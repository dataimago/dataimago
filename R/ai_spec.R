#' @importFrom cli cli_abort
#' @importFrom utils modifyList
NULL

# ============================================================================
# Spec-driven generation (D.2.3.b)
# ----------------------------------------------------------------------------
# `ai(spec_path = ...)` reads a user's `dataimago-spec.yaml`, validates it,
# locates the R package it points at, and runs the producer-driver generators
# gated by the spec's `features` flags -- writing the integration-contract
# artifact family (discover.json + static JSON, types.ts, mcp-schema.json,
# optional live api.R). Generation runs in the user's repo CI (Framing C); the
# CI commits the result.
#
# See dataimago-design/wiki/patterns/rpkg-nextjs-integration-contract.md and
# wiki/decisions/spec-to-artifact-bridge.md.
# ============================================================================

#' Validate a spec file against the bundled JSON Schema.
#'
#' The Zod schema exported by `@dataimago/spec` in
#' `dataimago-ai/packages/spec` is authoritative.
#' `inst/schemas/dataimago-spec.v1alpha1.schema.json` is generated from it with
#' the package's `dataimago-spec-json-schema --kind ProjectSpec` bin and bundled
#' here so `ai(spec_path)` validates without Node at R runtime -- the
#' spec-to-artifact-bridge contract (decision 4).
#'
#' Engine-gated: runs when `jsonvalidate` (Suggests) is installed and its ajv
#' engine compiles the schema; otherwise it is skipped with a warning and the
#' structural checks in [validate_spec()] remain the only gate. Cross-field
#' invariants that do not survive `zod-to-json-schema` (the Zod `superRefine`
#' rules) are re-checked in R by [validate_spec()] regardless.
#'
#' @param spec_path Path to a `dataimago-spec.yaml`.
#' @return Invisibly: `TRUE` when the spec validates, `NA` when the engine is
#'   unavailable (with a warning). Aborts with per-error details when the spec
#'   violates the schema.
#' @keywords internal
validate_spec_schema <- function(spec_path) {
  if (!requireNamespace("jsonvalidate", quietly = TRUE)) {
    cli::cli_warn(c(
      "!" = "Package {.pkg jsonvalidate} is not installed -- skipping JSON-Schema validation of {.path {spec_path}}.",
      i = "Structural checks still run; install {.pkg jsonvalidate} for full schema validation."
    ))
    return(invisible(NA))
  }

  schema_path <- system.file(
    "schemas",
    "dataimago-spec.v1alpha1.schema.json",
    package = "dataimago"
  )
  if (!nzchar(schema_path)) {
    cli::cli_warn(
      "Bundled spec schema not found -- skipping JSON-Schema validation."
    )
    return(invisible(NA))
  }

  # Re-parse with every YAML sequence kept as a list so single-element
  # sequences serialize back to JSON arrays. (yaml's default simplification
  # turns a one-item sequence into a scalar vector, which auto_unbox would
  # then emit as a JSON scalar -- a false schema violation.)
  spec <- yaml::read_yaml(
    spec_path,
    handlers = list(seq = function(x) as.list(x))
  )

  # Legacy compatibility: a top-level `knowledge` block predates
  # vertical.rpkg.knowledge and is still honored by validate_spec(), but the
  # schema (additionalProperties: false) rejects it. Strip it for validation
  # and nudge toward the canonical location.
  if (!is.null(spec$knowledge)) {
    cli::cli_warn(c(
      "!" = "Top-level {.field knowledge} is deprecated; move it under {.field vertical.rpkg.knowledge}.",
      i = "It is still honored this release, but is excluded from JSON-Schema validation."
    ))
    spec$knowledge <- NULL
  }

  # R lists cannot hold an explicit trailing null the way YAML can
  # (`rPackage: null`); a spec written from R via yaml::write_yaml drops the
  # key entirely. The schema requires the key (nullable), so restore the
  # explicit null before serializing -- semantically identical for consumers.
  if (is.list(spec$source) && !("rPackage" %in% names(spec$source))) {
    spec$source["rPackage"] <- list(NULL)
  }

  spec_json <- jsonlite::toJSON(
    spec,
    auto_unbox = TRUE,
    null = "null",
    digits = NA
  )

  result <- tryCatch(
    jsonvalidate::json_validate(
      spec_json,
      schema_path,
      engine = "ajv",
      verbose = TRUE
    ),
    error = function(e) {
      cli::cli_warn(c(
        "!" = "JSON-Schema validation engine failed -- skipping schema validation.",
        i = conditionMessage(e)
      ))
      NA
    }
  )
  if (is.na(result)) {
    return(invisible(NA))
  }

  if (!isTRUE(result)) {
    errors <- attr(result, "errors")
    details <- character(0)
    if (is.data.frame(errors) && nrow(errors) > 0) {
      where <- errors$instancePath
      if (is.null(where)) {
        where <- errors$dataPath # older engine field name
      }
      if (is.null(where)) {
        where <- rep(NA_character_, nrow(errors))
      }
      details <- paste0(
        ifelse(is.na(where) | !nzchar(where), "(root)", where),
        ": ",
        errors$message
      )
      # cli interpolates {}; escape any braces coming from engine messages.
      details <- gsub("\\{", "{{", gsub("\\}", "}}", details))
      names(details) <- rep("x", length(details))
    }
    cli::cli_abort(c(
      "Spec fails JSON-Schema validation: {.path {spec_path}}.",
      details,
      i = "Schema: {.path {schema_path}} (generated from authoritative {.pkg @dataimago/spec} in dataimago-ai)."
    ))
  }

  invisible(TRUE)
}

#' Validate a parsed `dataimago-spec.yaml` and apply defaults.
#'
#' Structural validation of the load-bearing invariants -- including the Zod
#' `superRefine` cross-field rules that do NOT survive `zod-to-json-schema`
#' (`source.rPackage` is null iff `source.case == "no-r"`; exactly one
#' vertical present) -- then fills in the optional `features` / `generator`
#' defaults and returns the normalized spec. Full JSON-Schema validation is
#' [validate_spec_schema()]'s job; this always runs, schema engine or not.
#'
#' @param spec A list (parsed YAML).
#' @return The normalized spec list (defaults applied).
#' @keywords internal
validate_spec <- function(spec) {
  if (!is.list(spec)) {
    cli::cli_abort(
      "Spec must be a parsed YAML mapping; got {.cls {class(spec)[1]}}."
    )
  }

  api <- spec$apiVersion
  if (is.null(api) || !grepl("^dataimago\\.ai/", api)) {
    cli::cli_abort(
      "Invalid spec apiVersion: expected a value beginning with 'dataimago.ai/'."
    )
  }
  if (!identical(spec$kind, "ProjectSpec")) {
    cli::cli_abort("Invalid spec kind: expected 'ProjectSpec'.")
  }
  if (
    is.null(spec$metadata) ||
      is.null(spec$metadata$name) ||
      !nzchar(spec$metadata$name)
  ) {
    cli::cli_abort("Spec is missing the required field metadata$name.")
  }

  case <- spec$source$case
  if (
    is.null(case) ||
      !case %in% c("extension", "retrofit", "no-r", "greenfield")
  ) {
    cli::cli_abort(
      "Invalid spec source$case: expected one of 'extension', 'retrofit', 'no-r', or 'greenfield'."
    )
  }
  has_rpkg <- !is.null(spec$source$rPackage)
  if (case == "no-r" && has_rpkg) {
    cli::cli_abort(
      "Invalid spec: source$rPackage must be absent when source$case is 'no-r'."
    )
  }
  if (case != "no-r" && !has_rpkg) {
    cli::cli_abort(
      "Invalid spec: source$rPackage is required unless source$case is 'no-r'."
    )
  }
  # superRefine parity: exactly one vertical (dissertation | rpkg) present.
  verticals <- c("dissertation", "rpkg")
  present <- verticals[
    vapply(
      verticals,
      function(k) !is.null(spec$vertical[[k]]),
      logical(1)
    )
  ]
  if (length(present) != 1L) {
    cli::cli_abort(
      "Invalid spec: exactly one vertical (dissertation or rpkg) must be present; found {length(present)}."
    )
  }
  if (has_rpkg) {
    sp <- spec$source$rPackage$submodulePath
    if (is.null(sp) || !nzchar(sp)) {
      cli::cli_abort("Invalid spec: source$rPackage$submodulePath is required.")
    }
  }

  # Defaults -- most spec fields are optional with sensible defaults (the
  # "spec accommodates, interview asks the critical subset" principle).
  user_features <- if (is.null(spec$features)) list() else spec$features
  feature_defaults <- list(
    quartoBuild = TRUE,
    thesisPdf = TRUE,
    mcpTools = if (identical(case, "retrofit")) FALSE else TRUE,
    aiContext = TRUE,
    apiScaffolding = if (identical(case, "retrofit")) FALSE else TRUE
  )
  generator_defaults <- list(
    rpkgVersion = ">=0.5.0",
    designVersion = ">=2.0.0",
    outputDir = ".",
    staticExport = "full"
  )
  spec$features <- modifyList(feature_defaults, user_features)
  spec$generator <- modifyList(
    generator_defaults,
    if (is.null(spec$generator)) list() else spec$generator
  )

  if (!spec$generator$staticExport %in% c("full", "discover-only", "off")) {
    cli::cli_abort(
      "Invalid spec generator$staticExport: expected one of 'full', 'discover-only', or 'off'."
    )
  }

  knowledge_was_declared <- !is.null(spec$vertical$rpkg$knowledge) ||
    !is.null(spec$knowledge)
  knowledge <- spec$vertical$rpkg$knowledge
  if (is.null(knowledge)) {
    knowledge <- spec$knowledge
  }
  knowledge_defaults <- list(wikiMode = "merge-seeded")
  knowledge <- modifyList(
    knowledge_defaults,
    if (is.null(knowledge)) list() else knowledge
  )
  if (!knowledge$wikiMode %in% c("bootstrap", "merge-seeded", "skip")) {
    cli::cli_abort(
      "Invalid spec knowledge$wikiMode: expected one of 'bootstrap', 'merge-seeded', or 'skip'."
    )
  }
  knowledge$.declared <- knowledge_was_declared
  spec$knowledge <- knowledge

  ai_agent_defaults <- list(
    skillBundle = TRUE,
    mcpTools = isTRUE(spec$features$mcpTools),
    skillMode = "merge-seeded",
    includeWikiResources = TRUE,
    includePrototypeFunctions = FALSE
  )
  spec$aiAgent <- modifyList(
    ai_agent_defaults,
    if (is.null(spec$aiAgent)) list() else spec$aiAgent
  )
  if (!spec$aiAgent$skillMode %in% c("bootstrap", "merge-seeded", "skip")) {
    cli::cli_abort(
      "Invalid spec aiAgent$skillMode: expected one of 'bootstrap', 'merge-seeded', or 'skip'."
    )
  }

  spec
}

#' Build the invisible result list returned by spec-driven generation.
#' @keywords internal
spec_result <- function(
  spec,
  project_path,
  out,
  generators_run,
  files_written
) {
  list(
    mode = "spec",
    project_name = spec$metadata$name,
    project_path = as.character(project_path),
    output_dir = as.character(out),
    generators_run = generators_run,
    files_written = files_written,
    success = TRUE,
    errors = character(0),
    timestamp = Sys.time()
  )
}

spec_domain_context <- function(spec, knowledge) {
  domain_type <- knowledge$domainType
  if (is.null(domain_type)) {
    domain_type <- "framework"
  }

  domain_name <- knowledge$domainName
  if (is.null(domain_name)) {
    domain_name <- spec$project$title
  }
  if (is.null(domain_name)) {
    domain_name <- spec$metadata$name
  }

  list(
    domain_type = domain_type,
    domain_name = domain_name
  )
}

#' Spec-driven local generation pipeline.
#'
#' Reads + validates `spec_path`, locates the R package at
#' `source$rPackage$submodulePath` (relative to `generator$outputDir`), and
#' runs the producer-driver generators gated by `features`.
#'
#' @param spec_path Path to a `dataimago-spec.yaml`.
#' @param project_path Directory the spec's `outputDir` is resolved against.
#'   Defaults to the directory containing `spec_path`.
#' @param verbose Logical. Print progress. Default TRUE.
#' @return Invisible list with generation metadata (see [spec_result()]).
#' @keywords internal
ai_from_spec <- function(spec_path, project_path = NULL, verbose = TRUE) {
  if (!fs::file_exists(spec_path)) {
    cli::cli_abort("Spec file not found: {.path {spec_path}}.")
  }
  spec_path <- fs::path_abs(spec_path)
  if (is.null(project_path)) {
    project_path <- fs::path_dir(spec_path)
  }

  validate_spec_schema(spec_path)
  spec <- validate_spec(yaml::read_yaml(spec_path))
  out <- fs::path_abs(fs::path(project_path, spec$generator$outputDir))

  if (verbose) {
    ui_info(glue::glue("Reading spec: {spec_path}"))
  }

  # greenfield (generate the R package FROM the spec's vertical.rpkg.package
  # block) is schema-valid but not yet implemented R-side. Fail honestly and
  # early rather than with a confusing missing-DESCRIPTION error below.
  if (identical(spec$source$case, "greenfield")) {
    cli::cli_abort(c(
      "source$case = 'greenfield' (generate the R package from the spec) is not implemented in this release.",
      i = "Use 'extension' or 'retrofit' with an existing package, or 'no-r'. Greenfield generation is tracked in the rpkg-spec design."
    ))
  }

  # no-r: nothing in the producer-driver family to generate.
  if (identical(spec$source$case, "no-r")) {
    if (verbose) {
      ui_info("source.case = 'no-r' -- no R-derived artifacts to generate.")
    }
    return(invisible(spec_result(
      spec,
      project_path,
      out,
      generators_run = character(0),
      files_written = character(0)
    )))
  }

  pkg_path <- fs::path(out, spec$source$rPackage$submodulePath)
  if (!fs::file_exists(fs::path(pkg_path, "DESCRIPTION"))) {
    cli::cli_abort(c(
      "Could not find the R package at {.path {pkg_path}}.",
      i = "Expected a DESCRIPTION there (from source$rPackage$submodulePath)."
    ))
  }

  generators_run <- character(0)
  files_written <- character(0)
  features <- spec$features

  if (verbose) {
    ui_info(glue::glue("Introspecting R package: {pkg_path}"))
  }

  # Static export mode controls whether dataimago writes the StaticProducerDriver
  # input contract at all, and whether it writes only the manifest/OpenAPI pair or
  # full endpoint fixture data.
  if (!identical(spec$generator$staticExport, "off")) {
    export_static_api(
      pkg_path = pkg_path,
      output_dir = fs::path(out, "data", "api"),
      mode = spec$generator$staticExport,
      verbose = verbose
    )
    generators_run <- c(generators_run, "export_static_api")
  }

  # Shared TS utils are independent from static JSON fixtures.
  utils_res <- generate_shared_utils(
    pkg_path = pkg_path,
    output_dir = fs::path(out, "packages", "shared-utils", "src"),
    verbose = verbose
  )
  generators_run <- c(generators_run, "generate_shared_utils")
  files_written <- c(files_written, utils_res$files_created)

  # aiAgent$mcpTools: MCP tool schema (canonical location:
  # public/api/mcp-schema.json). features$mcpTools remains backward-compatible
  # and is mirrored into aiAgent defaults during validation.
  if (isTRUE(spec$aiAgent$mcpTools)) {
    generate_mcp_tools(
      pkg_path = pkg_path,
      output_path = fs::path(out, "public", "api", "mcp-schema.json"),
      include_api_tools = isTRUE(features$apiScaffolding),
      verbose = verbose
    )
    generators_run <- c(generators_run, "generate_mcp_tools")
    files_written <- c(files_written, "public/api/mcp-schema.json")
  }

  # apiScaffolding: optional live-driver RestRserve server (api.R) alongside
  # the R package it serves.
  if (isTRUE(features$apiScaffolding)) {
    generate_api_scaffolding(
      pkg_path = pkg_path,
      output_dir = pkg_path,
      verbose = verbose
    )
    generators_run <- c(generators_run, "generate_api_scaffolding")
  }

  # Knowledge layer: scaffold wiki/ + raw/ + KNOWLEDGE.md -- the AI-native
  # package's domain knowledge base (the "populate raw -> seed wiki -> build"
  # opening workflow). Gated on a `knowledge` block or features$aiContext.
  # This is committed, curated source (seeded-vs-curated), distinct from the
  # producer-driver build artifacts above. Seeding from raw/ is an in-repo-AI
  # task; here we scaffold the structure + the KNOWLEDGE.md how-to.
  knowledge <- spec$knowledge
  domain <- spec_domain_context(spec, knowledge)
  if (isTRUE(features$aiContext) || isTRUE(knowledge$.declared)) {
    if (!identical(knowledge$wikiMode, "skip")) {
      overwrite_knowledge <- identical(knowledge$wikiMode, "bootstrap")
      bootstrap_wiki(
        project_path = out,
        project_name = spec$metadata$name,
        source_pkg = pkg_path,
        domain_type = domain$domain_type,
        overwrite = overwrite_knowledge,
        verbose = verbose
      )
      generators_run <- c(generators_run, "bootstrap_wiki")

      knowledge_res <- generate_knowledge_md(
        project_path = out,
        project_name = spec$metadata$name,
        domain_type = domain$domain_type,
        domain_name = domain$domain_name,
        source_pkg = pkg_path,
        overwrite = overwrite_knowledge,
        verbose = verbose
      )
      generators_run <- c(generators_run, "generate_knowledge_md")
      if (!isTRUE(knowledge_res$skipped)) {
        files_written <- c(files_written, "KNOWLEDGE.md")
      }
    }
  }

  # AI skill bundle: an instructional layer for agents. This can ship before
  # executable MCP exposure because it teaches safe workflows rather than
  # granting tool access.
  if (
    isTRUE(spec$aiAgent$skillBundle) &&
      !identical(spec$aiAgent$skillMode, "skip")
  ) {
    skill_res <- generate_ai_skill(
      project_path = out,
      project_name = spec$metadata$name,
      domain_type = domain$domain_type,
      domain_name = domain$domain_name,
      source_pkg = pkg_path,
      overwrite = identical(spec$aiAgent$skillMode, "bootstrap"),
      verbose = verbose
    )
    generators_run <- c(generators_run, "generate_ai_skill")
    files_written <- c(files_written, skill_res$files_created)
  }

  if (verbose) {
    ui_done(glue::glue(
      "ai(spec_path) complete -- {length(generators_run)} generators run."
    ))
  }

  invisible(spec_result(spec, project_path, out, generators_run, files_written))
}
