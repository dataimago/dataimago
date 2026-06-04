#' @importFrom fs dir_exists dir_create path file_exists
#' @importFrom glue glue
#' @importFrom jsonlite toJSON
#' @importFrom crayon green silver yellow red bold blue
NULL

# ============================================================================
# generate_api.R -- Emit the Live-Producer Driver's Backing Server
# ============================================================================
#
# Phase 2e semantics: the `api.R` file emitted here is NOT a public API.
# It is the backing service the LiveProducerDriver dials when
# DATAIMAGO_PRODUCER=live. The only public HTTP surface in a generated
# project is the NextJS API route tree (/api/discover, /api/data/<endpoint>,
# /api/openapi.json) owned by the template at apps/template/src/app/api/.
#
# Consequences:
#   - This generator MUST NOT write into apps/template/src/app/api/**.
#     That tree is owned by the template checkout; overwriting it would
#     break the canonical routes. The `output_dir` argument should always
#     point at a project-local `R/` directory.
#   - The routes below (/<endpoint>, /discover, /openapi.json) become
#     internal endpoints from the NextJS process's point of view. CORS
#     is therefore unnecessary in production (same-network live driver)
#     but is preserved for developer-mode direct access.
#
# Key pattern: R as Source of Truth -> Live Producer Driver -> NextJS API
#   -> Web UI / MCP Tools
# ============================================================================


#' Parse Roxygen Documentation from R Source Files
#'
#' Reads all R source files in a package directory and extracts exported
#' function metadata: name, title, description, parameters (with types,
#' descriptions, defaults), and return value documentation.
#'
#' @param pkg_path Character. Path to the R package root (containing R/ directory)
#' @param verbose Logical. Print progress messages. Default: FALSE
#'
#' @return A named list of function metadata, keyed by function name. Each entry
#'   contains: name, title, description, params (list of parameter metadata),
#'   return_doc, exported (logical), examples.
#'
#' @details
#' This function parses roxygen2 comments directly from R source files rather
#' than relying on pre-rendered .Rd files. This allows generation from source
#' packages that haven't been documented yet.
#'
#' Parameter types are inferred from:
#' 1. Explicit type mentions in @@param descriptions ("Character", "Numeric", etc.)
#' 2. Default values in the function signature
#' 3. Enum-like patterns (quoted strings in descriptions)
#'
#' @export
parse_roxygen_exports <- function(pkg_path, verbose = FALSE) {
  r_dir <- fs::path(pkg_path, "R")
  if (!fs::dir_exists(r_dir)) {
    stop(glue::glue("No R/ directory found at '{pkg_path}'"), call. = FALSE)
  }

  r_files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE, ignore.case = TRUE)
  if (length(r_files) == 0) {
    warning("No .R files found in R/ directory")
    return(list())
  }

  all_functions <- list()

  for (r_file in r_files) {
    if (verbose) ui_info(glue::glue("Parsing: {basename(r_file)}"))
    lines <- readLines(r_file, warn = FALSE)

    # Find function definitions with preceding roxygen blocks
    func_defs <- grep("^[a-zA-Z_.][a-zA-Z0-9_.]*\\s*<-\\s*function\\s*\\(", lines)

    for (func_line_num in func_defs) {
      func_name <- sub("^([a-zA-Z_.][a-zA-Z0-9_.]*)\\s*<-.*", "\\1", lines[func_line_num])

      # Walk backwards to find roxygen block
      roxygen_lines <- character(0)
      i <- func_line_num - 1
      while (i >= 1 && grepl("^#'", lines[i])) {
        roxygen_lines <- c(lines[i], roxygen_lines)
        i <- i - 1
      }

      if (length(roxygen_lines) == 0) next

      # Check if exported
      is_exported <- any(grepl("^#'\\s*@export", roxygen_lines))
      if (!is_exported) next

      # Parse roxygen block
      func_meta <- parse_roxygen_block(roxygen_lines, func_name)

      # Parse function signature for defaults
      sig_defaults <- parse_function_defaults(lines, func_line_num)
      func_meta$params <- merge_param_defaults(func_meta$params, sig_defaults)
      validate_roxygen_contract(func_meta, lines, func_line_num)

      all_functions[[func_name]] <- func_meta
    }
  }

  if (verbose) {
    ui_done(glue::glue("Found {length(all_functions)} exported functions"))
  }

  all_functions
}


#' Generate the Live-Producer Driver's Backing Server
#'
#' Creates an `api.R` file with RestRserve endpoints for each exported
#' function in the target R package. In Phase 2e+ this file is the
#' **live-producer driver's backing service**, not a public API — the
#' NextJS API route tree (owned by `apps/template/src/app/api/`) remains
#' the sole public surface.
#'
#' @param pkg_path Character. Path to the source R package.
#' @param output_dir Character. Directory to write the generated `api.R`.
#'   Must NOT point into `apps/template/src/app/api/` — that tree is owned
#'   by the template and must never be overwritten by the generator.
#' @param pkg_name Character. Package name (used in generated code). If NULL,
#'   read from DESCRIPTION.
#' @param port Integer. Default port for the backing server. Default: 8000.
#' @param verbose Logical. Print progress. Default: TRUE.
#'
#' @return List with: files_created, endpoints_generated, function_count.
#'
#' @details
#' The generated server exposes:
#' - One GET endpoint per exported function (consumed by LiveProducerDriver)
#' - `/discover` — endpoint catalog, used by `/api/discover` in live mode
#' - `/openapi.json` — OpenAPI 3.0 spec, used by `/api/openapi.json`
#' - CORS headers, left permissive for developer-mode direct access; the
#'   live driver itself runs same-network against this server.
#'
#' @section Phase 2e Invariants:
#' - The only HTTP surface a browser or external caller should ever touch
#'   is the NextJS route tree. This generator does not scaffold that tree;
#'   it is supplied by the template at clone time and is the write-once
#'   public contract.
#' - Client code (`api-client.ts`) never talks to the server below directly.
#'
#' @section Ethical Alignment:
#' Generated servers inherit dataimago's ethical constraints through:
#' - Structured error responses (no stack traces in production)
#' - Data variable metadata endpoint for transparency
#' - Same-network invocation in production removes the CORS attack surface;
#'   developer-mode CORS should be tightened before any public exposure.
#'
#' @export
generate_api_scaffolding <- function(pkg_path,
                                     output_dir,
                                     pkg_name = NULL,
                                     port = 8000L,
                                     verbose = TRUE) {
  # Phase 2e write-once guard: never emit into the template's NextJS API
  # route tree. That tree is the sole public HTTP surface and is owned by
  # apps/template/src/app/api/.
  normalized_out <- normalizePath(output_dir, mustWork = FALSE, winslash = "/")
  if (grepl("/src/app/api(/|$)", normalized_out)) {
    stop(
      "generate_api_scaffolding() refuses to write into `src/app/api/` -- ",
      "the NextJS API route tree is owned by the template and must never ",
      "be overwritten. Use a project-local `R/` directory instead.",
      call. = FALSE
    )
  }

  # Read package name from DESCRIPTION if not provided
  if (is.null(pkg_name)) {
    desc_path <- fs::path(pkg_path, "DESCRIPTION")
    if (fs::file_exists(desc_path)) {
      desc_lines <- readLines(desc_path, warn = FALSE)
      pkg_line <- grep("^Package:", desc_lines, value = TRUE)
      if (length(pkg_line) > 0) {
        pkg_name <- trimws(sub("^Package:\\s*", "", pkg_line[1]))
      }
    }
    if (is.null(pkg_name)) {
      pkg_name <- basename(pkg_path)
    }
  }

  if (verbose) {
    ui_info(glue::glue("\U0001F310 Generating REST API scaffolding for '{pkg_name}'"))
  }

  # Parse exported functions

  exports <- parse_roxygen_exports(pkg_path, verbose = verbose)

  if (length(exports) == 0) {
    if (verbose) ui_warn("No exported functions found -- API scaffolding will be minimal")
  }

  # Generate api.R code
  api_code <- generate_api_code(exports, pkg_name, port)

  # Write api.R
  if (!fs::dir_exists(output_dir)) {
    fs::dir_create(output_dir, recurse = TRUE)
  }

  api_path <- fs::path(output_dir, "api.R")
  writeLines(api_code, api_path)

  results <- list(
    files_created = "R/api.R",
    endpoints_generated = names(exports),
    function_count = length(exports),
    api_path = api_path
  )

  if (verbose) {
    ui_done(glue::glue("Generated api.R with {length(exports)} endpoints"))
    for (fn in names(exports)) {
      ui_info(glue::glue("  GET /{fn_to_endpoint(fn)}"))
    }
    ui_info("  GET /discover")
    ui_info("  GET /openapi.json")
  }

  invisible(results)
}


# ============================================================================
# Internal: Roxygen Parsing Helpers
# ============================================================================

#' Parse a roxygen comment block into structured metadata
#' @noRd
parse_roxygen_block <- function(roxygen_lines, func_name) {
  # Strip #' prefix
  clean <- sub("^#'\\s?", "", roxygen_lines)

  meta <- list(
    name = func_name,
    title = "",
    description = "",
    params = list(),
    return_doc = "",
    exported = TRUE,
    examples = character(0)
  )

  # Parse @title (or first non-tag line)
  title_lines <- grep("^@title\\s+", clean, value = TRUE)
  if (length(title_lines) > 0) {
    meta$title <- sub("^@title\\s+", "", title_lines[1])
  } else {
    # First non-empty, non-tag line is the title
    non_tag <- clean[!grepl("^@", clean) & nchar(trimws(clean)) > 0]
    if (length(non_tag) > 0) {
      meta$title <- non_tag[1]
    }
  }

  # Parse @description (multi-line aware)
  desc_idx <- grep("^@description\\s+", clean)
  if (length(desc_idx) > 0) {
    desc_text <- sub("^@description\\s+", "", clean[desc_idx[1]])
    j <- desc_idx[1] + 1
    while (j <= length(clean) && !grepl("^@", clean[j]) && nchar(trimws(clean[j])) > 0) {
      desc_text <- paste(desc_text, trimws(clean[j]))
      j <- j + 1
    }
    meta$description <- desc_text
  } else if (length(non_tag) > 1) {
    # Second non-tag paragraph is description
    meta$description <- paste(non_tag[2:min(4, length(non_tag))], collapse = " ")
  }

  # Parse @param entries
  param_indices <- grep("^@param\\s+", clean)
  for (idx in param_indices) {
    param_line <- sub("^@param\\s+", "", clean[idx])
    # Parameter name is the first word
    param_name <- sub("^(\\S+)\\s.*", "\\1", param_line)
    param_desc <- sub("^\\S+\\s+", "", param_line)

    # Continue collecting multi-line param descriptions
    j <- idx + 1
    while (j <= length(clean) && !grepl("^@", clean[j]) && nchar(trimws(clean[j])) > 0) {
      param_desc <- paste(param_desc, trimws(clean[j]))
      j <- j + 1
    }

    # Infer type from description
    param_type <- infer_param_type(param_desc)

    # Extract enum values from description
    enum_vals <- extract_enum_values(param_desc)

    meta$params[[param_name]] <- list(
      name = param_name,
      description = trimws(param_desc),
      type = param_type,
      enum = enum_vals,
      default = NULL # Will be filled from function signature
    )
  }

  # Parse @return
  return_lines <- grep("^@return\\s+", clean, value = TRUE)
  if (length(return_lines) > 0) {
    meta$return_doc <- sub("^@return\\s+", "", return_lines[1])
  }

  meta
}


#' Parse function signature to extract parameter defaults
#' @noRd
parse_function_defaults <- function(lines, start_line) {
  # Collect the full function signature (may span multiple lines)
  sig <- ""
  paren_depth <- 0
  started <- FALSE

  for (i in start_line:min(start_line + 50, length(lines))) {
    line <- lines[i]
    sig <- paste0(sig, " ", line)

    # Count parentheses
    for (char in strsplit(line, "")[[1]]) {
      if (char == "(") {
        paren_depth <- paren_depth + 1
        started <- TRUE
      }
      if (char == ")") paren_depth <- paren_depth - 1
    }

    if (started && paren_depth <= 0) break
  }

  # Extract parameter defaults
  # Remove function name and outer parens
  sig_inner <- sub(".*function\\s*\\((.*)\\).*", "\\1", sig)

  defaults <- list()

  # Split by comma, respecting nested structures
  params <- split_params(sig_inner)

  for (p in params) {
    p <- trimws(p)
    if (nchar(p) == 0) next

    if (grepl("=", p)) {
      param_name <- trimws(sub("\\s*=.*", "", p))
      default_val <- trimws(sub(".*=\\s*", "", p))
      defaults[[param_name]] <- default_val
    } else {
      param_name <- trimws(p)
      defaults[[param_name]] <- NA # No default (required parameter)
    }
  }

  defaults
}


#' Split parameter string by commas, respecting nested parentheses and c()
#' @noRd
split_params <- function(sig) {
  params <- character(0)
  current <- ""
  depth <- 0

  for (char in strsplit(sig, "")[[1]]) {
    if (char %in% c("(", "[")) depth <- depth + 1
    if (char %in% c(")", "]")) depth <- depth - 1

    if (char == "," && depth == 0) {
      params <- c(params, current)
      current <- ""
    } else {
      current <- paste0(current, char)
    }
  }

  if (nchar(trimws(current)) > 0) {
    params <- c(params, current)
  }

  params
}


#' Merge roxygen parameter info with function signature defaults
#' @noRd
merge_param_defaults <- function(roxygen_params, sig_defaults) {
  # Add defaults from signature
  for (param_name in names(sig_defaults)) {
    default_val <- sig_defaults[[param_name]]

    if (param_name %in% names(roxygen_params)) {
      roxygen_params[[param_name]]$default <- default_val
      roxygen_params[[param_name]]$signature_default <- default_val

      # If default is c("a", "b", "c"), treat as enum
      if (!is.na(default_val) && grepl("^c\\(", default_val)) {
        enum_vals <- extract_c_values(default_val)
        if (length(enum_vals) > 0) {
          if (length(roxygen_params[[param_name]]$enum) == 0) {
            roxygen_params[[param_name]]$enum <- enum_vals
          }
          # First value is the default
          roxygen_params[[param_name]]$default <- paste0('"', enum_vals[1], '"')
        }
      }

      # Refine type from default if roxygen didn't specify
      if (roxygen_params[[param_name]]$type == "string" && !is.na(default_val)) {
        if (default_val %in% c("TRUE", "FALSE")) {
          roxygen_params[[param_name]]$type <- "boolean"
        } else if (grepl("^\\d+L?$", default_val)) {
          roxygen_params[[param_name]]$type <- "integer"
        } else if (grepl("^\\d+\\.?\\d*$", default_val)) {
          roxygen_params[[param_name]]$type <- "number"
        }
      }
    } else {
      # Parameter in signature but not in roxygen
      roxygen_params[[param_name]] <- list(
        name = param_name,
        description = param_name,
        type = infer_type_from_default(default_val),
        enum = NULL,
        default = default_val,
        signature_default = default_val
      )
    }
  }

  # Mark required parameters (no default)
  for (param_name in names(roxygen_params)) {
    if (is.null(roxygen_params[[param_name]]$default) || identical(roxygen_params[[param_name]]$default, NA)) {
      roxygen_params[[param_name]]$required <- TRUE
    } else {
      roxygen_params[[param_name]]$required <- FALSE
    }
  }

  roxygen_params
}


#' Validate generator-facing roxygen/signature contracts
#' @noRd
validate_roxygen_contract <- function(func_meta, lines, start_line) {
  for (param_name in names(func_meta$params)) {
    param <- func_meta$params[[param_name]]
    sig_default <- param$signature_default
    has_c_default <- !is.null(sig_default) &&
      !identical(sig_default, NA) &&
      grepl("^c\\(", sig_default)

    if (!has_c_default) next

    if (identical(param$type, "array")) {
      stop(glue::glue(
        "Invalid dataimago roxygen contract for `{func_meta$name}({param_name})`: ",
        "vector parameters must not use c() signature defaults. Make the array ",
        "parameter required or provide values through an explicit static export grid."
      ), call. = FALSE)
    }

    if (!function_uses_match_arg(lines, start_line, param_name)) {
      stop(glue::glue(
        "Invalid dataimago roxygen contract for `{func_meta$name}({param_name})`: ",
        "c() defaults are only supported for scalar enum parameters validated with ",
        "`{param_name} <- match.arg({param_name})`. Use a scalar default, make the ",
        "parameter required, or add the match.arg() validation."
      ), call. = FALSE)
    }
  }
}


#' Detect scalar enum validation in the function body
#' @noRd
function_uses_match_arg <- function(lines, start_line, param_name) {
  end_line <- min(start_line + 200L, length(lines))
  body <- lines[start_line:end_line]
  pattern <- paste0(
    "\\b", param_name,
    "\\s*<-\\s*match\\.arg\\s*\\(\\s*",
    param_name, "\\b"
  )
  any(grepl(pattern, body))
}


#' Infer JSON Schema type from roxygen parameter description
#' @noRd
infer_param_type <- function(desc) {
  desc_lower <- tolower(desc)
  if (grepl("\\blogical\\b", desc_lower)) {
    return("boolean")
  }
  if (grepl("\\binteger\\b", desc_lower)) {
    return("integer")
  }
  if (grepl("\\bnumeric\\b|\\bnumber\\b|\\bdouble\\b", desc_lower)) {
    return("number")
  }
  if (grepl("\\bcharacter\\s+vector\\b", desc_lower)) {
    return("array")
  }
  "string"
}


#' Infer JSON Schema type from a default value string
#' @noRd
infer_type_from_default <- function(default_val) {
  if (is.na(default_val)) {
    return("string")
  }
  if (default_val %in% c("TRUE", "FALSE")) {
    return("boolean")
  }
  if (grepl("^\\d+L$", default_val)) {
    return("integer")
  }
  if (grepl("^\\d+\\.?\\d*$", default_val)) {
    return("number")
  }
  if (grepl("^NULL$", default_val)) {
    return("string")
  }
  "string"
}


#' Extract enum values from roxygen description text
#' @noRd
extract_enum_values <- function(desc) {
  desc_lower <- tolower(desc)
  has_enum_marker <- grepl(
    "\\bone of\\b|allowed values?|options?:|choices?",
    desc_lower
  )

  # Pattern: "option1", "option2", "option3"
  quoted <- regmatches(desc, gregexpr('"[^"]*"', desc))[[1]]
  if (has_enum_marker && length(quoted) >= 2) {
    return(unique(gsub('"', "", quoted)))
  }

  # Pattern: Options: val1, val2, val3
  if (grepl("options?:", desc, ignore.case = TRUE)) {
    after_options <- sub(".*options?:\\s*", "", desc, ignore.case = TRUE)
    # Take up to period or end of line
    after_options <- sub("\\..*", "", after_options)
    vals <- trimws(strsplit(after_options, ",")[[1]])
    vals <- vals[nchar(vals) > 0 & nchar(vals) < 30]
    if (length(vals) >= 2) {
      return(vals)
    }
  }

  NULL
}


#' Extract values from c("a", "b", "c") expression
#' @noRd
extract_c_values <- function(c_expr) {
  inner <- sub("^c\\((.*)\\)$", "\\1", c_expr)
  quoted <- regmatches(inner, gregexpr('"[^"]*"', inner))[[1]]
  gsub('"', "", quoted)
}


#' Convert function name to URL endpoint path
#' @noRd
fn_to_endpoint <- function(fn_name) {
  # camelCase -> kebab-case
  endpoint <- gsub("([a-z])([A-Z])", "\\1-\\2", fn_name)
  # snake_case -> kebab-case
  endpoint <- gsub("_", "-", endpoint)
  tolower(endpoint)
}


# ============================================================================
# Internal: API Code Generation
# ============================================================================

#' Generate the full api.R source code
#' @noRd
generate_api_code <- function(exports, pkg_name, port) {
  # Build handler code for each function
  handler_blocks <- character(0)
  register_blocks <- character(0)
  cors_paths <- character(0)
  openapi_paths <- character(0)

  for (fn_name in names(exports)) {
    fn_meta <- exports[[fn_name]]
    endpoint <- fn_to_endpoint(fn_name)

    handler_blocks <- c(handler_blocks, generate_handler_code(fn_name, fn_meta, endpoint, pkg_name))
    register_blocks <- c(register_blocks, glue::glue('    app$add_get("/{endpoint}", {fn_name}_handler)'))
    cors_paths <- c(cors_paths, glue::glue('"/{endpoint}"'))
    openapi_paths <- c(openapi_paths, generate_openapi_path(fn_name, fn_meta, endpoint))
  }

  # Discovery endpoint
  discover_code <- generate_discover_endpoint(exports, pkg_name)

  cors_paths_str <- paste(c(cors_paths, '"/discover"', '"/openapi.json"'), collapse = ", ")

  # Assemble the full file
  c(
    glue::glue("# Auto-generated REST API for {pkg_name}"),
    glue::glue("# Generated by dataimago::generate_api_scaffolding()"),
    glue::glue("# Date: {Sys.Date()}"),
    "#",
    "# This file exposes R package functions as REST endpoints using RestRserve.",
    "# Pattern: R as Source of Truth -> REST API -> MCP Tools -> Web UI",
    "#",
    "# DO NOT EDIT MANUALLY -- regenerate with dataimago::generate_api_scaffolding()",
    "",
    "#' @import RestRserve",
    "#' @importFrom jsonlite toJSON",
    "NULL",
    "",
    "",
    glue::glue("#' Create {pkg_name} API Application"),
    "#'",
    glue::glue("#' @description Creates and configures a RestRserve application exposing"),
    glue::glue("#' {pkg_name} functions as REST endpoints."),
    "#' @return A configured RestRserve application object",
    "#' @export",
    glue::glue("create_{pkg_name}_api <- function() {{"),
    "    app <- RestRserve::Application$new()",
    "",
    "    ## CORS helper",
    "    add_cors_headers <- function(response) {",
    '        response$set_header("Access-Control-Allow-Origin", "*")',
    '        response$set_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")',
    '        response$set_header("Access-Control-Allow-Headers", "Content-Type")',
    "    }",
    "",
    paste(handler_blocks, collapse = "\n\n"),
    "",
    discover_code,
    "",
    generate_openapi_endpoint(exports, pkg_name, openapi_paths),
    "",
    "    ## Register endpoints",
    paste(register_blocks, collapse = "\n"),
    '    app$add_get("/discover", discover_handler)',
    '    app$add_get("/openapi.json", openapi_handler)',
    "",
    "    ## CORS preflight handlers",
    "    cors_preflight <- function(req, res) {",
    "        add_cors_headers(res)",
    "        res$set_status_code(204L)",
    "    }",
    glue::glue("    for (path in c({cors_paths_str})) {{"),
    "        app$add_options(path, cors_preflight)",
    "    }",
    "",
    "    return(app)",
    "}",
    "",
    "",
    glue::glue("#' Run {pkg_name} API"),
    "#'",
    glue::glue("#' @description Starts the {pkg_name} REST API server."),
    glue::glue("#' @param port Integer. Port number (default: {port})."),
    '#\' @param host Character. Host address (default: "127.0.0.1").',
    "#' @return None (starts server, blocks until terminated)",
    "#' @export",
    glue::glue('run_{pkg_name}_api <- function(port = {port}L, host = "127.0.0.1") {{'),
    glue::glue("    app <- create_{pkg_name}_api()"),
    "    backend <- RestRserve::BackendRserve$new()",
    "    backend$start(app, http_port = port, host = host)",
    "}"
  ) |> paste(collapse = "\n")
}


#' Generate handler code for a single function endpoint
#' @noRd
generate_handler_code <- function(fn_name, fn_meta, endpoint, pkg_name) {
  # Build query parameter extraction
  param_extractions <- character(0)
  call_args <- character(0)

  for (param_name in names(fn_meta$params)) {
    p <- fn_meta$params[[param_name]]

    # Determine default value for query parameter
    default_str <- if (!is.null(p$default) && !is.na(p$default)) {
      # Clean R default for use as string default
      clean_default <- gsub('^"|"$', "", as.character(p$default))
      if (p$type == "boolean") {
        tolower(clean_default)
      } else {
        clean_default
      }
    } else {
      "NULL"
    }

    # Type conversion
    if (p$type == "boolean") {
      param_extractions <- c(
        param_extractions,
        glue::glue("        {param_name}_raw <- request$get_query_parameter('{param_name}', default = '{default_str}')"),
        glue::glue("        {param_name} <- as.logical({param_name}_raw)"),
        glue::glue("        if (is.na({param_name})) {param_name} <- FALSE")
      )
    } else if (p$type %in% c("integer", "number")) {
      conversion_fn <- if (p$type == "integer") "as.integer" else "as.numeric"
      param_extractions <- c(
        param_extractions,
        glue::glue("        {param_name}_raw <- request$get_query_parameter('{param_name}', default = '{default_str}')"),
        glue::glue("        {param_name} <- {conversion_fn}({param_name}_raw)")
      )
    } else {
      param_extractions <- c(
        param_extractions,
        glue::glue("        {param_name} <- request$get_query_parameter('{param_name}', default = '{default_str}')")
      )
    }

    call_args <- c(call_args, glue::glue("{param_name} = {param_name}"))
  }

  param_block <- paste(param_extractions, collapse = "\n")
  call_args_str <- paste(call_args, collapse = ",\n                ")

  c(
    glue::glue("    ## ---- /{endpoint} endpoint ----"),
    glue::glue("    {fn_name}_handler <- function(request, response) {{"),
    "        add_cors_headers(response)",
    "        tryCatch({",
    param_block,
    "",
    glue::glue("            result <- {pkg_name}::{fn_name}("),
    glue::glue("                {call_args_str}"),
    "            )",
    "",
    "            response$set_content_type('application/json')",
    "            response$set_status_code(if (identical(result$status, 'success')) 200L else 400L)",
    "            response$set_body(jsonlite::toJSON(result, auto_unbox = TRUE, dataframe = 'rows'))",
    "        }, error = function(e) {",
    "            error_result <- list(",
    "                status = 'error',",
    "                message = as.character(e$message),",
    glue::glue("                endpoint = '/{endpoint}',"),
    "                timestamp = as.character(Sys.time()),",
    "                code = 'INTERNAL_ERROR'",
    "            )",
    "            response$set_content_type('application/json')",
    "            response$set_status_code(500L)",
    "            response$set_body(jsonlite::toJSON(error_result, auto_unbox = TRUE))",
    "        })",
    "    }"
  ) |> paste(collapse = "\n")
}


#' Generate discovery endpoint code
#' @noRd
generate_discover_endpoint <- function(exports, pkg_name) {
  # Build analysis list
  analysis_entries <- character(0)
  for (fn_name in names(exports)) {
    fn_meta <- exports[[fn_name]]
    desc <- gsub('"', '\\\\"', fn_meta$title)

    param_entries <- character(0)
    for (p_name in names(fn_meta$params)) {
      p <- fn_meta$params[[p_name]]
      p_desc <- gsub('"', '\\\\"', p$description)
      param_entries <- c(param_entries, glue::glue('                    {p_name} = "{p_desc}"'))
    }

    analysis_entries <- c(analysis_entries, paste(c(
      glue::glue("                {fn_name} = list("),
      glue::glue('                    description = "{desc}",'),
      "                    parameters = list(",
      paste(param_entries, collapse = ",\n"),
      "                    )",
      "                )"
    ), collapse = "\n"))
  }

  c(
    "    ## ---- /discover endpoint ----",
    "    discover_handler <- function(request, response) {",
    "        add_cors_headers(response)",
    "        tryCatch({",
    "            result <- list(",
    glue::glue("                package = '{pkg_name}',"),
    "                analyses = list(",
    paste(analysis_entries, collapse = ",\n"),
    "                )",
    "            )",
    "            response$set_content_type('application/json')",
    "            response$set_status_code(200L)",
    "            response$set_body(jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE))",
    "        }, error = function(e) {",
    "            error_result <- list(",
    "                status = 'error',",
    "                message = as.character(e$message),",
    "                endpoint = '/discover',",
    "                timestamp = as.character(Sys.time()),",
    "                code = 'INTERNAL_ERROR'",
    "            )",
    "            response$set_content_type('application/json')",
    "            response$set_status_code(500L)",
    "            response$set_body(jsonlite::toJSON(error_result, auto_unbox = TRUE))",
    "        })",
    "    }"
  ) |> paste(collapse = "\n")
}


#' Generate OpenAPI specification endpoint code
#' @noRd
generate_openapi_endpoint <- function(exports, pkg_name, openapi_path_blocks) {
  c(
    "    ## ---- /openapi.json endpoint ----",
    "    openapi_handler <- function(request, response) {",
    "        add_cors_headers(response)",
    "        tryCatch({",
    "            spec <- list(",
    "                openapi = '3.0.0',",
    "                info = list(",
    glue::glue("                    title = '{pkg_name} API',"),
    "                    version = '1.0.0',",
    glue::glue("                    description = 'REST API for {pkg_name} -- auto-generated by dataimago'"),
    "                ),",
    "                paths = list()",
    "            )",
    "            response$set_content_type('application/json')",
    "            response$set_status_code(200L)",
    "            response$set_body(jsonlite::toJSON(spec, auto_unbox = TRUE, pretty = TRUE))",
    "        }, error = function(e) {",
    "            error_result <- list(",
    '                status = "error",',
    "                message = as.character(e$message),",
    '                endpoint = "/openapi.json",',
    "                timestamp = as.character(Sys.time()),",
    '                code = "OPENAPI_ERROR"',
    "            )",
    '            response$set_content_type("application/json")',
    "            response$set_status_code(500L)",
    "            response$set_body(jsonlite::toJSON(error_result, auto_unbox = TRUE))",
    "        })",
    "    }"
  ) |> paste(collapse = "\n")
}


#' Generate OpenAPI path entry for a function
#' @noRd
generate_openapi_path <- function(fn_name, fn_meta, endpoint) {
  # Returns a string to be used in the OpenAPI spec paths object
  # Keeping this simple -- the full spec is generated dynamically

  endpoint
}
