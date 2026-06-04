#' @importFrom fs dir_exists dir_create path file_exists
#' @importFrom glue glue
#' @importFrom jsonlite toJSON
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
#   <output_dir>/discover.json                        - manifest (Phase-2e shape)
#   <output_dir>/openapi.json                         - OpenAPI spec (stub OK)
#   <output_dir>/<endpoint>/default.json              - no-param response
#   <output_dir>/<endpoint>/<v1>_<v2>_..._<vn>.json   - param response
#                                                       (values only, lowercased,
#                                                        whitespace -> "_")
#
# Pattern: R functions x parameter combinations -> <output_dir>/**/*.json
# Reference:
#   - packages/shared-utils/src/producers/static-driver.ts (contract)
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

  # Export OpenAPI stub (StaticProducerDriver.readOpenApi contract)
  openapi_result <- export_openapi_stub(exports, pkg_name, pkg_version, output_dir)
  total_files <- total_files + openapi_result$files

  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  results <- list(
    files_created = total_files,
    total_size_kb = round(total_bytes / 1024, 1),
    functions_exported = functions_exported,
    elapsed_seconds = round(elapsed, 1)
  )

  if (verbose) {
    ui_done(glue::glue(
      "Exported {total_files} JSON files ({results$total_size_kb} KB) ",
      "for {length(functions_exported)} functions in {results$elapsed_seconds}s"
    ))
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
