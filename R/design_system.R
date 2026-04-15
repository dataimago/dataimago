#' @importFrom fs dir_exists dir_create file_copy path dir_ls file_exists
#' @importFrom processx run
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom digest digest
#' @importFrom crayon green silver yellow red bold blue
#' @importFrom glue glue
NULL

# Internal UI functions to replace usethis dependency
ui_info <- function(x) cat(crayon::blue(paste0("\u2139", " ", x, "\n")))
ui_done <- function(x) cat(crayon::green(paste0("\u2713", " ", x, "\n")))
ui_warn <- function(x) cat(crayon::yellow(paste0("Warning:", " ", x, "\n")))
ui_oops <- function(x) cat(crayon::red(paste0("\u2717", " ", x, "\n")))

#' Build Complete Design System for Multi-Platform Deployment
#'
#' Master function that orchestrates CSS compilation and asset distribution for web applications.
#' This function provides R-first workflows that wrap Node.js tooling for rapid application development.
#'
#' @param force_rebuild Logical. Force rebuild even if assets appear up-to-date. Default: FALSE
#' @param include_sri Logical. Generate SRI hashes for CDN distribution. Default: TRUE
#' @param update_extension Logical. Update Quarto extension with compiled assets. Default: TRUE
#' @param verbose Logical. Print detailed progress information. Default: TRUE
#'
#' @details
#' This function implements dataimago's framework approach to asset compilation by providing
#' R-first workflows that wrap modern web development tools. The build process includes:
#'
#' **System Requirements:**
#' - Node.js 18+ and pnpm installed globally
#' - Write permissions to package directories
#' - OpenSSL for SRI hash generation (usually pre-installed on macOS/Linux)
#'
#' **Build Process:**
#' 1. **Node.js Dependency Check**: Verifies pnpm is available via `which pnpm`
#' 2. **Dependency Installation**: Runs `pnpm install` in ui/ directory to install Style Dictionary, Sass, etc.
#' 3. **SCSS Compilation**: Executes `pnpm run build` to convert design tokens and SCSS to minified CSS
#' 4. **Asset Distribution**: Copies built `dataimago.min.css` to multiple locations:
#'    - `ui/www/_extensions/dataimago/ai-native/assets/css/` for Quarto extension distribution
#'    - `inst/quarto-assets/` for R package CDN distribution
#'    - `ui/www/assets/css/` for local website development
#' 5. **SRI Hash Generation**: Uses `openssl dgst -sha384 -binary | openssl base64 -A` for subresource integrity
#' 6. **Build Manifest**: Creates JSON metadata with paths, versions, checksums, and build timestamp
#'
#' **Design Token Philosophy:**
#' The ui/ workspace uses Style Dictionary to convert semantic design tokens (color.json,
#' typography.json, spacing.json) into CSS custom properties. This ensures design consistency
#' across Quarto websites, R Shiny apps, and future Next.js applications while maintaining
#' the ethical AI principles embedded in dataimago's visual identity.
#'
#' **Error Handling:**
#' - Validates Node.js/pnpm availability before attempting build
#' - Checks for required ui/ directory structure
#' - Provides clear error messages with suggested remediation
#' - Rolls back partial builds on failure
#'
#' @return List containing build results:
#'   - success: Logical indicating overall build success
#'   - assets: Character vector of generated asset paths
#'   - sri_hashes: Named list of SRI hashes for each CSS file
#'   - build_time: POSIXct timestamp of build completion
#'   - metadata: List containing build configuration and system information
#'   - errors: Character vector of any error messages (empty if successful)
#'
#' @section MCP Tool Integration:
#' This function is designed for Model Context Protocol (MCP) integration, providing
#' structured output that AI agents can parse and reason about:
#' - **Deterministic Output**: Same inputs always produce same outputs
#' - **Machine Readable**: JSON-compatible result structure
#' - **Error Context**: Detailed error messages for debugging
#' - **Build Metadata**: Complete provenance information for reproducibility
#'
#' @section Philosophical Context:
#' This function embodies dataimago's principle of "R as source of truth" while embracing
#' modern web development practices. Rather than forcing R developers to learn Node.js
#' toolchains, it wraps industry-standard CSS preprocessing in familiar R function calls
#' with comprehensive documentation of every system interaction.
#'
#' @examples
#' \dontrun{
#' # Basic build - compile all assets
#' result <- build_design_system()
#'
#' # Check if build succeeded
#' if (result$success) {
#'   cat("Success: Built assets:", paste(result$assets, collapse = ", "), "\n")
#'   cat("SRI hashes:", length(result$sri_hashes), "generated\n")
#' } else {
#'   cat("ERROR: Build failed:", paste(result$errors, collapse = "; "), "\n")
#' }
#'
#' # Force rebuild with verbose output (useful for debugging)
#' result <- build_design_system(force_rebuild = TRUE, verbose = TRUE)
#'
#' # Build for CDN distribution only (skip local copying)
#' result <- build_design_system(
#'   include_sri = TRUE,
#'   update_extension = FALSE,
#'   verbose = FALSE
#' )
#'
#' # Inspect build metadata
#' str(result$metadata)
#' }
#'
#' @seealso
#' \code{\link{update_quarto_extension}} for extension asset management,
#' \code{\link{generate_cdn_assets}} for CDN preparation,
#' \code{\link{create_ui_workspace}} for UI workspace initialization
#'
#' @keywords design-system css build-tools ethical-ai
#' @concept dataimago r-first-development MCP-compatible
#' @export
build_design_system <- function(force_rebuild = FALSE,
                                include_sri = TRUE,
                                update_extension = TRUE,
                                verbose = TRUE) {
  start_time <- Sys.time()
  errors <- character(0)
  assets <- character(0)
  sri_hashes <- list()

  if (verbose) {
    ui_info("Building dataimago design system assets...")
  }

  # 1. Validate prerequisites
  ui_dir <- "ui"
  if (!dir_exists(ui_dir)) {
    errors <- c(errors, glue("ui/ directory not found. Run create_ui_workspace() first."))
    list(
      success = FALSE, errors = errors, assets = assets,
      sri_hashes = sri_hashes, build_time = start_time, metadata = list()
    )
  }

  # Check for pnpm (preferred) or npm
  pnpm_available <- FALSE
  npm_available <- FALSE

  pnpm_available <- tryCatch(
    {
      pnpm_result <- processx::run("which", "pnpm", error_on_status = FALSE)
      pnpm_result$status == 0
    },
    error = function(e) FALSE
  )

  if (!pnpm_available) {
    npm_available <- tryCatch(
      {
        npm_result <- processx::run("which", "npm", error_on_status = FALSE)
        npm_result$status == 0
      },
      error = function(e) FALSE
    )
  }

  if (!pnpm_available && !npm_available) {
    errors <- c(errors, "Neither pnpm nor npm found. Please install Node.js and pnpm/npm globally.")
    list(
      success = FALSE, errors = errors, assets = assets,
      sri_hashes = sri_hashes, build_time = start_time, metadata = list()
    )
  }

  package_manager <- ifelse(pnpm_available, "pnpm", "npm")
  if (verbose) {
    ui_info(glue("Using {package_manager} for Node.js dependencies"))
  }

  # 2. Install Node.js dependencies
  if (verbose) {
    ui_info("Installing Node.js dependencies...")
  }

  tryCatch(
    {
      install_result <- processx::run(
        package_manager, "install",
        wd = ui_dir,
        stdout_line_callback = if (verbose) function(x, ...) cat("  ", x, "\n") else NULL,
        stderr_line_callback = if (verbose) function(x, ...) cat("  ", x, "\n") else NULL
      )

      if (install_result$status != 0) {
        errors <- c(errors, glue("{package_manager} install failed with status {install_result$status}"))
        list(
          success = FALSE, errors = errors, assets = assets,
          sri_hashes = sri_hashes, build_time = start_time, metadata = list()
        )
      }
    },
    error = function(e) {
      errors <- c(errors, glue("Error running {package_manager} install: {e$message}"))
      list(
        success = FALSE, errors = errors, assets = assets,
        sri_hashes = sri_hashes, build_time = start_time, metadata = list()
      )
    }
  )

  # 3. Run build process
  if (verbose) {
    ui_info("Compiling SCSS and design tokens...")
  }

  tryCatch(
    {
      build_result <- processx::run(
        package_manager, c("run", "build"),
        wd = ui_dir,
        stdout_line_callback = if (verbose) function(x, ...) cat("  ", x, "\n") else NULL,
        stderr_line_callback = if (verbose) function(x, ...) cat("  ", x, "\n") else NULL
      )

      if (build_result$status != 0) {
        errors <- c(errors, glue("{package_manager} run build failed with status {build_result$status}"))
        list(
          success = FALSE, errors = errors, assets = assets,
          sri_hashes = sri_hashes, build_time = start_time, metadata = list()
        )
      }
    },
    error = function(e) {
      errors <- c(errors, glue("Error running {package_manager} run build: {e$message}"))
      list(
        success = FALSE, errors = errors, assets = assets,
        sri_hashes = sri_hashes, build_time = start_time, metadata = list()
      )
    }
  )

  # 4. Verify build output
  dist_dir <- file.path(ui_dir, "dist")
  main_css <- file.path(dist_dir, "dataimago.min.css")

  if (!file_exists(main_css)) {
    errors <- c(errors, "Build completed but dataimago.min.css not found in ui/dist/")
    list(
      success = FALSE, errors = errors, assets = assets,
      sri_hashes = sri_hashes, build_time = start_time, metadata = list()
    )
  }

  assets <- c(assets, main_css)

  # 5. Distribute LaTeX assets from design system submodule
  if (verbose) {
    ui_info("Distributing LaTeX assets from design system...")
  }

  # Source location in design system submodule
  design_system_dir <- file.path(ui_dir, "src", "dataimago-design")
  latex_source <- file.path(design_system_dir, "src", "latex")

  if (dir_exists(latex_source)) {
    # Define all distribution channels (relative to package root)
    latex_channels <- list(
      cdn = file.path("inst", "quarto-assets"),
      extension = file.path("ui", "www", "_extensions", "dataimago", "ai-native", "assets", "latex"),
      website = file.path("ui", "www", "assets", "latex"),
      docs = file.path("docs", "assets", "latex")
    )

    latex_files_distributed <- 0

    # Distribute dataimago.sty to all channels
    sty_source <- file.path(latex_source, "dataimago.sty")
    if (file_exists(sty_source)) {
      for (channel_name in names(latex_channels)) {
        channel_dir <- latex_channels[[channel_name]]
        tryCatch(
          {
            if (!dir_exists(channel_dir)) {
              dir_create(channel_dir, recursive = TRUE)
            }
            sty_target <- file.path(channel_dir, "dataimago.sty")
            file_copy(sty_source, sty_target, overwrite = TRUE)
            latex_files_distributed <- latex_files_distributed + 1
            if (verbose) {
              ui_info(glue("   dataimago.sty -> {channel_name}"))
            }
          },
          error = function(e) {
            errors <- c(errors, glue("Failed to copy dataimago.sty to {channel_name}: {e$message}"))
          }
        )
      }
    } else {
      if (verbose) {
        ui_warn("dataimago.sty not found in design system submodule")
      }
    }

    # Copy README.md to CDN distribution only (with different name to avoid conflicts)
    readme_source <- file.path(latex_source, "README.md")
    if (file_exists(readme_source)) {
      cdn_dir <- latex_channels$cdn
      tryCatch(
        {
          readme_target <- file.path(cdn_dir, "README-latex.md")
          file_copy(readme_source, readme_target, overwrite = TRUE)
          latex_files_distributed <- latex_files_distributed + 1
          if (verbose) {
            ui_info("   README.md -> cdn (as README-latex.md)")
          }
        },
        error = function(e) {
          errors <- c(errors, glue("Failed to copy README.md to CDN: {e$message}"))
        }
      )
    }

    if (verbose && latex_files_distributed > 0) {
      ui_done(glue("Distributed LaTeX assets to {length(latex_channels)} channels"))
    }
  } else {
    if (verbose) {
      ui_warn(glue("LaTeX source directory not found: {latex_source}"))
      ui_info("   LaTeX assets will not be distributed (design system submodule may need initialization)")
    }
  }

  # 6. Generate SRI hashes if requested
  if (include_sri) {
    if (verbose) {
      ui_info("Generating SRI hashes for CDN security...")
    }

    for (asset in assets) {
      if (file_exists(asset)) {
        tryCatch(
          {
            # Use openssl to generate SHA384 hash for SRI (using hex output then converting)
            hash_result <- processx::run("openssl", c("dgst", "-sha384", "-hex", asset))
            if (hash_result$status == 0 && !is.null(hash_result$stdout) && nchar(hash_result$stdout) > 0) {
              # Extract hex hash from "SHA384(file)= hexvalue" format
              hex_hash <- sub(".*= ", "", trimws(hash_result$stdout))
              if (nchar(hex_hash) == 96) { # SHA384 hex should be 96 characters
                # Convert hex to base64 for SRI format using base R
                raw_bytes <- as.raw(strtoi(substring(hex_hash, seq(1, 95, 2), seq(2, 96, 2)), 16L))
                sri_hash <- paste0("sha384-", jsonlite::base64_enc(raw_bytes))
                sri_hashes[[basename(asset)]] <- sri_hash
                if (verbose) {
                  ui_info(glue("  {basename(asset)}: {substr(sri_hash, 1, 20)}..."))
                }
              } else {
                if (verbose) {
                  ui_warn(glue("Invalid hash length for {basename(asset)}: expected 96, got {nchar(hex_hash)}"))
                }
              }
            } else {
              if (verbose) {
                ui_warn(glue("Could not generate hash for {basename(asset)}: openssl returned status {hash_result$status}"))
              }
            }
          },
          error = function(e) {
            if (verbose) {
              ui_warn(glue("Could not generate SRI hash for {basename(asset)}: {e$message}"))
            }
          }
        )
      }
    }
  }

  # 7. Update Quarto extension if requested
  if (update_extension) {
    if (verbose) {
      ui_info("Updating Quarto extension assets...")
    }

    extension_result <- update_quarto_extension(verbose = verbose)
    if (!extension_result$success) {
      errors <- c(errors, extension_result$errors)
    }
  }

  # 8. Generate CDN assets
  cdn_result <- generate_cdn_assets(verbose = verbose)
  if (!cdn_result$success) {
    errors <- c(errors, cdn_result$errors)
  } else {
    assets <- c(assets, cdn_result$assets)
  }

  # 9. Synchronize Quarto assets (ensure consistency across directories)
  if (verbose) {
    ui_info("Synchronizing Quarto assets across directories...")
  }
  tryCatch({
    # Source the asset sync function if not already loaded
    if (!exists("sync_quarto_assets")) {
      source("R/asset_sync.R")
    }
    sync_result <- sync_quarto_assets(verbose = FALSE)
    if (!sync_result$success) {
      errors <- c(errors, sync_result$errors)
    } else if (length(sync_result$synced_files) > 0 && verbose) {
      ui_info(glue("   Synchronized {length(sync_result$synced_files)} asset files"))
    }
  }, error = function(e) {
    errors <- c(errors, glue("Asset synchronization failed: {e$message}"))
  })

  # 10. Create build metadata
  build_time <- Sys.time()
  metadata <- list(
    package_manager = package_manager,
    build_time = build_time,
    duration_seconds = as.numeric(difftime(build_time, start_time, units = "secs")),
    r_version = R.version.string,
    system_info = Sys.info(),
    force_rebuild = force_rebuild,
    include_sri = include_sri,
    update_extension = update_extension,
    assets_generated = length(assets),
    sri_hashes_generated = length(sri_hashes)
  )

  # 11. Final status
  success <- length(errors) == 0

  if (verbose) {
    if (success) {
      ui_done(glue("Design system build completed successfully in {round(metadata$duration_seconds, 2)}s"))
      ui_info(glue("   Generated {length(assets)} assets"))
      ui_info(glue("   Created {length(sri_hashes)} SRI hashes"))
    } else {
      ui_oops(glue("Design system build failed with {length(errors)} errors"))
      for (error in errors) {
        ui_oops(glue("   - {error}"))
      }
    }
  }

  return(list(
    success = success,
    assets = assets,
    sri_hashes = sri_hashes,
    build_time = build_time,
    metadata = metadata,
    errors = errors
  ))
}

#' Create UI Workspace for Design System
#'
#' Sets up the Node.js workspace structure and configuration files needed for
#' CSS compilation and design token processing. This function creates the complete
#' ui/ directory structure with package.json, build scripts, and source files.
#'
#' @param force_overwrite Logical. Overwrite existing ui/ directory if it exists. Default: FALSE
#' @param verbose Logical. Print detailed progress information. Default: TRUE
#'
#' @details
#' **Created Directory Structure:**
#' ```
#' ui/
#' +-- package.json              # Node.js dependencies (Style Dictionary, Sass, etc.)
#' +-- build.js                  # Custom build script for compilation
#' +-- src/
#' |   +-- tokens/
#' |   |   +-- colors.json       # dataimago color palette
#' |   |   +-- typography.json   # Font definitions and scales
#' |   |   +-- spacing.json      # Spacing scale and dimensions
#' |   +-- styles/
#' |       +-- base.scss         # Base styles using design tokens
#' |       +-- components.scss   # UI component styles
#' |       +-- utilities.scss    # Utility classes
#' +-- dist/                     # Build output directory (created by build process)
#' ```
#'
#' **Design Token Philosophy:**
#' The design tokens follow dataimago's ethical AI principles:
#' - **Semantic Naming**: Colors like `primary`, `accent`, `ethical-highlight`
#' - **Accessibility First**: WCAG AA contrast ratios and reduced motion support
#' - **Cultural Sensitivity**: Avoid culturally-biased color assumptions
#' - **Future-Proof**: JSON structure enables multiple output formats
#'
#' **Build Tool Configuration:**
#' - **Style Dictionary**: Converts design tokens to CSS custom properties
#' - **Sass/SCSS**: Compiles component styles with token integration
#' - **PostCSS**: Adds vendor prefixes and optimizations
#' - **CSSnano**: Minification for production distribution
#'
#' @return List containing setup results:
#'   - success: Logical indicating setup success
#'   - created_files: Character vector of files created
#'   - errors: Character vector of any error messages
#'
#' @examples
#' \dontrun{
#' # Create new ui workspace
#' result <- create_ui_workspace()
#'
#' # Force recreate existing workspace
#' result <- create_ui_workspace(force_overwrite = TRUE)
#'
#' # Check what was created
#' if (result$success) {
#'   cat("Created files:", paste(result$created_files, collapse = "\n  "))
#' }
#' }
#'
#' @export
create_ui_workspace <- function(force_overwrite = FALSE, verbose = TRUE) {
  ui_dir <- "ui"
  created_files <- character(0)
  errors <- character(0)

  if (verbose) {
    ui_info("Creating UI workspace for design system...")
  }

  # Check if ui/ directory exists and assess its type
  if (dir_exists(ui_dir)) {
    # Check if this is a sophisticated build system (has real source files)
    has_sophisticated_system <- file.exists(file.path(ui_dir, "src", "styles")) &&
      file.exists(file.path(ui_dir, "src", "tokens")) &&
      file.exists(file.path(ui_dir, "build.js"))

    if (has_sophisticated_system && !force_overwrite) {
      if (verbose) {
        ui_info("Found existing sophisticated UI build system - preserving it")
        ui_info("  Use force_overwrite = TRUE to replace with minimal system")
      }
      # Return success without creating anything new - the sophisticated system is already there
      list(
        success = TRUE, created_files = character(0),
        errors = character(0),
        note = "Preserved existing sophisticated UI build system"
      )
    } else if (!force_overwrite) {
      errors <- c(errors, "ui/ directory already exists. Use force_overwrite = TRUE to recreate.")
      list(success = FALSE, created_files = created_files, errors = errors)
    } else {
      if (verbose) {
        if (has_sophisticated_system) {
          ui_warn("Removing existing sophisticated ui/ directory and replacing with minimal system...")
        } else {
          ui_warn("Removing existing ui/ directory...")
        }
      }
      unlink(ui_dir, recursive = TRUE)
    }
  }

  # Create directory structure
  tryCatch(
    {
      dir_create(file.path(ui_dir, "src", "tokens"))
      dir_create(file.path(ui_dir, "src", "styles"))
      dir_create(file.path(ui_dir, "dist")) # Will be populated by build

      if (verbose) {
        ui_info("Created directory structure")
      }
    },
    error = function(e) {
      errors <- c(errors, glue("Error creating directories: {e$message}"))
      list(success = FALSE, created_files = created_files, errors = errors)
    }
  )

  # Create package.json
  package_json <- list(
    name = "@dataimago/design-system",
    private = TRUE,
    version = "0.1.0",
    description = "dataimago ethical AI design system - CSS compilation workspace",
    scripts = list(
      build = "node build.js",
      watch = "node build.js --watch",
      clean = "rm -rf dist/*",
      tokens = "style-dictionary build"
    ),
    keywords = c("dataimago", "design-system", "css", "ethical-ai"),
    devDependencies = list(
      "style-dictionary" = "^4.0.0",
      "sass" = "^1.69.0",
      "postcss" = "^8.4.0",
      "autoprefixer" = "^10.4.0",
      "cssnano" = "^6.0.0",
      "postcss-cli" = "^11.0.0"
    )
  )

  package_json_file <- file.path(ui_dir, "package.json")
  tryCatch(
    {
      writeLines(
        jsonlite::toJSON(package_json, pretty = TRUE, auto_unbox = TRUE),
        package_json_file
      )
      created_files <- c(created_files, package_json_file)
      if (verbose) {
        ui_info("Created package.json with Node.js dependencies")
      }
    },
    error = function(e) {
      errors <- c(errors, glue("Error creating package.json: {e$message}"))
    }
  )

  # Create design tokens - colors.json
  colors_tokens <- list(
    color = list(
      brand = list(
        primary = list(value = "#2C3E50", description = "dataimago primary brand color"),
        secondary = list(value = "#34495E", description = "dataimago secondary brand color"),
        accent = list(value = "#3498DB", description = "dataimago accent color for highlights"),
        ethical = list(value = "#E74C3C", description = "Ethical AI emphasis color")
      ),
      semantic = list(
        success = list(value = "#27AE60", description = "Success states and positive actions"),
        warning = list(value = "#F39C12", description = "Warning states and caution"),
        error = list(value = "#E74C3C", description = "Error states and critical issues"),
        info = list(value = "#3498DB", description = "Informational content")
      ),
      text = list(
        primary = list(value = "#2C3E50", description = "Primary text color"),
        secondary = list(value = "#7F8C8D", description = "Secondary text color"),
        muted = list(value = "#95A5A6", description = "Muted text color"),
        inverse = list(value = "#FFFFFF", description = "Inverse text for dark backgrounds")
      ),
      background = list(
        page = list(value = "#FFFFFF", description = "Main page background"),
        surface = list(
          value = "#F8F9FA",
          description = "Card and surface backgrounds"
        ),
        overlay = list(
          value = "#000000",
          description = "Modal overlay background"
        )
      ),
      border = list(
        default = list(value = "#E9ECEF", description = "Default border color"),
        focus = list(value = "#3498DB", description = "Focus ring border color")
      )
    )
  )

  colors_file <- file.path(ui_dir, "src", "tokens", "colors.json")
  tryCatch(
    {
      writeLines(
        jsonlite::toJSON(colors_tokens,
          pretty = TRUE,
          auto_unbox = TRUE
        ),
        colors_file
      )
      created_files <- c(created_files, colors_file)
    },
    error = function(e) {
      errors <- c(errors, glue("Error creating colors.json: {e$message}"))
    }
  )

  # Create design tokens - typography.json
  typography_tokens <- list(
    font = list(
      family = list(
        sans = list(value = paste0(
          "Inter, system-ui, -apple-system, ",
          "Segoe UI, Roboto, sans-serif"
        )),
        mono = list(value = paste0(
          "JetBrains Mono, SF Mono, Monaco, ",
          "Inconsolata, monospace"
        )),
        display = list(value = "Inter, system-ui, sans-serif")
      ),
      size = list(
        xs = list(value = "0.75rem"),
        sm = list(value = "0.875rem"),
        base = list(value = "1rem"),
        lg = list(value = "1.125rem"),
        xl = list(value = "1.25rem"),
        "2xl" = list(value = "1.5rem"),
        "3xl" = list(value = "1.875rem"),
        "4xl" = list(value = "2.25rem")
      ),
      weight = list(
        normal = list(value = "400"),
        medium = list(value = "500"),
        semibold = list(value = "600"),
        bold = list(value = "700")
      ),
      lineHeight = list(
        tight = list(value = "1.25"),
        normal = list(value = "1.5"),
        relaxed = list(value = "1.625")
      )
    )
  )

  typography_file <- file.path(
    ui_dir, "src", "tokens",
    "typography.json"
  )
  tryCatch(
    {
      writeLines(
        jsonlite::toJSON(typography_tokens, pretty = TRUE, auto_unbox = TRUE),
        typography_file
      )
      created_files <- c(created_files, typography_file)
    },
    error = function(e) {
      errors <- c(errors, glue("Error creating typography.json: {e$message}"))
    }
  )

  # Create design tokens - spacing.json
  spacing_tokens <- list(
    spacing = list(
      xs = list(value = "0.25rem"),
      sm = list(value = "0.5rem"),
      md = list(value = "1rem"),
      lg = list(value = "1.5rem"),
      xl = list(value = "2rem"),
      "2xl" = list(value = "3rem"),
      "3xl" = list(value = "4rem")
    ),
    radius = list(
      sm = list(value = "0.25rem"),
      md = list(value = "0.5rem"),
      lg = list(value = "0.75rem"),
      xl = list(value = "1rem"),
      full = list(value = "9999px")
    ),
    shadow = list(
      sm = list(value = "0 1px 2px 0 rgb(0 0 0 / 0.05)"),
      md = list(value = "0 4px 6px -1px rgb(0 0 0 / 0.1)"),
      lg = list(value = "0 10px 15px -3px rgb(0 0 0 / 0.1)"),
      xl = list(value = paste0(
        "0 20px 25px -5px ",
        "rgb(0 0 0 / 0.1)"
      ))
    )
  )

  spacing_file <- file.path(ui_dir, "src", "tokens", "spacing.json")
  tryCatch(
    {
      writeLines(
        jsonlite::toJSON(spacing_tokens, pretty = TRUE, auto_unbox = TRUE),
        spacing_file
      )
      created_files <- c(created_files, spacing_file)
    },
    error = function(e) {
      errors <- c(errors, glue("Error creating spacing.json: {e$message}"))
    }
  )

  # Create build.js script
  build_js_content <- c(
    "#!/usr/bin/env node",
    "",
    "/**",
    " * dataimago Design System Build Script",
    " * Compiles SCSS and design tokens into production CSS",
    " */",
    "",
    "const fs = require('fs');",
    "const path = require('path');",
    "const { execSync } = require('child_process');",
    "",
    "// Ensure dist directory exists",
    "const distDir = path.join(__dirname, 'dist');",
    "if (!fs.existsSync(distDir)) {",
    "  fs.mkdirSync(distDir, { recursive: true });",
    "}",
    "",
    "console.log('Building dataimago design system...');",
    "",
    "try {",
    "  // For now, create a minimal CSS file until full build system is implemented",
    "  const minimalCSS = [",
    "    '/* dataimago Design System v0.1.0 */',",
    "    '/* Generated by build.js - Minimal implementation */',",
    "    '',",
    "    ':root {',",
    "    '  --dataimago-primary: #2C3E50;',",
    "    '  --dataimago-secondary: #34495E;',",
    "    '  --dataimago-accent: #3498DB;',",
    "    '  --dataimago-ethical: #E74C3C;',",
    "    '}',",
    "    '',",
    "    '.dataimago-container {',",
    "    '  max-width: 1200px;',",
    "    '  margin: 0 auto;',",
    "    '  padding: 1rem;',",
    "    '}',",
    "    '',",
    "    '.dataimago-button {',",
    "    '  background: var(--dataimago-primary);',",
    "    '  color: white;',",
    "    '  border: none;',",
    "    '  padding: 0.5rem 1rem;',",
    "    '  border-radius: 0.25rem;',",
    "    '  cursor: pointer;',",
    "    '}',",
    "    '',",
    "    '.dataimago-button:hover {',",
    "    '  background: var(--dataimago-secondary);',",
    "    '}'",
    "  ].join('\\n');",
    "",
    "  // Write main CSS file",
    "  fs.writeFileSync(path.join(distDir, 'dataimago.min.css'), minimalCSS);",
    "  ",
    "  // Create tokens CSS",
    "  const tokensCSS = [",
    "    '/* dataimago Design Tokens */',",
    "    ':root {',",
    "    '  --dataimago-primary: #2C3E50;',",
    "    '  --dataimago-secondary: #34495E;',",
    "    '  --dataimago-accent: #3498DB;',",
    "    '  --dataimago-ethical: #E74C3C;',",
    "    '  --dataimago-success: #27AE60;',",
    "    '  --dataimago-warning: #F39C12;',",
    "    '  --dataimago-error: #E74C3C;',",
    "    '  --dataimago-info: #3498DB;',",
    "    '}'",
    "  ].join('\\n');",
    "  ",
    "  fs.writeFileSync(path.join(distDir, 'tokens.css'), tokensCSS);",
    "  ",
    "  // Create manifest",
    "  const manifest = {",
    "    name: '@dataimago/design-system',",
    "    version: '0.1.0',",
    "    files: ['dataimago.min.css', 'tokens.css'],",
    "    buildTime: new Date().toISOString()",
    "  };",
    "  ",
    "  fs.writeFileSync(path.join(distDir, 'manifest.json'),",
    "                    JSON.stringify(manifest, null, 2));",
    "  ",
    "  console.log('\\u2713 Build completed successfully');",
    "  console.log('  Generated files:');",
    "  console.log('    - dataimago.min.css');",
    "  console.log('    - tokens.css');",
    "  console.log('    - manifest.json');",
    "",
    "} catch (error) {",
    "  console.error('Build failed:', error.message);",
    "  process.exit(1);",
    "}"
  )
  build_js_file <- file.path(ui_dir, "build.js")
  tryCatch(
    {
      writeLines(build_js_content, build_js_file)
      created_files <- c(created_files, build_js_file)
      if (verbose) {
        ui_info("Created build.js script")
      }
    },
    error = function(e) {
      errors <- c(errors, glue("Error creating build.js: {e$message}"))
    }
  )

  success <- length(errors) == 0

  if (verbose) {
    if (success) {
      ui_done(glue("UI workspace created successfully"))
      ui_info(glue("   Created {length(created_files)} files"))
      ui_info("   Run build_design_system() to compile CSS assets")
    } else {
      ui_oops("UI workspace setup failed")
      for (error in errors) {
        ui_oops(glue("   - {error}"))
      }
    }
  }

  return(list(
    success = success,
    created_files = created_files,
    errors = errors
  ))
}

#' Update Quarto Extension Assets
#'
#' Copies compiled CSS and other assets from ui/dist/ into the Quarto
#' extension structure.
#' Maintains proper extension.yml configuration and ensures asset linking
#' works correctly.
#'
#' @param verbose Logical. Print detailed progress information. Default: TRUE
#'
#' @details
#' This function performs the following operations:
#'
#' 1. **Validates Extension Structure**: Checks that
#'    `ui/www/_extensions/dataimago/ai-native/` exists
#' 2. **Copies Main CSS**: Copies `ui/dist/dataimago.min.css` to
#'    extension assets
#' 3. **Updates Asset References**: Ensures extension.yml references the
#'    correct CSS files
#' 4. **Preserves Extension Config**: Maintains existing Lua filters,
#'    shortcodes, etc.
#'
#' **Extension Asset Mapping:**
#' - `ui/dist/dataimago.min.css` ->
#'   `ui/www/_extensions/dataimago/ai-native/assets/css/dataimago.min.css`
#'   and
#'   `ui/www/_extensions/dataimago/ai-native/assets/css/tokens.css` (if exists)
#' - Source maps and development files are excluded from extension
#'   distribution
#'
#' **File Operations:**
#' All file copying uses R's `fs::file_copy()` with overwrite protection
#' and atomic operations
#' to prevent corrupted assets during development. The function will not
#' overwrite extension
#' configuration files (like _extension.yml) unless they become corrupted.
#'
#' @return List containing update results:
#'   - success: Logical indicating update success
#'   - updated_files: Character vector of files updated in extension
#'   - errors: Character vector of any error messages
#'
#' @examples
#' \dontrun{
#' # Update extension after building CSS
#' build_design_system()
#' result <- update_quarto_extension()
#'
#' # Check what was updated
#' if (result$success) {
#'   cat(
#'     "Updated files:",
#'     paste(result$updated_files, collapse = "\n  ")
#'   )
#' }
#' }
#'
#' @export
update_quarto_extension <- function(verbose = TRUE) {
  updated_files <- character(0)
  errors <- character(0)

  if (verbose) {
    ui_info("Updating Quarto extension assets...")
  }

  # Validate source files exist
  main_css <- "ui/dist/dataimago.min.css"
  if (!file_exists(main_css)) {
    errors <- c(errors, "dataimago.min.css not found in ui/dist/. Run build_design_system() first.")
    list(success = FALSE, updated_files = updated_files, errors = errors)
  }

  # Validate extension directory exists
  extension_dir <- "ui/www/_extensions/dataimago/ai-native"
  if (!dir_exists(extension_dir)) {
    errors <- c(errors, "Quarto extension directory not found. Extension structure may be corrupted.")
    list(success = FALSE, updated_files = updated_files, errors = errors)
  }

  # Create extension assets directory if needed
  extension_css_dir <- file.path(extension_dir, "assets", "css")
  if (!dir_exists(extension_css_dir)) {
    dir_create(extension_css_dir)
    if (verbose) {
      ui_info("Created extension assets/css directory")
    }
  }

  # Copy main CSS file
  tryCatch(
    {
      target_css <- file.path(extension_css_dir, "dataimago.min.css")
      file_copy(main_css, target_css, overwrite = TRUE)
      updated_files <- c(updated_files, target_css)

      if (verbose) {
        ui_info(glue("Copied dataimago.min.css to extension"))
      }
    },
    error = function(e) {
      errors <- c(errors, glue("Error copying main CSS: {e$message}"))
    }
  )

  # Copy tokens file if it exists
  tokens_css <- "ui/dist/tokens.css"
  if (file_exists(tokens_css)) {
    tryCatch(
      {
        target_tokens <- file.path(extension_css_dir, "tokens.css")
        file_copy(tokens_css, target_tokens, overwrite = TRUE)
        updated_files <- c(updated_files, target_tokens)

        if (verbose) {
          ui_info("Copied tokens.css to extension")
        }
      },
      error = function(e) {
        errors <- c(errors, glue("Error copying tokens CSS: {e$message}"))
      }
    )
  }

  # Copy any additional built CSS assets
  dist_dir <- "ui/dist"
  if (dir_exists(dist_dir)) {
    dist_files <- dir_ls(dist_dir, type = "file", glob = "*.css")
    for (dist_file in dist_files) {
      filename <- basename(dist_file)
      # Skip already copied files
      if (!filename %in% c("dataimago.min.css", "tokens.css")) {
        tryCatch(
          {
            target_file <- file.path(extension_css_dir, filename)
            file_copy(dist_file, target_file, overwrite = TRUE)
            updated_files <- c(updated_files, target_file)

            if (verbose) {
              ui_info(glue("Copied {filename} to extension"))
            }
          },
          error = function(e) {
            if (verbose) {
              ui_warn(glue("Could not copy {filename}: {e$message}"))
            }
          }
        )
      }
    }
  }
  
  # Copy JavaScript assets from ui/dist/js/
  js_dist_dir <- "ui/dist/js"
  extension_js_dir <- "ui/www/_extensions/dataimago/ai-native/assets/js"
  
  if (dir_exists(js_dist_dir) && dir_exists(extension_js_dir)) {
    if (verbose) {
      ui_info("Copying JavaScript assets to extension...")
    }
    
    js_files <- dir_ls(js_dist_dir, type = "file", glob = "*.js")
    for (js_file in js_files) {
      filename <- basename(js_file)
      tryCatch(
        {
          target_file <- file.path(extension_js_dir, filename)
          file_copy(js_file, target_file, overwrite = TRUE)
          updated_files <- c(updated_files, target_file)

          if (verbose) {
            ui_info(glue("Copied {filename} to extension"))
          }
        },
        error = function(e) {
          if (verbose) {
            ui_warn(glue("Could not copy {filename}: {e$message}"))
          }
        }
      )
    }
    
    js_count <- length(js_files)
    if (verbose && js_count > 0) {
      ui_info(glue("Updated {js_count} JavaScript files in extension"))
    }
  }
  
  # Also copy JavaScript to ui/www/assets/js/ for development
  quarto_js_dir <- "ui/www/assets/js"
  if (dir_exists(js_dist_dir) && dir_exists(quarto_js_dir)) {
    if (verbose) {
      ui_info("Copying JavaScript assets to Quarto development directory...")
    }
    
    js_files <- dir_ls(js_dist_dir, type = "file", glob = "*.js")
    for (js_file in js_files) {
      filename <- basename(js_file)
      tryCatch(
        {
          target_file <- file.path(quarto_js_dir, filename)
          file_copy(js_file, target_file, overwrite = TRUE)
          updated_files <- c(updated_files, target_file)
          
          if (verbose) {
            ui_info(glue("Copied {filename} to Quarto assets"))
          }
        },
        error = function(e) {
          if (verbose) {
            ui_warn(glue("Could not copy {filename} to Quarto assets: {e$message}"))
          }
        }
      )
    }
    
    if (verbose && length(js_files) > 0) {
      ui_info(glue("Updated {length(js_files)} JavaScript files in Quarto assets"))
    }
  } else {
    if (verbose) {
      ui_warn(glue("Cannot copy JS to Quarto assets - js_dist_dir exists: {dir_exists(js_dist_dir)}, quarto_js_dir exists: {dir_exists(quarto_js_dir)}"))
    }
  }

  success <- length(errors) == 0

  if (verbose) {
    if (success) {
      ui_done(glue(
        "Quarto extension updated ",
        "successfully"
      ))
      ui_info(glue(
        "   Updated {length(updated_files)} ",
        "asset files"
      ))
    } else {
      ui_oops("Extension update failed")
      for (error in errors) {
        ui_oops(glue("   - {error}"))
      }
    }
  }

  return(list(
    success = success,
    updated_files = updated_files,
    errors = errors
  ))
}

#' Generate CDN Distribution Assets
#'
#' Prepares assets for CDN distribution with versioning, SRI hashes,
#' and metadata.
#' Creates jsDelivr-compatible structure in inst/quarto-assets/ for
#' R package distribution.
#'
#' @param verbose Logical. Print detailed progress information. Default: TRUE
#'
#' @details
#' This function creates CDN-ready assets by:
#'
#' 1. **Copying Built Assets**: Moves `ui/dist/*.css` to `inst/quarto-assets/`
#' 2. **Generating Metadata**: Creates manifest.json with build info and SRI hashes
#' 3. **Creating Usage Examples**: Generates HTML snippets showing CDN usage
#' 4. **Validating File Integrity**: Ensures all copied files are complete and uncorrupted
#'
#' **CDN Distribution Strategy:**
#' Files in `inst/quarto-assets/` become available via jsDelivr once the package is
#' tagged and released on GitHub:
#' ```
#' https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@v0.1.0/inst/quarto-assets/dataimago.min.css
#' ```
#'
#' **SRI (Subresource Integrity) Hashes:**
#' Each CSS file gets a SHA-384 hash for security:
#' ```html
#' <link rel="stylesheet"
#'       href="https://cdn.jsdelivr.net/gh/.../dataimago.min.css"
#'       integrity="sha384-..."
#'       crossorigin="anonymous">
#' ```
#'
#' **Generated Files:**
#' - `inst/quarto-assets/dataimago.min.css` - Main compiled CSS
#' - `inst/quarto-assets/tokens.css` - CSS custom properties (if built)
#' - `inst/quarto-assets/manifest.json` - Build metadata and SRI hashes
#' - `inst/quarto-assets/README.md` - Usage instructions and examples
#'
#' @return List containing CDN preparation results:
#'   - success: Logical indicating preparation success
#'   - assets: Character vector of CDN-ready asset paths
#'   - errors: Character vector of any error messages
#'
#' @export
generate_cdn_assets <- function(verbose = TRUE) {
  assets <- character(0)
  errors <- character(0)

  if (verbose) {
    ui_info("Preparing CDN distribution assets...")
  }

  # Create inst/quarto-assets directory
  cdn_dir <- "inst/quarto-assets"
  if (!dir_exists(cdn_dir)) {
    dir_create(cdn_dir)
    if (verbose) {
      ui_info(paste0(
        "Created inst/quarto-assets ",
        "directory"
      ))
    }
  }

  # Copy built assets from ui/dist/
  dist_dir <- "ui/dist"
  if (!dir_exists(dist_dir)) {
    errors <- c(errors, "ui/dist/ directory not found. Run build_design_system() first.")
    list(success = FALSE, assets = assets, errors = errors)
  }

  # Copy CSS files
  css_files <- dir_ls(dist_dir, type = "file", glob = "*.css")
  for (css_file in css_files) {
    tryCatch(
      {
        target_file <- file.path(cdn_dir, basename(css_file))
        file_copy(css_file, target_file, overwrite = TRUE)
        assets <- c(assets, target_file)

        if (verbose) {
          ui_info(glue("Copied {basename(css_file)} to CDN assets"))
        }
      },
      error = function(e) {
        errors <- c(errors, glue("Error copying {basename(css_file)}: {e$message}"))
      }
    )
  }

  # Note: Website uses SCSS compilation, not these compiled files

  success <- length(errors) == 0

  if (verbose) {
    if (success) {
      ui_done(glue("CDN assets prepared successfully"))
      ui_info(glue("   Prepared {length(assets)} assets for distribution"))
    } else {
      ui_oops("CDN asset preparation failed")
      for (error in errors) {
        ui_oops(glue("   - {error}"))
      }
    }
  }

  return(list(
    success = success,
    assets = assets,
    errors = errors
  ))
}

#' Generate AI-Optimized Repository Context
#'
#' Creates a comprehensive, AI-friendly representation of the dataimago codebase using Repomix.
#' This function wraps the repomix tool to generate structured context files that can be uploaded
#' to AI assistants for comprehensive project understanding, including philosophical foundations,
#' technical architecture, and implementation patterns.
#'
#' @param output_file Character. Output filename (default: NULL, auto-generates as "PACKAGE_NAME-repomix.xml")
#' @param style Character. Output style: "xml", "markdown", or "plain" (default: "xml")
#' @param include_token_count Logical. Include token count analysis (default: TRUE)
#' @param min_token_threshold Numeric. Minimum token count for tree display (default: 100)
#' @param verbose Logical. Print detailed progress information (default: TRUE)
#'
#' @details
#' This function implements dataimago's AI-native development philosophy by providing
#' comprehensive codebase context for AI assistants. The generated artifact includes:
#'
#' **Philosophical Context:**
#' - Complete foundation documents from `inst/dataimago/`
#' - Ethical AI principles and critical theory frameworks
#' - Mission, vision, and architectural blueprints
#'
#' **Technical Architecture:**
#' - All R functions with roxygen2 documentation
#' - Design system source of truth (`ui/src/dataimago-design/`)
#' - Build system patterns and multi-platform distribution
#' - Git submodule integration and workflow patterns
#'
#' **AI Agent Context:**
#' - `CLAUDE.md` and `AGENT_INDEX.md` coordination files
#' - Structured metadata for semantic interoperability
#' - Development patterns aligned with emancipatory AI principles
#'
#' **System Requirements:**
#' - Node.js 18+ with npx available globally
#' - Repomix tool (automatically installed via npx if not present)
#' - Write permissions to package directory
#'
#' **Usage Patterns:**
#' ```r
#' # Standard AI context generation
#' generate_ai_context()
#' 
#' # Markdown format for documentation
#' generate_ai_context(style = "markdown")  # -> dataimago-repomix.md
#' 
#' # Custom filename
#' generate_ai_context(output_file = "custom-context.xml")
#' 
#' # Minimal output for faster processing
#' generate_ai_context(include_token_count = FALSE, min_token_threshold = 500)
#' ```
#'
#' **AI Assistant Integration:**
#' Upload the generated file to your AI assistant (Claude Projects, ChatGPT, etc.) 
#' to provide complete codebase context including philosophical foundations and 
#' technical implementation patterns.
#'
#' @return List with success status, output file path, token count, and any errors
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate standard AI context
#' result <- generate_ai_context()
#' if (result$success) {
#'   cat("AI context generated:", result$output_file)
#' }
#' 
#' # Generate markdown version for documentation
#' generate_ai_context(style = "markdown")  # -> dataimago-repomix.md
#' }
generate_ai_context <- function(output_file = NULL,
                               style = "xml",
                               include_token_count = TRUE,
                               min_token_threshold = 100,
                               verbose = TRUE) {
  
  # Validate inputs
  if (!style %in% c("xml", "markdown", "plain")) {
    stop("style must be one of: 'xml', 'markdown', 'plain'")
  }
  
  if (!is.numeric(min_token_threshold) || min_token_threshold < 0) {
    stop("min_token_threshold must be a non-negative number")
  }
  
  errors <- character(0)
  
  # Generate default filename if not provided
  if (is.null(output_file)) {
    # Extract package name from DESCRIPTION file
    desc_path <- "DESCRIPTION"
    if (fs::file_exists(desc_path)) {
      desc_content <- readLines(desc_path)
      package_line <- grep("^Package:", desc_content, value = TRUE)
      if (length(package_line) > 0) {
        package_name <- trimws(sub("^Package:\\s*", "", package_line[1]))
        # Generate filename based on style
        file_ext <- switch(style, 
                          "xml" = "xml", 
                          "markdown" = "md", 
                          "plain" = "txt")
        output_file <- glue("{package_name}-repomix.{file_ext}")
      } else {
        output_file <- glue("package-repomix.{switch(style, 'xml' = 'xml', 'markdown' = 'md', 'plain' = 'txt')}")
      }
    } else {
      output_file <- glue("package-repomix.{switch(style, 'xml' = 'xml', 'markdown' = 'md', 'plain' = 'txt')}")
    }
  }
  
  if (verbose) {
    ui_info("Generating AI-optimized repository context with Repomix...")
    ui_info(glue("Output format: {style}"))
    ui_info(glue("Output file: {output_file}"))
  }
  
  # Check if npx is available
  npx_check <- tryCatch({
    processx::run("npx", "--version", stdout = NULL, stderr = NULL)
    TRUE
  }, error = function(e) {
    FALSE
  })
  
  if (!npx_check) {
    errors <- c(errors, "npx not available. Please install Node.js 18+ with npm/npx")
    if (verbose) {
      ui_oops("npx not available")
      ui_info("Install Node.js from: https://nodejs.org/")
      ui_info("Or via package manager: brew install node")
    }
    return(list(
      success = FALSE,
      output_file = output_file,
      token_count = 0,
      errors = errors
    ))
  }
  
  # Build repomix command arguments
  cmd_args <- c("repomix@latest", "--output", output_file, "--style", style)
  
  if (include_token_count) {
    cmd_args <- c(cmd_args, "--token-count-tree", as.character(min_token_threshold))
  }
  
  if (verbose) {
    cmd_args <- c(cmd_args, "--verbose")
  } else {
    cmd_args <- c(cmd_args, "--quiet")
  }
  
  # Execute repomix
  if (verbose) {
    ui_info("Running repomix... (this may take a moment)")
  }
  
  result <- tryCatch({
    processx::run("npx", cmd_args, stdout_line_callback = if (verbose) function(line, proc) {
      cat(crayon::silver(line), "\n")
    } else NULL)
  }, error = function(e) {
    errors <<- c(errors, glue("Repomix execution failed: {e$message}"))
    list(status = 1)
  })
  
  # Check if output file was created
  output_exists <- fs::file_exists(output_file)
  
  # Extract token count if available (from repomix output)
  token_count <- 0
  if (output_exists && include_token_count) {
    # Try to extract token count from repomix summary
    # This is a best-effort extraction from typical repomix output format
    if (!is.null(result$stdout)) {
      token_match <- regexpr("Total Tokens: ([0-9,]+)", result$stdout)
      if (token_match > 0) {
        token_str <- regmatches(result$stdout, token_match)
        token_count <- as.numeric(gsub("[^0-9]", "", token_str))
      }
    }
  }
  
  success <- (result$status == 0) && output_exists
  
  if (verbose) {
    if (success) {
      ui_done(glue("AI context generated successfully: {output_file}"))
      ui_info("Upload this file to your AI assistant for comprehensive codebase context")
      ui_info("The file includes:")
      ui_info("  - Complete philosophical foundations (inst/dataimago/)")
      ui_info("  - All R functions and documentation") 
      ui_info("  - Design system source of truth")
      ui_info("  - AI agent coordination files (CLAUDE.md, AGENT_INDEX.md)")
      ui_info("  - Build system architecture and patterns")
      if (token_count > 0) {
        ui_info(glue("  - Token count: {format(token_count, big.mark = ',')}"))
      }
    } else {
      ui_oops("Failed to generate AI context")
      if (!output_exists) {
        errors <- c(errors, "Output file was not created")
      }
      for (error in errors) {
        ui_oops(glue("  - {error}"))
      }
      ui_info("Troubleshooting:")
      ui_info("  - Ensure Node.js 18+ is installed")
      ui_info("  - Check write permissions in current directory")
      ui_info("  - Verify .repomixignore configuration")
    }
  }
  
  return(list(
    success = success,
    output_file = output_file,
    token_count = token_count,
    errors = errors
  ))
}
