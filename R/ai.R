#' @importFrom fs dir_exists dir_create path file_exists
#' @importFrom processx run
#' @importFrom rlang arg_match
#' @importFrom glue glue
#' @importFrom crayon green silver yellow red bold blue
NULL

#' Create Complete AI-Native Application
#'
#' The dataimago meta-orchestration function that creates production-ready
#' AI-native web applications with a single command. Embodies the dataimago
#' philosophy of "R as source of truth" for modern web development.
#'
#' When a source R package is provided, executes the full meta-tool pipeline:
#' R functions → REST API → MCP tools → TypeScript types → Web Application.
#' The generated application inherits dataimago's ethical constraints structurally.
#'
#' @param project_name Character. Name of the project/application to create
#' @param project_path Character. Path where project should be created. Default: getwd()
#' @param source_pkg Character. Path to the source R package whose exported
#'   functions should drive the generated application. This is the "R as Source
#'   of Truth" — all APIs, MCP tools, types, and UI derive from this package.
#'   If NULL, creates scaffolding without the derivation pipeline.
#' @param mode Character. Generation mode: "local" runs the full pipeline locally,
#'   "remote" delegates to the dataimago-ai platform API. Default: "local"
#' @param api_url Character. URL of the dataimago-ai orchestration API.
#'   Default: "https://dataimago.ai/api/orchestrate"
#' @param api_key Character. API key for remote mode. If NULL, reads from
#'   the DATAIMAGO_API_KEY environment variable.
#' @param domain_type Character. Domain type: "research", "explorer", or "framework".
#'   Default: "research"
#' @param domain_name Character. Human-readable domain name. Default: project_name
#' @param framework Character. Target framework: "quarto", "shiny", "nextjs", or "full". Default: "quarto"
#' @param features Character vector. AI features to include:
#'   - "chat-interface": Conversational AI components
#'   - "document-analysis": Document processing and analysis
#'   - "data-viz": Interactive data visualization
#'   - "streaming": Real-time streaming interfaces
#'   - "model-management": AI model selection and management
#' @param theme Character. Visual theme: "professional", "academic", "minimal", "ethical". Default: "professional"
#' @param ai_providers Character vector. AI service integrations:
#'   - "openai": OpenAI GPT integration
#'   - "anthropic": Claude integration
#'   - "local": Local LLM support
#'   - "custom": Custom API endpoints
#' @param ethical_framework Logical. Include dataimago ethical AI guidelines. Default: TRUE
#' @param foundation_docs Logical. Include philosophical foundation documents. Default: TRUE
#' @param export_static Logical. Pre-compute API responses as static JSON for
#'   serverless deployment. Only applies when source_pkg is provided. Default: TRUE
#' @param force_overwrite Logical. Overwrite existing project directory. Default: FALSE
#' @param verbose Logical. Print detailed progress information. Default: TRUE
#'
#' @return List with project metadata, file paths, and build information
#'
#' @details
#' The ai() function implements dataimago's complete application generation pipeline:
#'
#' **Meta-Tool Pipeline (when source_pkg provided):**
#' 1. `build_design_framework()` - Creates directory structure, configs, workflows
#' 2. `build_design_components()` - Generates API, MCP tools, types from R package
#' 3. `build_design_system()` - Compiles design assets
#' 4. `export_static_api()` - Pre-computes JSON for serverless deployment
#'
#' **Scaffold Pipeline (when source_pkg is NULL):**
#' 1. `build_design_framework()` - Creates directory structure, configs, workflows
#' 2. `build_design_components()` - Populates with templates and documentation
#' 3. `build_design_system()` - Compiles design assets
#'
#' **Ethical AI Integration:**
#' Every generated application includes dataimago's ethical AI principles embedded
#' at the code, design, and architectural level. Ethical constraints propagate
#' structurally from dataimago-design through the build pipeline.
#'
#' **System Requirements:**
#' - R 4.0+
#' - Node.js 18+ with pnpm installed globally
#' - Git (for repository initialization)
#' - Write permissions to target directory
#'
#' @examples
#' \dontrun{
#' # Full meta-tool pipeline from an R package
#' ai("my-analysis-app",
#'    source_pkg = "path/to/my-rpkg",
#'    framework = "nextjs")
#'
#' # Minimal Quarto website with chat interface
#' ai("my-research-site",
#'    framework = "quarto",
#'    features = "chat-interface")
#'
#' # Full-featured AI application
#' ai("intelligent-dashboard",
#'    framework = "full",
#'    source_pkg = "path/to/rpkg",
#'    features = c("chat-interface", "data-viz", "streaming"),
#'    ai_providers = c("openai", "anthropic"),
#'    theme = "professional")
#' }
#'
#' @export
ai <- function(project_name,
               project_path = getwd(),
               source_pkg = NULL,
               mode = c("local", "remote"),
               api_url = "https://dataimago.ai/api/orchestrate",
               api_key = NULL,
               domain_type = c("research", "explorer", "framework"),
               domain_name = project_name,
               framework = c("quarto", "shiny", "nextjs", "full"),
               features = NULL,
               theme = c("professional", "academic", "minimal", "ethical"),
               ai_providers = NULL,
               ethical_framework = TRUE,
               foundation_docs = TRUE,
               export_static = TRUE,
               force_overwrite = FALSE,
               verbose = TRUE) {

  # Validate arguments
  mode <- rlang::arg_match(mode)
  domain_type <- rlang::arg_match(domain_type)
  framework <- rlang::arg_match(framework)
  theme <- rlang::arg_match(theme)

  # Validate project name
  if (missing(project_name) || is.null(project_name) || project_name == "") {
    stop("project_name is required and cannot be empty", call. = FALSE)
  }

  # Create full project path
  full_project_path <- fs::path(project_path, project_name)

  # Check if project already exists
  if (fs::dir_exists(full_project_path) && !force_overwrite) {
    stop(glue::glue("Project directory '{full_project_path}' already exists. Use force_overwrite = TRUE to overwrite."),
         call. = FALSE)
  }

  if (verbose) {
    ui_info(glue::glue("\\U0001F3AF Creating AI-native application: {crayon::bold(project_name)}"))
    ui_info(glue::glue("\\U0001F4C1 Location: {full_project_path}"))
    ui_info(glue::glue("\\U0001F504 Mode: {mode}"))
    ui_info(glue::glue("\\U0001F3D7\\uFE0F Framework: {framework}"))
    ui_info(glue::glue("\\U0001F3A8 Theme: {theme}"))
    if (!is.null(source_pkg)) {
      ui_info(glue::glue("\\U0001F4E6 Source R package: {source_pkg}"))
    }
    if (!is.null(features)) {
      ui_info(glue::glue("\\u26A1 Features: {paste(features, collapse = ', ')}"))
    }
    if (!is.null(ai_providers)) {
      ui_info(glue::glue("\\U0001F916 AI Providers: {paste(ai_providers, collapse = ', ')}"))
    }
  }

  # ---- REMOTE MODE: delegate to dataimago-ai platform API ----
  if (mode == "remote") {
    return(ai_remote(
      project_name = project_name,
      full_project_path = full_project_path,
      source_pkg = source_pkg,
      api_url = api_url,
      api_key = api_key,
      domain_type = domain_type,
      domain_name = domain_name,
      force_overwrite = force_overwrite,
      verbose = verbose
    ))
  }
  
  # Initialize results list
  results <- list(
    project_name = project_name,
    project_path = full_project_path,
    source_pkg = source_pkg,
    framework = framework,
    theme = theme,
    features = features,
    ai_providers = ai_providers,
    ethical_framework = ethical_framework,
    foundation_docs = foundation_docs,
    timestamp = Sys.time(),
    success = FALSE,
    errors = character(0)
  )
  
  tryCatch({
    # PHASE 1: Build Design Framework
    if (verbose) ui_info("\\U0001F3D7\\uFE0F Phase 1: Building design framework...")
    
    framework_result <- build_design_framework(
      project_path = full_project_path,
      framework = framework,
      verbose = verbose
    )
    
    results$framework_result <- framework_result
    
    # PHASE 2: Build Design Components (+ meta-tool pipeline if source_pkg)
    if (verbose) ui_info("\\U0001F4E6 Phase 2: Building design components...")

    components_result <- build_design_components(
      project_path = full_project_path,
      source_pkg = source_pkg,
      features = features,
      ai_providers = ai_providers,
      theme = theme,
      foundation_docs = foundation_docs,
      ethical_framework = ethical_framework,
      verbose = verbose
    )

    results$components_result <- components_result

    # PHASE 3: Build Design System (if framework created UI workspace)
    if (framework_result$has_ui_workspace) {
      if (verbose) ui_info("\\U0001F3A8 Phase 3: Building design system...")

      # Change to project directory for build_design_system
      original_wd <- getwd()
      setwd(full_project_path)

      tryCatch({
        system_result <- build_design_system(verbose = verbose)
        results$system_result <- system_result
      }, finally = {
        setwd(original_wd)
      })
    }

    # PHASE 4: Export Static API (if source_pkg provided and export_static)
    if (!is.null(source_pkg) && export_static) {
      if (verbose) ui_info("\\U0001F4BE Phase 4: Exporting static API data...")

      static_output_dir <- fs::path(full_project_path, "public", "api")
      tryCatch({
        static_result <- export_static_api(
          pkg_path = source_pkg,
          output_dir = static_output_dir,
          verbose = verbose
        )
        results$static_result <- static_result
      }, error = function(e) {
        if (verbose) {
          ui_warn(glue::glue("Static export encountered issues: {e$message}"))
          ui_info("Static export is optional — the app will work in live API mode")
        }
      })
    }

    # PHASE 5: Recursive Loop (CLAUDE.md, Wiki, Ethical CI, Self-MCP)
    if (verbose) ui_info("\\U0001F504 Phase 5: Wiring recursive loop...")

    # 5a: Generate project-specific CLAUDE.md
    tryCatch({
      claude_result <- generate_claude_md(
        project_path = full_project_path,
        project_name = project_name,
        source_pkg = source_pkg,
        framework = framework,
        features = features,
        verbose = verbose
      )
      results$claude_result <- claude_result
    }, error = function(e) {
      if (verbose) ui_warn(glue::glue("CLAUDE.md generation encountered issues: {e$message}"))
    })

    # 5b: Bootstrap wiki (if foundation_docs enabled)
    if (foundation_docs) {
      tryCatch({
        wiki_result <- bootstrap_wiki(
          project_path = full_project_path,
          project_name = project_name,
          source_pkg = source_pkg,
          verbose = verbose
        )
        results$wiki_result <- wiki_result
      }, error = function(e) {
        if (verbose) ui_warn(glue::glue("Wiki bootstrap encountered issues: {e$message}"))
      })
    }

    # 5c: Generate ethical CI pipeline
    if (ethical_framework) {
      tryCatch({
        ci_result <- generate_ethical_ci(
          project_path = full_project_path,
          framework = framework,
          verbose = verbose
        )
        results$ci_result <- ci_result
      }, error = function(e) {
        if (verbose) ui_warn(glue::glue("Ethical CI generation encountered issues: {e$message}"))
      })
    }

    # 5d: Generate dataimago self-description MCP (in project for reference)
    tryCatch({
      self_mcp_path <- fs::path(full_project_path, "dataimago-mcp-schema.json")
      self_mcp_result <- generate_self_mcp(
        output_path = self_mcp_path,
        verbose = verbose
      )
      results$self_mcp_result <- self_mcp_result
    }, error = function(e) {
      if (verbose) ui_warn(glue::glue("Self-MCP generation encountered issues: {e$message}"))
    })

    results$success <- TRUE

    if (verbose) {
      ui_done(glue::glue("\\U0001F389 AI-native application '{project_name}' created successfully!"))
      ui_info(glue::glue("\\U0001F4C1 Location: {full_project_path}"))

      # Provide next steps based on framework
      if (framework == "quarto") {
        ui_info("\\U0001F680 Next steps:")
        ui_info(glue::glue("   cd {project_name}"))
        ui_info("   quarto preview")
      } else if (framework == "shiny") {
        ui_info("\\U0001F680 Next steps:")
        ui_info(glue::glue("   cd {project_name}"))
        ui_info("   R -e \"shiny::runApp()\"")
      } else if (framework %in% c("nextjs", "full")) {
        ui_info("\\U0001F680 Next steps:")
        ui_info(glue::glue("   cd {project_name}"))
        if (!is.null(source_pkg)) {
          ui_info(glue::glue("   # Start R API server:"))
          ui_info(glue::glue("   R -e \"{pkg_name}::run_{pkg_name}_api()\""))
          ui_info(glue::glue("   # In another terminal, start NextJS:"))
        }
        ui_info("   pnpm install && pnpm dev")
      }
    }
    
  }, error = function(e) {
    results$errors <- c(results$errors, as.character(e))
    if (verbose) {
      ui_oops(glue::glue("Failed to create AI application: {e$message}"))
    }
  })

  invisible(results)
}


# ====================================================================
# Remote mode implementation
# ====================================================================

#' @keywords internal
ai_remote <- function(project_name,
                      full_project_path,
                      source_pkg,
                      api_url,
                      api_key,
                      domain_type,
                      domain_name,
                      force_overwrite,
                      verbose) {

  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("Package 'httr2' is required for remote mode. Install with: install.packages('httr2')",
         call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required for remote mode. Install with: install.packages('jsonlite')",
         call. = FALSE)
  }

  key <- api_key %||% Sys.getenv("DATAIMAGO_API_KEY", unset = "")
  if (key == "") {
    stop(
      "No API key provided. Set DATAIMAGO_API_KEY environment variable or pass api_key argument.",
      call. = FALSE
    )
  }

  if (verbose) ui_info("Calling dataimago-ai orchestration API...")

  introspection <- NULL
  if (!is.null(source_pkg)) {
    introspection <- build_introspection_payload(source_pkg, verbose)
  }

  payload <- list(
    project_name = project_name,
    domain_type = domain_type,
    domain_name = domain_name,
    scope = "public",
    source_pkg_introspection = introspection,
    create_repo = FALSE
  )

  response <- tryCatch({
    req <- httr2::request(api_url) |>
      httr2::req_headers(Authorization = paste("Bearer", key)) |>
      httr2::req_body_json(payload) |>
      httr2::req_timeout(120)
    httr2::req_perform(req)
  }, error = function(e) {
    if (verbose) {
      ui_warn(glue::glue("Remote API call failed: {e$message}"))
      ui_info("Falling back to local generation pipeline...")
    }
    return(NULL)
  })

  if (is.null(response)) {
    return(ai(
      project_name = project_name,
      project_path = dirname(full_project_path),
      source_pkg = source_pkg,
      mode = "local",
      domain_type = domain_type,
      domain_name = domain_name,
      force_overwrite = force_overwrite,
      verbose = verbose
    ))
  }

  result <- httr2::resp_body_json(response)

  if (!is.null(result$error)) {
    stop(glue::glue("Orchestration API error: {result$error}"), call. = FALSE)
  }

  if (verbose) ui_info("Writing generated files to disk...")

  if (!fs::dir_exists(full_project_path)) {
    fs::dir_create(full_project_path, recurse = TRUE)
  }

  files_written <- character(0)
  for (f in result$files) {
    file_path <- fs::path(full_project_path, f$path)
    parent_dir <- dirname(file_path)
    if (!fs::dir_exists(parent_dir)) {
      fs::dir_create(parent_dir, recurse = TRUE)
    }
    writeLines(f$content, file_path)
    files_written <- c(files_written, f$path)
  }

  if (!is.null(result$manifest)) {
    manifest_path <- fs::path(full_project_path, "dataimago-framework.json")
    writeLines(
      jsonlite::toJSON(result$manifest, auto_unbox = TRUE, pretty = TRUE),
      manifest_path
    )
  }

  if (verbose) {
    ui_done(glue::glue(
      "Project '{project_name}' created via remote API ({length(files_written)} files)"
    ))
    ui_info(glue::glue("Location: {full_project_path}"))
  }

  invisible(list(
    project_name = project_name,
    project_path = as.character(full_project_path),
    mode = "remote",
    files_written = files_written,
    manifest = result$manifest,
    success = TRUE,
    errors = character(0),
    timestamp = Sys.time()
  ))
}

#' Build introspection payload from an R package for the orchestration API
#' @keywords internal
build_introspection_payload <- function(source_pkg, verbose = FALSE) {
  desc_path <- fs::path(source_pkg, "DESCRIPTION")
  if (!fs::file_exists(desc_path)) return(NULL)

  desc_lines <- readLines(desc_path)
  pkg_name <- trimws(sub("^Package:\\s*", "", grep("^Package:", desc_lines, value = TRUE)[1]))
  title <- trimws(sub("^Title:\\s*", "", grep("^Title:", desc_lines, value = TRUE)[1]))
  version <- trimws(sub("^Version:\\s*", "", grep("^Version:", desc_lines, value = TRUE)[1]))
  desc <- trimws(sub("^Description:\\s*", "", grep("^Description:", desc_lines, value = TRUE)[1]))

  exported_functions <- list()
  tryCatch({
    exports <- parse_roxygen_exports(source_pkg, verbose = FALSE)
    exported_functions <- lapply(exports, function(x) {
      list(name = x$name, title = if (!is.null(x$title)) x$title else "")
    })
  }, error = function(e) {
    if (verbose) ui_warn(glue::glue("Could not parse exports: {e$message}"))
  })

  list(
    package_name = pkg_name,
    exported_functions = exported_functions,
    description = if (!is.na(desc)) desc else title,
    version = version
  )
}