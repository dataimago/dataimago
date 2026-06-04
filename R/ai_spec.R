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

#' Validate a parsed `dataimago-spec.yaml` and apply defaults.
#'
#' Lightweight structural validation (no JSON-Schema dependency this release;
#' the schema is carried in `inst/schemas/` for reference). Checks the
#' load-bearing invariants -- including the `source.rPackage` <-> `source.case`
#' cross-field rule that does NOT survive `zod-to-json-schema` -- then fills in
#' the optional `features` / `generator` defaults and returns the normalized
#' spec.
#'
#' @param spec A list (parsed YAML).
#' @return The normalized spec list (defaults applied).
#' @keywords internal
validate_spec <- function(spec) {
  if (!is.list(spec)) {
    cli::cli_abort("Spec must be a parsed YAML mapping; got {.cls {class(spec)[1]}}.")
  }

  api <- spec$apiVersion
  if (is.null(api) || !grepl("^dataimago\\.ai/", api)) {
    cli::cli_abort("Invalid spec apiVersion: expected a value beginning with 'dataimago.ai/'.")
  }
  if (!identical(spec$kind, "ProjectSpec")) {
    cli::cli_abort("Invalid spec kind: expected 'ProjectSpec'.")
  }
  if (is.null(spec$metadata) || is.null(spec$metadata$name) || !nzchar(spec$metadata$name)) {
    cli::cli_abort("Spec is missing the required field metadata$name.")
  }

  case <- spec$source$case
  if (is.null(case) || !case %in% c("extension", "retrofit", "no-r")) {
    cli::cli_abort("Invalid spec source$case: expected one of 'extension', 'retrofit', or 'no-r'.")
  }
  has_rpkg <- !is.null(spec$source$rPackage)
  if (case == "no-r" && has_rpkg) {
    cli::cli_abort("Invalid spec: source$rPackage must be absent when source$case is 'no-r'.")
  }
  if (case != "no-r" && !has_rpkg) {
    cli::cli_abort("Invalid spec: source$rPackage is required when source$case is 'extension' or 'retrofit'.")
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
    quartoBuild = TRUE, thesisPdf = TRUE,
    mcpTools = if (identical(case, "retrofit")) FALSE else TRUE,
    aiContext = TRUE,
    apiScaffolding = if (identical(case, "retrofit")) FALSE else TRUE
  )
  generator_defaults <- list(
    rpkgVersion = ">=0.5.0", designVersion = ">=2.0.0",
    outputDir = ".", staticExport = "full"
  )
  spec$features <- modifyList(feature_defaults, user_features)
  spec$generator <- modifyList(
    generator_defaults, if (is.null(spec$generator)) list() else spec$generator
  )

  if (!spec$generator$staticExport %in% c("full", "discover-only", "off")) {
    cli::cli_abort("Invalid spec generator$staticExport: expected one of 'full', 'discover-only', or 'off'.")
  }

  knowledge_was_declared <- !is.null(spec$vertical$rpkg$knowledge) || !is.null(spec$knowledge)
  knowledge <- spec$vertical$rpkg$knowledge
  if (is.null(knowledge)) knowledge <- spec$knowledge
  knowledge_defaults <- list(wikiMode = "merge-seeded")
  knowledge <- modifyList(knowledge_defaults, if (is.null(knowledge)) list() else knowledge)
  if (!knowledge$wikiMode %in% c("bootstrap", "merge-seeded", "skip")) {
    cli::cli_abort("Invalid spec knowledge$wikiMode: expected one of 'bootstrap', 'merge-seeded', or 'skip'.")
  }
  knowledge$.declared <- knowledge_was_declared
  spec$knowledge <- knowledge

  spec
}

#' Build the invisible result list returned by spec-driven generation.
#' @keywords internal
spec_result <- function(spec, project_path, out, generators_run, files_written) {
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
  if (is.null(project_path)) project_path <- fs::path_dir(spec_path)

  spec <- validate_spec(yaml::read_yaml(spec_path))
  out <- fs::path_abs(fs::path(project_path, spec$generator$outputDir))

  if (verbose) ui_info(glue::glue("Reading spec: {spec_path}"))

  # no-r: nothing in the producer-driver family to generate.
  if (identical(spec$source$case, "no-r")) {
    if (verbose) {
      ui_info("source.case = 'no-r' -- no R-derived artifacts to generate.")
    }
    return(invisible(spec_result(
      spec, project_path, out,
      generators_run = character(0), files_written = character(0)
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

  if (verbose) ui_info(glue::glue("Introspecting R package: {pkg_path}"))

  # Static export mode controls whether dataimago writes the StaticProducerDriver
  # input contract at all, and whether it writes only the manifest/OpenAPI pair or
  # full endpoint fixture data.
  if (!identical(spec$generator$staticExport, "off")) {
    export_static_api(
      pkg_path = pkg_path,
      output_dir = fs::path(out, "public", "api"),
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

  # mcpTools: MCP tool schema (canonical location: public/api/mcp-schema.json).
  if (isTRUE(features$mcpTools)) {
    generate_mcp_tools(
      pkg_path = pkg_path,
      output_path = fs::path(out, "public", "api", "mcp-schema.json"),
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
  if (isTRUE(features$aiContext) || isTRUE(knowledge$.declared)) {
    domain_type <- knowledge$domainType
    if (is.null(domain_type)) domain_type <- "framework"
    domain_name <- knowledge$domainName
    if (is.null(domain_name)) domain_name <- spec$project$title
    if (is.null(domain_name)) domain_name <- spec$metadata$name

    if (!identical(knowledge$wikiMode, "skip")) {
      overwrite_knowledge <- identical(knowledge$wikiMode, "bootstrap")
      bootstrap_wiki(
        project_path = out,
        project_name = spec$metadata$name,
        source_pkg = pkg_path,
        domain_type = domain_type,
        overwrite = overwrite_knowledge,
        verbose = verbose
      )
      generators_run <- c(generators_run, "bootstrap_wiki")

      knowledge_res <- generate_knowledge_md(
        project_path = out,
        project_name = spec$metadata$name,
        domain_type = domain_type,
        domain_name = domain_name,
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

  if (verbose) {
    ui_done(glue::glue(
      "ai(spec_path) complete -- {length(generators_run)} generators run."
    ))
  }

  invisible(spec_result(spec, project_path, out, generators_run, files_written))
}
