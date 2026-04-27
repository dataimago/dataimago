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
#' R functions -> REST API -> MCP tools -> TypeScript types -> Web Application.
#' The generated application inherits dataimago's ethical constraints structurally.
#'
#' @param project_name Character. Name of the project/application to create
#' @param project_path Character. Path where project should be created. Default: getwd()
#' @param source_pkg Character. Path to the source R package whose exported
#'   functions should drive the generated application. This is the "R as Source
#'   of Truth" -- all APIs, MCP tools, types, and UI derive from this package.
#'   If NULL, creates scaffolding without the derivation pipeline.
#' @param mode Character. Generation mode: "remote" delegates to the
#'   dataimago-ai platform API (recommended; requires `DATAIMAGO_API_KEY`).
#'   "local" was retired in 0.0-4.0 and now throws an explanatory error
#'   pointing to "remote" or to the manual new-consumer checklist.
#'   Default: "remote".
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
#' The `ai()` function is the public entry point to dataimago's application
#' generation pipeline. In the current `0.0-4.x` release, generation is
#' delegated to the dataimago-ai platform over HTTPS; the in-package local
#' scaffolder was retired alongside the `ui/src/dataimago-design/` submodule
#' (see `NEWS.md` 0.0-4.0).
#'
#' **Remote mode (`mode = "remote"`, recommended):**
#' Calls `https://dataimago.ai/api/orchestrate` with a bearer token from
#' `DATAIMAGO_API_KEY`. The platform assembles the project using canonical
#' templates from the sibling `dataimago-design` repo and the published
#' `@dataimago/*` packages, and returns a file manifest that `ai()` writes
#' to disk.
#'
#' **Local mode (`mode = "local"`):**
#' Currently unavailable. The in-package scaffolders
#' (`build_design_framework()`, `create_ui_workspace()`) were removed in
#' 0.0-4.0 because they wrote against the retired design-system submodule
#' layout. New local scaffolders tracking the package-channel model are
#' planned for a later release. Follow
#' `dataimago-design/wiki/patterns/new-consumer-checklist.md` to wire a new
#' project to the `@dataimago/*` packages by hand in the meantime.
#'
#' **Ethical AI Integration:**
#' Every generated application inherits dataimago's ethical AI principles
#' structurally because the design tokens, CSS, and components it consumes
#' from the `@dataimago/*` packages already encode them.
#'
#' **System Requirements:**
#' - R 4.0+
#' - `httr2` and `jsonlite` (for remote mode)
#' - `DATAIMAGO_API_KEY` environment variable (for remote mode)
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
               mode = c("remote", "local"),
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
      call. = FALSE
    )
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

  # ---- LOCAL MODE: retired in 0.0-4.0; remains unavailable ----
  #
  # The local scaffolders (build_design_framework(), create_ui_workspace())
  # were retired with the ui/src/dataimago-design/ submodule in 0.0-4.0.
  # Use mode = "remote" (with DATAIMAGO_API_KEY set) or bootstrap a new
  # consumer by hand following
  # dataimago-design/wiki/patterns/new-consumer-checklist.md.
  stop(
    paste0(
      "ai(mode = \"local\") is unavailable. ",
      "The in-package scaffolders were retired alongside the ",
      "ui/src/dataimago-design/ submodule in 0.0-4.0. Either:\n",
      "  1. Call ai(mode = \"remote\") with DATAIMAGO_API_KEY set, or\n",
      "  2. Bootstrap the project by hand following\n",
      "     dataimago-design/wiki/patterns/new-consumer-checklist.md.\n",
      "See NEWS.md 0.0-4.0 for the original migration note."
    ),
    call. = FALSE
  )
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
      call. = FALSE
    )
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required for remote mode. Install with: install.packages('jsonlite')",
      call. = FALSE
    )
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

  response <- tryCatch(
    {
      req <- httr2::request(api_url) |>
        httr2::req_headers(Authorization = paste("Bearer", key)) |>
        httr2::req_body_json(payload) |>
        httr2::req_timeout(120)
      httr2::req_perform(req)
    },
    error = function(e) {
      if (verbose) {
        ui_warn(glue::glue("Remote API call failed: {e$message}"))
      }
      NULL
    }
  )

  if (is.null(response)) {
    stop(
      paste0(
        "Remote orchestration API at ", api_url, " is unreachable. ",
        "Local fallback was retired in dataimago 0.0-4.0; see ",
        "dataimago-design/wiki/patterns/new-consumer-checklist.md to ",
        "bootstrap the project by hand."
      ),
      call. = FALSE
    )
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
  if (!fs::file_exists(desc_path)) {
    return(NULL)
  }

  desc_lines <- readLines(desc_path)
  pkg_name <- trimws(sub("^Package:\\s*", "", grep("^Package:", desc_lines, value = TRUE)[1]))
  title <- trimws(sub("^Title:\\s*", "", grep("^Title:", desc_lines, value = TRUE)[1]))
  version <- trimws(sub("^Version:\\s*", "", grep("^Version:", desc_lines, value = TRUE)[1]))
  desc <- trimws(sub("^Description:\\s*", "", grep("^Description:", desc_lines, value = TRUE)[1]))

  exported_functions <- list()
  tryCatch(
    {
      exports <- parse_roxygen_exports(source_pkg, verbose = FALSE)
      exported_functions <- lapply(exports, function(x) {
        list(name = x$name, title = if (!is.null(x$title)) x$title else "")
      })
    },
    error = function(e) {
      if (verbose) ui_warn(glue::glue("Could not parse exports: {e$message}"))
    }
  )

  list(
    package_name = pkg_name,
    exported_functions = exported_functions,
    description = if (!is.na(desc)) desc else title,
    version = version
  )
}
