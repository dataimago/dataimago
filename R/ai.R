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
#' @param project_name Character. Name of the project/application to create
#' @param project_path Character. Path where project should be created. Default: getwd()
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
#' @param force_overwrite Logical. Overwrite existing project directory. Default: FALSE
#' @param verbose Logical. Print detailed progress information. Default: TRUE
#'
#' @return List with project metadata, file paths, and build information
#'
#' @details
#' The ai() function implements dataimago's complete application generation pipeline:
#' 
#' **Architecture Pipeline:**
#' 1. `build_design_framework()` - Creates directory structure, configs, workflows
#' 2. `build_design_components()` - Populates with content, R package files, templates  
#' 3. `build_design_system()` - Compiles assets, optimizes for production
#'
#' **Ethical AI Integration:**
#' Every generated application includes dataimago's ethical AI principles embedded
#' at the code, design, and architectural level. This ensures responsible AI development
#' practices are built-in rather than bolted-on.
#'
#' **System Requirements:**
#' - R 4.0+
#' - Node.js 18+ with pnpm installed globally
#' - Git (for repository initialization)
#' - Write permissions to target directory
#'
#' @examples
#' \dontrun{
#' # Minimal Quarto website with chat interface
#' ai("my-research-site", 
#'    framework = "quarto",
#'    features = "chat-interface")
#'
#' # Full-featured AI application  
#' ai("intelligent-dashboard",
#'    framework = "full", 
#'    features = c("chat-interface", "data-viz", "streaming"),
#'    ai_providers = c("openai", "anthropic"),
#'    theme = "professional")
#' }
#'
#' @export
ai <- function(project_name, 
               project_path = getwd(),
               framework = c("quarto", "shiny", "nextjs", "full"),
               features = NULL,
               theme = c("professional", "academic", "minimal", "ethical"), 
               ai_providers = NULL,
               ethical_framework = TRUE,
               foundation_docs = TRUE,
               force_overwrite = FALSE,
               verbose = TRUE) {
  
  # Validate arguments
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
    ui_info(glue::glue("🎯 Creating AI-native application: {crayon::bold(project_name)}"))
    ui_info(glue::glue("📁 Location: {full_project_path}"))
    ui_info(glue::glue("🏗️  Framework: {framework}"))
    ui_info(glue::glue("🎨 Theme: {theme}"))
    if (!is.null(features)) {
      ui_info(glue::glue("⚡ Features: {paste(features, collapse = ', ')}"))
    }
    if (!is.null(ai_providers)) {
      ui_info(glue::glue("🤖 AI Providers: {paste(ai_providers, collapse = ', ')}"))
    }
  }
  
  # Initialize results list
  results <- list(
    project_name = project_name,
    project_path = full_project_path,
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
    if (verbose) ui_info("🏗️  Phase 1: Building design framework...")
    
    framework_result <- build_design_framework(
      project_path = full_project_path,
      framework = framework,
      verbose = verbose
    )
    
    results$framework_result <- framework_result
    
    # PHASE 2: Build Design Components  
    if (verbose) ui_info("📦 Phase 2: Building design components...")
    
    components_result <- build_design_components(
      project_path = full_project_path,
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
      if (verbose) ui_info("🎨 Phase 3: Building design system...")
      
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
    
    results$success <- TRUE
    
    if (verbose) {
      ui_done(glue::glue("🎉 AI-native application '{project_name}' created successfully!"))
      ui_info(glue::glue("📁 Location: {full_project_path}"))
      
      # Provide next steps based on framework
      if (framework == "quarto") {
        ui_info("🚀 Next steps:")
        ui_info(glue::glue("   cd {project_name}"))
        ui_info("   quarto preview")
      } else if (framework == "shiny") {
        ui_info("🚀 Next steps:")
        ui_info(glue::glue("   cd {project_name}"))
        ui_info("   R -e \"shiny::runApp()\"")
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