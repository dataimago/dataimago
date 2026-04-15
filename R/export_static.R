#' @importFrom fs dir_exists dir_create path file_exists
#' @importFrom glue glue
#' @importFrom jsonlite toJSON
#' @importFrom crayon green silver yellow red bold blue
NULL

# ============================================================================
# export_static.R — Pre-compute R Analysis Results as Static JSON
# ============================================================================
#
# Enables serverless deployment (e.g., Vercel) by pre-computing all R
# analysis results as static JSON files. The dual-mode API client reads
# these files in production instead of hitting a live R server.
#
# Pattern: R functions × parameter combinations → public/api/*.json
# Reference: dissertation framework's static export workflow
# ============================================================================


#' Export Static API Data
#'
#' Enumerates parameter combinations for exported R functions and pre-computes
#' results as static JSON files. These files enable serverless deployment
#' where no R runtime is available (e.g., Vercel, Netlify, GitHub Pages).
#'
#' @param pkg_path Character. Path to the R package source directory
#' @param output_dir Character. Directory for JSON output files (typically
#'   \code{public/api/} in the NextJS project). Default: "public/api"
#' @param pkg_name Character. Package name. If NULL, read from DESCRIPTION.
#' @param param_grid List. Custom parameter combinations to enumerate. If NULL,
#'   combinations are inferred from roxygen enum values and defaults.
#' @param max_combinations Integer. Safety limit on total combinations per
#'   function. Default: 500
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
#' File naming convention:
#' \code{output_dir/<endpoint>/default.json} — default parameters
#' \code{output_dir/<endpoint>/<param1>-<val1>_<param2>-<val2>.json} — specific params
#'
#' @section Performance Equity:
#' Static JSON files are typically much smaller than dynamic responses because
#' they can be pre-compressed and cached at the CDN edge. This aligns with
#' dataimago's performance equity principle — users on constrained connections
#' get the same quality of data access.
#'
#' @export
export_static_api <- function(pkg_path,
                               output_dir = "public/api",
                               pkg_name = NULL,
                               param_grid = NULL,
                               max_combinations = 500L,
                               verbose = TRUE) {

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
    if (verbose) ui_warn("No exported functions found — nothing to export")
    return(invisible(list(files_created = 0, total_size_kb = 0)))
  }

  # Ensure output directory
  if (!fs::dir_exists(output_dir)) {
    fs::dir_create(output_dir, recurse = TRUE)
  }

  total_files <- 0L
  total_bytes <- 0L
  functions_exported <- character(0)

  for (fn_name in names(exports)) {
    fn_meta <- exports[[fn_name]]
    endpoint <- fn_to_endpoint(fn_name)

    # Create endpoint directory
    endpoint_dir <- fs::path(output_dir, endpoint)
    if (!fs::dir_exists(endpoint_dir)) {
      fs::dir_create(endpoint_dir, recurse = TRUE)
    }

    if (verbose) {
      ui_info(glue::glue("  Exporting: {fn_name} → /{endpoint}/"))
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

  # Export discovery endpoint
  discover_result <- export_discover_endpoint(exports, pkg_name, output_dir)
  total_files <- total_files + discover_result$files

  # Write manifest
  manifest <- list(
    package = pkg_name,
    generated = as.character(Sys.time()),
    generator = "dataimago::export_static_api()",
    endpoints = lapply(names(exports), function(fn) {
      list(
        function_name = fn,
        endpoint = fn_to_endpoint(fn),
        files = list.files(fs::path(output_dir, fn_to_endpoint(fn)), pattern = "\\.json$")
      )
    }),
    total_files = total_files,
    total_size_kb = round(total_bytes / 1024, 1)
  )

  manifest_path <- fs::path(output_dir, "manifest.json")
  writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE), manifest_path)
  total_files <- total_files + 1L

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
  tryCatch({
    fn <- getFromNamespace(fn_name, pkg_name)
    do.call(fn, params)
  }, error = function(e) {
    # Return error structure instead of NULL for debugging
    list(
      status = "error",
      message = paste("Static export error:", e$message),
      function_name = fn_name,
      params = params
    )
  })
}


#' Convert parameter combination to filename
#' @noRd
combo_to_filename <- function(combo) {
  if (length(combo) == 0) return("default.json")

  parts <- vapply(names(combo), function(k) {
    v <- as.character(combo[[k]])
    # Sanitize value for filename
    v_clean <- gsub("[^a-zA-Z0-9_.-]", "_", v)
    paste0(k, "-", v_clean)
  }, character(1))

  paste0(paste(sort(parts), collapse = "_"), ".json")
}


#' Export the discovery endpoint as static JSON
#' @noRd
export_discover_endpoint <- function(exports, pkg_name, output_dir) {
  discover_dir <- fs::path(output_dir, "discover")
  if (!fs::dir_exists(discover_dir)) {
    fs::dir_create(discover_dir, recurse = TRUE)
  }

  discover_data <- list(
    package = pkg_name,
    analyses = lapply(exports, function(fn_meta) {
      list(
        description = fn_meta$title,
        parameters = lapply(fn_meta$params, function(p) p$description)
      )
    })
  )

  json_content <- jsonlite::toJSON(discover_data, auto_unbox = TRUE, pretty = TRUE)
  writeLines(json_content, fs::path(discover_dir, "default.json"))

  list(files = 1L)
}
