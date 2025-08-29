#' @importFrom cli symbol
#' 
#' Synchronize Assets Across Quarto Directories
#'
#' @description
#' Synchronizes assets from quarto_website/assets/ to quarto_website/_extensions/
#' using a single source of truth approach.
#'
#' @details
#' This function establishes `quarto_website/assets/` as the **source of truth** for:
#' - Custom CSS files (*.css)
#' - SCSS source files (*.scss) 
#' - JavaScript files (*.js)
#' 
#' **Source of Truth Hierarchy**:
#' 1. `ui/src/` - Design system tokens and base styles (build system input)
#' 2. `quarto_website/assets/` - Quarto-specific styling and overrides (**source of truth**)
#' 3. `quarto_website/_extensions/` - Distribution copies (synchronized FROM assets)
#' 4. `inst/quarto-assets/` - CDN distribution (synchronized from extensions)
#' 
#' The function:
#' 1. Identifies files newer in assets/ than extensions/
#' 2. Copies missing and updated files FROM assets TO extensions
#' 3. **Never** overwrites assets/ (preserves source of truth)
#' 4. Reports synchronization status with added/updated distinction
#' 
#' **Important**: This ensures `quarto render` has consistent assets while
#' preserving the assets/ directory as the authoritative source.
#'
#' @param verbose Logical. Print detailed progress information. Default: TRUE
#' 
#' @concept dataimago asset-management quarto-synchronization
#' @keywords asset-sync
#' 
#' @return List containing:
#' \describe{
#'   \item{success}{Logical indicating synchronization success}
#'   \item{synced_files}{Character vector of files that were synchronized}
#'   \item{errors}{Character vector of any error messages}
#' }
#' 
#' @examples
#' \dontrun{
#' # Synchronize all assets
#' result <- sync_quarto_assets()
#' 
#' # Check synchronization status
#' if (result$success) {
#'   cat("Assets synchronized successfully")
#' } else {
#'   cat("Synchronization errors:", paste(result$errors, collapse = "; "))
#' }
#' 
#' # Silent synchronization
#' sync_quarto_assets(verbose = FALSE)
#' }
#' 
#' @export
sync_quarto_assets <- function(verbose = TRUE) {
  if (verbose) {
    cat(crayon::blue(cli::symbol$info), "Synchronizing assets across quarto directories...\n")
  }
  
  # Get base directories
  base_dir <- getwd()
  
  quarto_dir <- file.path(base_dir, "quarto_website")
  assets_dir <- file.path(quarto_dir, "assets")
  extensions_dir <- file.path(quarto_dir, "_extensions", "dataimago", "ai-native", "assets")
  docs_dir <- file.path(base_dir, "docs")
  
  errors <- character()
  synced_files <- character()
  
  # Verify directories exist
  if (!dir.exists(quarto_dir)) {
    errors <- c(errors, "quarto_website directory not found")
    return(list(success = FALSE, synced_files = character(), errors = errors))
  }
  
  # Ensure extension directory exists
  if (!dir.exists(extensions_dir)) {
    dir.create(extensions_dir, recursive = TRUE, showWarnings = FALSE)
    if (verbose) {
      cat(crayon::blue(cli::symbol$info), "Created extensions directory:", extensions_dir, "\n")
    }
  }
  
  # 1. Sync CSS files (assets/css is source of truth for custom CSS)
  css_source <- file.path(assets_dir, "css")
  css_extension <- file.path(extensions_dir, "css")
  
  if (dir.exists(css_source) && dir.exists(css_extension)) {
    css_files <- list.files(css_source, pattern = "\\.css$", full.names = FALSE)
    extension_files <- list.files(css_extension, pattern = "\\.css$", full.names = FALSE)
    
    # Exclude compiled files that should come from build system
    compiled_files <- c("dataimago.css", "dataimago.min.css", "tokens.css")
    css_files <- setdiff(css_files, compiled_files)
    
    # Assets directory is source of truth - copy TO extensions
    missing_in_extensions <- setdiff(css_files, extension_files)
    
    # Also check for files that need updating (newer in assets)
    update_in_extensions <- character()
    for (file in intersect(css_files, extension_files)) {
      source_file <- file.path(css_source, file)
      target_file <- file.path(css_extension, file)
      if (file.exists(source_file) && file.exists(target_file)) {
        if (file.info(source_file)$mtime > file.info(target_file)$mtime) {
          update_in_extensions <- c(update_in_extensions, file)
        }
      }
    }
    
    # All files that need to be copied to extensions
    files_to_copy <- unique(c(missing_in_extensions, update_in_extensions))
    
    if (length(files_to_copy) > 0) {
      if (verbose) {
        cat(crayon::yellow(cli::symbol$warning), 
            "Synchronizing", length(files_to_copy), "CSS files to extensions...\n")
      }
      for (file in files_to_copy) {
        tryCatch({
          file.copy(
            file.path(css_source, file),
            file.path(css_extension, file),
            overwrite = TRUE
          )
          synced_files <- c(synced_files, file.path("extensions/css", file))
          if (verbose) {
            status_msg <- if (file %in% missing_in_extensions) "Added" else "Updated"
            cat(crayon::green(cli::symbol$tick), status_msg, file, "in extensions\n")
          }
        }, error = function(e) {
          errors <- c(errors, glue::glue("Failed to copy {file} to extensions: {e$message}"))
        })
      }
    }
  }
  
  # 2. Sync SCSS files (assets/css is source of truth for SCSS)
  if (dir.exists(css_source) && dir.exists(css_extension)) {
    scss_files <- list.files(css_source, pattern = "\\.scss$", full.names = FALSE)
    extension_scss_files <- list.files(css_extension, pattern = "\\.scss$", full.names = FALSE)
    
    # Assets directory is source of truth - copy TO extensions
    missing_scss_in_extensions <- setdiff(scss_files, extension_scss_files)
    
    # Check for files that need updating (newer in assets)
    update_scss_in_extensions <- character()
    for (file in intersect(scss_files, extension_scss_files)) {
      source_file <- file.path(css_source, file)
      target_file <- file.path(css_extension, file)
      if (file.exists(source_file) && file.exists(target_file)) {
        if (file.info(source_file)$mtime > file.info(target_file)$mtime) {
          update_scss_in_extensions <- c(update_scss_in_extensions, file)
        }
      }
    }
    
    # All SCSS files that need to be copied to extensions
    scss_to_copy <- unique(c(missing_scss_in_extensions, update_scss_in_extensions))
    
    if (length(scss_to_copy) > 0) {
      if (verbose) {
        cat(crayon::yellow(cli::symbol$warning), 
            "Synchronizing", length(scss_to_copy), "SCSS files to extensions...\n")
      }
      for (file in scss_to_copy) {
        tryCatch({
          file.copy(
            file.path(css_source, file),
            file.path(css_extension, file),
            overwrite = TRUE
          )
          synced_files <- c(synced_files, file.path("extensions/css", file))
          if (verbose) {
            status_msg <- if (file %in% missing_scss_in_extensions) "Added" else "Updated"
            cat(crayon::green(cli::symbol$tick), status_msg, file, "in extensions\n")
          }
        }, error = function(e) {
          errors <- c(errors, glue::glue("Failed to copy {file} to extensions: {e$message}"))
        })
      }
    }
  }

  # 3. Sync JS files (assets/js is source of truth)
  js_source <- file.path(assets_dir, "js")
  js_extension <- file.path(extensions_dir, "js")
  
  if (dir.exists(js_source) && dir.exists(js_extension)) {
    js_files <- list.files(js_source, pattern = "\\.js$", full.names = FALSE)
    extension_js_files <- list.files(js_extension, pattern = "\\.js$", full.names = FALSE)
    
    # Assets directory is source of truth - copy TO extensions
    missing_js_in_extensions <- setdiff(js_files, extension_js_files)
    
    # Check for files that need updating (newer in assets)
    update_js_in_extensions <- character()
    for (file in intersect(js_files, extension_js_files)) {
      source_file <- file.path(js_source, file)
      target_file <- file.path(js_extension, file)
      if (file.exists(source_file) && file.exists(target_file)) {
        if (file.info(source_file)$mtime > file.info(target_file)$mtime) {
          update_js_in_extensions <- c(update_js_in_extensions, file)
        }
      }
    }
    
    # All JS files that need to be copied to extensions
    js_to_copy <- unique(c(missing_js_in_extensions, update_js_in_extensions))
    
    if (length(js_to_copy) > 0) {
      if (verbose) {
        cat(crayon::yellow(cli::symbol$warning), 
            "Synchronizing", length(js_to_copy), "JS files to extensions...\n")
      }
      for (file in js_to_copy) {
        tryCatch({
          file.copy(
            file.path(js_source, file),
            file.path(js_extension, file),
            overwrite = TRUE
          )
          synced_files <- c(synced_files, file.path("extensions/js", file))
          if (verbose) {
            status_msg <- if (file %in% missing_js_in_extensions) "Added" else "Updated"
            cat(crayon::green(cli::symbol$tick), status_msg, file, "in extensions\n")
          }
        }, error = function(e) {
          errors <- c(errors, glue::glue("Failed to copy {file} to extensions: {e$message}"))
        })
      }
    }
  }
  
  # 4. Report status
  if (length(synced_files) == 0 && length(errors) == 0) {
    if (verbose) {
      cat(crayon::green(cli::symbol$tick), "All assets already synchronized\n")
    }
  } else if (length(errors) > 0) {
    if (verbose) {
      cat(crayon::red(cli::symbol$cross), "Synchronization completed with errors:\n")
      for (error in errors) {
        cat(crayon::red("  -"), error, "\n")
      }
    }
  } else {
    if (verbose) {
      cat(crayon::green(cli::symbol$tick), "Synchronized", length(synced_files), "asset files\n")
    }
  }
  
  return(list(
    success = length(errors) == 0,
    synced_files = synced_files,
    errors = errors
  ))
}

#' Check Quarto Render Asset Status
#'
#' @description
#' Analyzes what happens to assets during `quarto render` and identifies
#' potential issues with asset copying to the docs/ directory.
#'
#' @details
#' This function helps understand the Quarto rendering process:
#' 
#' **CSS Files**: 
#' - Quarto copies CSS files from `assets/css/` to `docs/assets/css/`
#' - CSS files referenced in YAML frontmatter are automatically included
#' 
#' **JavaScript Files**:
#' - JS files in `assets/js/` are NOT automatically copied to `docs/assets/js/`
#' - JS files must be referenced in `include-after` or `include-before` YAML
#' - Only files referenced in HTML `<script>` tags get copied
#' 
#' **Extensions**:
#' - Extension assets are used during rendering but may not be copied to docs/
#' - Extensions provide a way to package assets for reuse across projects
#'
#' @param verbose Logical. Print detailed analysis. Default: TRUE
#' 
#' @concept dataimago quarto-rendering asset-analysis
#' @keywords quarto render analysis
#' 
#' @return List containing analysis of asset status across directories
#' 
#' @examples
#' \dontrun{
#' # Analyze asset status
#' status <- check_quarto_asset_status()
#' 
#' # Check what files are missing after render
#' if (length(status$missing_in_docs) > 0) {
#'   cat("Files not copied to docs:", paste(status$missing_in_docs, collapse = ", "))
#' }
#' }
#' 
#' @export
check_quarto_asset_status <- function(verbose = TRUE) {
  if (verbose) {
    cat(crayon::blue(cli::symbol$info), "Analyzing Quarto asset status...\n")
  }
  
  # Get base directories
  base_dir <- getwd()
  
  quarto_dir <- file.path(base_dir, "quarto_website")
  assets_dir <- file.path(quarto_dir, "assets")
  docs_dir <- file.path(base_dir, "docs")
  
  analysis <- list(
    css_in_assets = character(),
    css_in_docs = character(),
    js_in_assets = character(),
    js_in_docs = character(),
    missing_css_in_docs = character(),
    missing_js_in_docs = character()
  )
  
  # Check CSS files
  css_assets_dir <- file.path(assets_dir, "css")
  css_docs_dir <- file.path(docs_dir, "assets", "css")
  
  if (dir.exists(css_assets_dir)) {
    analysis$css_in_assets <- list.files(css_assets_dir, pattern = "\\.css$")
  }
  
  if (dir.exists(css_docs_dir)) {
    analysis$css_in_docs <- list.files(css_docs_dir, pattern = "\\.css$")
    analysis$missing_css_in_docs <- setdiff(analysis$css_in_assets, analysis$css_in_docs)
  }
  
  # Check JS files  
  js_assets_dir <- file.path(assets_dir, "js")
  js_docs_dir <- file.path(docs_dir, "assets", "js")
  
  if (dir.exists(js_assets_dir)) {
    analysis$js_in_assets <- list.files(js_assets_dir, pattern = "\\.js$")
  }
  
  if (dir.exists(js_docs_dir)) {
    analysis$js_in_docs <- list.files(js_docs_dir, pattern = "\\.js$")
    analysis$missing_js_in_docs <- setdiff(analysis$js_in_assets, analysis$js_in_docs)
  } else {
    analysis$missing_js_in_docs <- analysis$js_in_assets
  }
  
  if (verbose) {
    cat("\n", crayon::bold("Asset Status Analysis:"), "\n")
    cat("CSS Files:\n")
    cat("  - In assets/css/:", length(analysis$css_in_assets), "files\n")
    cat("  - In docs/assets/css/:", length(analysis$css_in_docs), "files\n")
    if (length(analysis$missing_css_in_docs) > 0) {
      cat(crayon::red("  - Missing in docs:"), paste(analysis$missing_css_in_docs, collapse = ", "), "\n")
    } else {
      cat(crayon::green("  - All CSS files present in docs\n"))
    }
    
    cat("\nJavaScript Files:\n")
    cat("  - In assets/js/:", length(analysis$js_in_assets), "files\n")
    cat("  - In docs/assets/js/:", length(analysis$js_in_docs), "files\n")
    if (length(analysis$missing_js_in_docs) > 0) {
      cat(crayon::yellow("  - Missing in docs:"), paste(analysis$missing_js_in_docs, collapse = ", "), "\n")
      cat(crayon::blue("  - Note: JS files must be referenced in _quarto.yml include-after to be copied\n"))
    } else {
      cat(crayon::green("  - All JS files present in docs\n"))
    }
    
    cat("\n", crayon::bold("Quarto Render Behavior:"), "\n")
    cat("[OK] CSS: Automatically copied from assets/css/ to docs/assets/css/\n")
    cat("[WARN] JS: Only copied if referenced in include-after/include-before\n")
    cat("[INFO] Extensions: Used during render, may not be copied to docs/\n")
  }
  
  return(analysis)
}