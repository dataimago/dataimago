#' @importFrom fs dir_exists dir_create path file_exists path_rel
#' @importFrom glue glue
#' @importFrom jsonlite toJSON
#' @importFrom digest digest
#' @importFrom crayon green silver yellow red bold blue
#' @importFrom utils getFromNamespace
NULL

# ============================================================================
# export_static.R -- Pre-compute R Analysis Results as Static JSON
# ============================================================================
#
# Phase 2e semantics: the JSON files written here are the
# **StaticProducerDriver's input contract**, not a public URL space. The
# NextJS API route tree (/api/discover, /api/data/<endpoint>,
# /api/openapi.json) is the only public surface; when DATAIMAGO_PRODUCER
# is "static", the route handlers read these files via the driver in
# `@dataimago/shared-utils/producers`.
#
# Filename convention (must match StaticProducerDriver.filenameFor):
#   <output_dir>/store.manifest.json                  - the store contract (see below)
#   <output_dir>/discover.json                        - manifest (Phase-2e shape)
#   <output_dir>/openapi.json                         - OpenAPI spec (stub OK)
#   <output_dir>/<endpoint>/default.json              - no-param response
#   <output_dir>/<endpoint>/<v1>_<v2>_..._<vn>.json   - param response
#                                                       (values only, lowercased,
#                                                        whitespace -> "_")
#
# `store.manifest.json` (schema `dataimago.store.v1`) is what makes this a *store*
# rather than a directory of JSON. It answers the three questions a bare directory
# cannot: which build produced this (provenance), has it been tampered with
# (per-artifact sha256), and may it be exposed (classification). The
# StaticProducerDriver refuses to serve any file the manifest does not list, and
# verifies the hash before returning bytes -- so a manifest that lies is a 500,
# not a silently-served stale file.
#
# The writer owns provenance. That is why it is emitted here and not by a
# downstream Node build step: only this process knows which commit the data was
# derived from.
#
# Pattern: R functions x parameter combinations -> <output_dir>/**/*.json
# Reference:
#   - packages/shared-utils/src/producers/static-driver.ts (contract)
#   - packages/shared-utils/src/store/ (the manifest reader + gate)
#   - dataimago-design wiki: patterns/data-store-contract.md
#   - dataimago-design wiki: patterns/producer-driver-pattern.md
# ============================================================================


#' Export Static API Data (StaticProducerDriver input contract)
#'
#' Enumerates parameter combinations for exported R functions and pre-computes
#' results as static JSON files. These files are the input contract for the
#' `StaticProducerDriver` (see `@dataimago/shared-utils/producers`): they are
#' read by the NextJS API route handlers at request time when
#' `DATAIMAGO_PRODUCER=static`. They are not themselves a public URL space.
#'
#' The filename convention below mirrors `StaticProducerDriver.filenameFor`
#' exactly; changes to this file *must* be mirrored there.
#'
#' @param pkg_path Character. Path to the R package source directory
#' @param output_dir Character. Directory for JSON output files (typically
#'   \code{public/api/} in the NextJS project). Default: "public/api"
#' @param pkg_name Character. Package name. If NULL, read from DESCRIPTION.
#' @param param_grid List. Custom parameter combinations to enumerate. If NULL,
#'   combinations are inferred from roxygen enum values and defaults.
#' @param max_combinations Integer. Safety limit on total combinations per
#'   function. Default: 500
#' @param mode Character. Export mode: "full" writes endpoint fixtures plus
#'   discover/openapi metadata; "discover-only" writes only metadata. Default:
#'   "full".
#' @param domain_schema Character. The vertical this store's data belongs to
#'   (e.g. "sgp", "dissertation"), recorded in `store.manifest.json`. Defaults
#'   to the package name.
#' @param verbose Logical. Print progress. Default: TRUE
#'
#' @return List with: files_created (count), total_size_kb, functions_exported,
#'   elapsed_seconds
#'
#' @details
#' The export process:
#' 1. Parse exported functions and their parameter metadata
#' 2. For each function, enumerate parameter combinations from:
#'    - Enum values documented in roxygen
#'    - Default values from function signatures
#'    - Custom grid provided via \code{param_grid}
#' 3. Call each function with each parameter combination
#' 4. Write results as JSON files to the output directory
#' 5. Create a manifest file listing all exported endpoints
#'
#' File naming convention (mirrors `StaticProducerDriver.filenameFor`):
#' \itemize{
#'   \item \code{output_dir/store.manifest.json} -- the `dataimago.store.v1`
#'     contract: provenance, per-artifact sha256, and classification. Only files
#'     listed here are reachable through the driver.
#'   \item \code{output_dir/discover.json} -- Phase-2e producer manifest
#'   \item \code{output_dir/openapi.json} -- OpenAPI 3.0 spec (stub acceptable)
#'   \item \code{output_dir/<endpoint>/default.json} -- no-parameter result
#'   \item \code{output_dir/<endpoint>/<v1>_<v2>_..._<vn>.json} -- param result,
#'     values only, lowercased, whitespace replaced by underscores, joined by
#'     underscores (no \code{param=val} encoding)
#' }
#'
#' @section Performance Equity:
#' Static JSON files are typically much smaller than dynamic responses because
#' they can be pre-compressed and cached at the CDN edge. This aligns with
#' dataimago's performance equity principle -- users on constrained connections
#' get the same quality of data access.
#'
#' @export
export_static_api <- function(pkg_path,
                              output_dir = "public/api",
                              pkg_name = NULL,
                              param_grid = NULL,
                              max_combinations = 500L,
                              mode = c("full", "discover-only"),
                              domain_schema = NULL,
                              verbose = TRUE) {
  mode <- match.arg(mode)
  start_time <- Sys.time()

  # Read package name
  if (is.null(pkg_name)) {
    desc_path <- fs::path(pkg_path, "DESCRIPTION")
    if (fs::file_exists(desc_path)) {
      desc_lines <- readLines(desc_path, warn = FALSE)
      pkg_line <- grep("^Package:", desc_lines, value = TRUE)
      if (length(pkg_line) > 0) {
        pkg_name <- trimws(sub("^Package:\\s*", "", pkg_line[1]))
      }
    }
    if (is.null(pkg_name)) pkg_name <- basename(pkg_path)
  }

  if (verbose) {
    ui_info(glue::glue("\U0001F4BE Exporting static API data for '{pkg_name}'"))
    ui_info(glue::glue("\U0001F4C1 Output: {output_dir}"))
  }

  # Parse exported functions
  exports <- parse_roxygen_exports(pkg_path, verbose = FALSE)

  if (length(exports) == 0) {
    if (verbose) ui_warn("No exported functions found -- nothing to export")
    return(invisible(list(files_created = 0, total_size_kb = 0)))
  }

  # Ensure output directory
  if (!fs::dir_exists(output_dir)) {
    fs::dir_create(output_dir, recurse = TRUE)
  }

  total_files <- 0L
  total_bytes <- 0L
  functions_exported <- character(0)
  # Every file written this run, hashed as it lands. Files left over from a
  # previous export are deliberately NOT listed: an unlisted artifact is
  # unreachable through the driver, which is how a stale fixture stops being
  # served the moment the store is rebuilt.
  artifacts <- list()

  if (identical(mode, "full")) {
    for (fn_name in names(exports)) {
      fn_meta <- exports[[fn_name]]
      endpoint <- fn_to_endpoint(fn_name)

      # Create endpoint directory
      endpoint_dir <- fs::path(output_dir, endpoint)
      if (!fs::dir_exists(endpoint_dir)) {
        fs::dir_create(endpoint_dir, recurse = TRUE)
      }

      if (verbose) {
        ui_info(glue::glue("  Exporting: {fn_name} -> /{endpoint}/"))
      }

      # Generate parameter combinations
      if (!is.null(param_grid) && fn_name %in% names(param_grid)) {
        combos <- param_grid[[fn_name]]
      } else {
        combos <- generate_param_combinations(fn_meta$params, max_combinations)
      }

      # Export default (no params) call
      result <- safe_call_function(pkg_name, fn_name, list())
      if (!is.null(result)) {
        json_content <- jsonlite::toJSON(result, auto_unbox = TRUE, dataframe = "rows", pretty = FALSE)
        default_path <- fs::path(endpoint_dir, "default.json")
        writeLines(json_content, default_path)
        artifacts <- c(artifacts, list(
          artifact_entry(default_path, output_dir, "aggregate", result_row_count(result))
        ))
        total_files <- total_files + 1L
        total_bytes <- total_bytes + nchar(json_content)
      }

      # Export each parameter combination
      for (combo in combos) {
        result <- safe_call_function(pkg_name, fn_name, combo)
        if (!is.null(result)) {
          filename <- combo_to_filename(combo)
          json_content <- jsonlite::toJSON(result, auto_unbox = TRUE, dataframe = "rows", pretty = FALSE)
          json_path <- fs::path(endpoint_dir, filename)
          writeLines(json_content, json_path)
          artifacts <- c(artifacts, list(
            artifact_entry(json_path, output_dir, "aggregate", result_row_count(result))
          ))
          total_files <- total_files + 1L
          total_bytes <- total_bytes + nchar(json_content)
        }
      }

      functions_exported <- c(functions_exported, fn_name)
    }
  } else {
    functions_exported <- names(exports)
  }

  # Export discovery manifest (Phase-2e shape: discover.json at the root)
  pkg_version <- read_pkg_version(pkg_path)
  discover_result <- export_discover_endpoint(exports, pkg_name, pkg_version, output_dir)
  total_files <- total_files + discover_result$files
  artifacts <- c(artifacts, list(
    artifact_entry(fs::path(output_dir, "discover.json"), output_dir, "metadata")
  ))

  # Export OpenAPI stub (StaticProducerDriver.readOpenApi contract)
  openapi_result <- export_openapi_stub(exports, pkg_name, pkg_version, output_dir)
  total_files <- total_files + openapi_result$files
  artifacts <- c(artifacts, list(
    artifact_entry(fs::path(output_dir, "openapi.json"), output_dir, "metadata")
  ))

  # The store contract. Written last: every artifact it lists must already exist
  # on disk, because each sha256 is taken from the bytes as written.
  store_result <- write_store_manifest(
    output_dir = output_dir,
    store_id = pkg_name,
    domain_schema = domain_schema %||% pkg_name,
    exports = exports,
    artifacts = artifacts
  )
  total_files <- total_files + store_result$files

  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  results <- list(
    files_created = total_files,
    total_size_kb = round(total_bytes / 1024, 1),
    functions_exported = functions_exported,
    elapsed_seconds = round(elapsed, 1),
    store_manifest = as.character(fs::path(output_dir, "store.manifest.json")),
    provenance = store_result$provenance
  )

  if (verbose) {
    ui_done(glue::glue(
      "Exported {total_files} JSON files ({results$total_size_kb} KB) ",
      "for {length(functions_exported)} functions in {results$elapsed_seconds}s"
    ))
    prov <- store_result$provenance
    if (is.null(prov$git_sha)) {
      ui_warn(paste(
        "store.manifest.json has no git_sha -- the output is outside a git repository.",
        "Integrity still holds; provenance does not."
      ))
    } else {
      ui_done(glue::glue(
        "store.manifest.json: {length(artifacts)} artifacts, ",
        "git_sha {substr(prov$git_sha, 1, 7)}{if (isTRUE(prov$dirty)) ' (dirty)' else ''}"
      ))
    }
  }

  invisible(results)
}


# ============================================================================
# Internal: Parameter Combination Generation
# ============================================================================

#' Generate parameter combinations from function metadata
#' @noRd
generate_param_combinations <- function(params, max_combinations) {
  # Collect enum values for each parameter
  enum_params <- list()

  for (param_name in names(params)) {
    p <- params[[param_name]]
    if (!is.null(p$enum) && length(p$enum) > 0) {
      enum_params[[param_name]] <- p$enum
    }
  }

  if (length(enum_params) == 0) {
    return(list())
  }

  # Generate Cartesian product of enum values
  grid <- expand.grid(enum_params, stringsAsFactors = FALSE)

  # Safety limit

  if (nrow(grid) > max_combinations) {
    warning(glue::glue(
      "Parameter grid has {nrow(grid)} combinations, truncating to {max_combinations}"
    ))
    grid <- grid[seq_len(max_combinations), , drop = FALSE]
  }

  # Convert to list of named lists
  combos <- lapply(seq_len(nrow(grid)), function(i) {
    as.list(grid[i, , drop = FALSE])
  })

  combos
}


#' Safely call an R package function with given parameters
#' @noRd
safe_call_function <- function(pkg_name, fn_name, params) {
  tryCatch(
    {
      fn <- getFromNamespace(fn_name, pkg_name)
      do.call(fn, params)
    },
    error = function(e) {
      # Return error structure instead of NULL for debugging
      list(
        status = "error",
        message = paste("Static export error:", e$message),
        function_name = fn_name,
        params = params
      )
    }
  )
}


#' Convert parameter combination to filename
#'
#' Mirrors `StaticProducerDriver.filenameFor()` in
#' `packages/shared-utils/src/producers/static-driver.ts`:
#'   - no params  -> "default.json"
#'   - otherwise  -> values only, lowercased, whitespace -> "_", joined by "_"
#'
#' Both sides of this contract MUST stay in lockstep.
#'
#' @noRd
combo_to_filename <- function(combo) {
  if (length(combo) == 0) {
    return("default.json")
  }

  # StaticProducerDriver sanitization: lowercase, whitespace -> "_",
  # and then be defensive against slashes and control chars for the filesystem.
  sanitize_value <- function(v) {
    s <- tolower(as.character(v))
    s <- gsub("\\s+", "_", s)
    # Keep [a-z0-9_.-]; everything else becomes "_".
    gsub("[^a-z0-9_.-]", "_", s)
  }

  # Preserve caller-provided ordering (matches JS Object.values() semantics
  # for string-keyed records). Empty / NULL values are skipped, matching
  # the driver's `filter((v) => v !== undefined && v !== null && v !== '')`.
  keep <- vapply(combo, function(v) {
    !is.null(v) && !identical(v, NA) && nzchar(as.character(v))
  }, logical(1))

  if (!any(keep)) {
    return("default.json")
  }

  values <- vapply(combo[keep], sanitize_value, character(1))
  paste0(paste(values, collapse = "_"), ".json")
}


#' Export the discovery manifest as `<output_dir>/discover.json`
#'
#' The shape is the Phase-2e `ProducerManifest` expected by the NextJS
#' `/api/discover` route and the `StaticProducerDriver`:
#'
#' \preformatted{
#'   {
#'     "package_name": "...",
#'     "version": "...",
#'     "endpoints": [ { "name", "title", "description", "path", "method",
#'                      "params": [ { "name", "type", "required", ... } ] } ],
#'     "openapi_url": "/api/openapi.json",
#'     "timestamp": "ISO-8601"
#'   }
#' }
#'
#' @noRd
export_discover_endpoint <- function(exports, pkg_name, pkg_version, output_dir) {
  endpoint_infos <- lapply(names(exports), function(fn_name) {
    fn_meta <- exports[[fn_name]]
    endpoint <- fn_to_endpoint(fn_name)

    params <- lapply(names(fn_meta$params), function(p_name) {
      p <- fn_meta$params[[p_name]]
      info <- list(
        name = p_name,
        type = p$type %||% "string",
        required = isTRUE(p$required)
      )
      if (!is.null(p$description) && nzchar(p$description)) {
        info$description <- p$description
      }
      if (!is.null(p$default) && !identical(p$default, NA)) {
        info$default <- gsub('^"|"$', "", as.character(p$default))
      }
      if (!is.null(p$enum) && length(p$enum) > 0) {
        info$enum <- as.list(p$enum)
      }
      info
    })

    list(
      name = endpoint,
      title = fn_meta$title %||% fn_name,
      description = fn_meta$description %||% "",
      path = paste0("/", endpoint),
      method = "GET",
      params = params
    )
  })

  manifest <- list(
    package_name = pkg_name,
    version = pkg_version %||% "0.0.0",
    endpoints = endpoint_infos,
    openapi_url = "/api/openapi.json",
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )

  json_content <- jsonlite::toJSON(
    manifest,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  writeLines(json_content, fs::path(output_dir, "discover.json"))

  list(files = 1L)
}


#' Export an OpenAPI 3.0 stub as `<output_dir>/openapi.json`
#'
#' StaticProducerDriver.readOpenApi reads this file verbatim. The stub
#' records the four public NextJS routes so downstream tooling (e.g.
#' the platform's API browser) has something to render before the real
#' spec is generated.
#'
#' @noRd
export_openapi_stub <- function(exports, pkg_name, pkg_version, output_dir) {
  paths <- list()
  paths[["/api/discover"]] <- list(
    get = list(
      summary = "Discover the endpoint catalog",
      responses = list(`200` = list(description = "Producer manifest"))
    )
  )
  paths[["/api/openapi.json"]] <- list(
    get = list(
      summary = "OpenAPI 3.0 specification for this project",
      responses = list(`200` = list(description = "OpenAPI document"))
    )
  )
  for (fn_name in names(exports)) {
    endpoint <- fn_to_endpoint(fn_name)
    paths[[paste0("/api/data/", endpoint)]] <- list(
      get = list(
        summary = exports[[fn_name]]$title %||% fn_name,
        responses = list(`200` = list(description = "Analysis result"))
      )
    )
  }

  spec <- list(
    openapi = "3.0.0",
    info = list(
      title = glue::glue("{pkg_name} API"),
      version = pkg_version %||% "0.0.0",
      description = "Auto-generated stub by dataimago::export_static_api(); replace with a real spec as the API matures."
    ),
    paths = paths
  )

  writeLines(
    jsonlite::toJSON(spec, auto_unbox = TRUE, pretty = TRUE),
    fs::path(output_dir, "openapi.json")
  )

  list(files = 1L)
}


# ============================================================================
# Internal: the `dataimago.store.v1` contract
# ============================================================================
#
# Read by `loadStoreManifest()` in `@dataimago/shared-utils/store`. Keep the two
# in lockstep: the reader validates schema_version, store.id, provenance.built_at,
# a nullable provenance.git_sha, and every artifact's path / sha256 / classification.
# ============================================================================

STORE_SCHEMA_VERSION <- "dataimago.store.v1"


#' Rows in a result, when the notion applies
#'
#' Mirrors what `jsonlite::toJSON(dataframe = "rows")` actually emits: a
#' data.frame becomes an array of row objects, an unnamed list becomes an array.
#' Anything else (a named list, a scalar) has no top-level array, so no count.
#'
#' @noRd
result_row_count <- function(x) {
  if (is.data.frame(x)) {
    return(nrow(x))
  }
  if (is.list(x) && is.null(names(x))) {
    return(length(x))
  }
  NULL
}


#' Describe one written file as a manifest artifact
#'
#' The hash is taken from the bytes on disk, not from the JSON string that
#' produced them -- `writeLines()` appends a trailing newline, so hashing the
#' string would record a digest the reader could never reproduce.
#'
#' @noRd
artifact_entry <- function(file_path, output_dir, classification, row_count = NULL) {
  rel <- as.character(fs::path_rel(file_path, output_dir))
  list(
    role = sub("\\.json$", "", rel),
    path = rel,
    format = "application/json",
    sha256 = digest::digest(file_path, algo = "sha256", file = TRUE),
    row_count = row_count,
    classification = classification
  )
}


#' Provenance of the repository that owns the data
#'
#' Not the provenance of `dataimago` itself. A store's `git_sha` names the commit
#' of the project whose data this is, so the question "which build produced this
#' file?" has an answer a human can check out.
#'
#' Outside a git repository there is no honest answer, so `git_sha` is `NULL` and
#' `dirty` is `TRUE`: an unknown working tree is assumed dirty rather than clean.
#' Integrity (sha256) does not depend on git and still holds.
#'
#' @noRd
store_provenance <- function(dir) {
  built_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  unknown <- list(git_sha = NULL, dirty = TRUE, built_at = built_at)

  if (!nzchar(Sys.which("git"))) {
    return(unknown)
  }

  run_git <- function(...) {
    # system2() pastes its args into a shell command without quoting them, so an
    # unquoted path breaks on the first space -- and "~/My Project/" is an
    # ordinary place to keep a project.
    out <- suppressWarnings(
      system2("git", c("-C", shQuote(dir), ...), stdout = TRUE, stderr = FALSE)
    )
    status <- attr(out, "status")
    if (!is.null(status) && !identical(as.integer(status), 0L)) {
      return(NULL)
    }
    out
  }

  sha <- run_git("rev-parse", "HEAD")
  if (is.null(sha) || length(sha) == 0 || !nzchar(sha[1])) {
    return(unknown)
  }

  porcelain <- run_git("status", "--porcelain")
  # A failed `status` leaves us unable to prove the tree is clean, so say dirty.
  dirty <- is.null(porcelain) || length(porcelain) > 0

  list(git_sha = sha[1], dirty = dirty, built_at = built_at)
}


#' Write `<output_dir>/store.manifest.json`
#'
#' `rawSql` is `FALSE` and `restricted` never appears in `disclosure`: a static
#' JSON store has no SQL engine, and exposing restricted data is not something
#' this writer can express.
#'
#' @noRd
write_store_manifest <- function(output_dir, store_id, domain_schema, exports, artifacts) {
  named_queries <- lapply(names(exports), function(fn_name) {
    list(
      name = fn_to_endpoint(fn_name),
      # as.list(): a length-1 character vector would auto_unbox into a bare
      # string, and `params` must always be a JSON array.
      params = as.list(names(exports[[fn_name]]$params) %||% character(0))
    )
  })

  manifest <- list(
    schema_version = STORE_SCHEMA_VERSION,
    store = list(id = store_id, kind = "static", domain_schema = domain_schema),
    provenance = store_provenance(output_dir),
    artifacts = artifacts,
    disclosure = list(
      api = as.list(c("aggregate", "metadata")),
      mcp = as.list(c("aggregate", "metadata"))
    ),
    capabilities = list(
      rawSql = FALSE,
      maxRows = 5000L,
      namedQueries = named_queries
    )
  )

  writeLines(
    jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE, null = "null"),
    fs::path(output_dir, "store.manifest.json")
  )

  list(files = 1L, provenance = manifest$provenance)
}


#' Read the Version field from an R package DESCRIPTION
#' @noRd
read_pkg_version <- function(pkg_path) {
  desc_path <- fs::path(pkg_path, "DESCRIPTION")
  if (!fs::file_exists(desc_path)) {
    return(NULL)
  }
  lines <- readLines(desc_path, warn = FALSE)
  v <- grep("^Version:", lines, value = TRUE)
  if (length(v) == 0) {
    return(NULL)
  }
  trimws(sub("^Version:\\s*", "", v[1]))
}

# `%||%` is provided by base R since 4.4.0; the package's DESCRIPTION requires
# R >= 4.5 via `Depends`, so no local definition is needed.
