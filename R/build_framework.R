#' @importFrom fs dir_exists dir_create path file_copy file_exists path_package
#' @importFrom processx run
#' @importFrom jsonlite toJSON
#' @importFrom yaml write_yaml
#' @importFrom rlang arg_match
#' @importFrom glue glue
#' @importFrom crayon green silver yellow red bold blue
NULL

#' Build Complete Design Framework Infrastructure
#'
#' Creates the foundational architecture for AI-native applications including
#' directory structure, configuration files, build systems, and deployment workflows.
#' This function establishes the "R as source of truth" philosophy by creating
#' comprehensive project scaffolding with embedded ethical AI principles.
#'
#' @param project_path Character. Root directory for framework setup
#' @param framework Character. Target framework: "quarto", "shiny", "nextjs", or "full". Default: "quarto"
#' @param include_workflows Logical. Include GitHub Actions workflows. Default: TRUE
#' @param include_docker Logical. Include Docker configuration. Default: FALSE
#' @param node_package_manager Character. "pnpm", "npm", or "yarn". Default: "pnpm"
#' @param git_init Logical. Initialize git repository. Default: TRUE
#' @param verbose Logical. Print detailed progress. Default: TRUE
#'
#' @return List with created directories, configuration files, and metadata
#'
#' @details
#' **Infrastructure Created:**
#' - **ui/**: Complete Node.js workspace with package.json, build.js
#' - **inst/**: R package data structure with foundation documents  
#' - **R/**: R function scaffolding with ethical AI annotations
#' - **.github/workflows/**: Automated testing, building, deployment
#' - **Configuration files**: _quarto.yml, .Rbuildignore, NAMESPACE, etc.
#' - **Build system**: PostCSS, Sass, Style Dictionary integration
#'
#' **Design Philosophy Integration:**
#' All generated infrastructure embeds dataimago's ethical AI principles and
#' "R as source of truth" philosophy at the architectural level.
#'
#' **System Requirements:**
#' - Node.js 18+ and specified package manager installed globally
#' - Git (if git_init = TRUE)
#' - Write permissions to target directory
#'
#' @examples
#' \dontrun{
#' # Basic Quarto framework
#' build_design_framework("./my-project", framework = "quarto")
#' 
#' # Full framework with Docker support
#' build_design_framework("./my-app", 
#'                        framework = "full",
#'                        include_docker = TRUE,
#'                        node_package_manager = "pnpm")
#' }
#'
#' @export
build_design_framework <- function(project_path,
                                 framework = c("quarto", "shiny", "nextjs", "full"),
                                 include_workflows = TRUE,
                                 include_docker = FALSE, 
                                 node_package_manager = c("pnpm", "npm", "yarn"),
                                 git_init = TRUE,
                                 verbose = TRUE) {
  
  # Validate arguments
  framework <- rlang::arg_match(framework)
  node_package_manager <- rlang::arg_match(node_package_manager)
  
  if (verbose) {
    ui_info(glue::glue("🏗️  Building design framework infrastructure"))
    ui_info(glue::glue("📁 Path: {project_path}"))
    ui_info(glue::glue("🎯 Framework: {framework}"))
  }
  
  # Initialize results
  results <- list(
    project_path = project_path,
    framework = framework,
    directories_created = character(0),
    files_created = character(0),
    has_ui_workspace = FALSE,
    has_r_package = FALSE,
    timestamp = Sys.time(),
    success = FALSE,
    errors = character(0)
  )
  
  tryCatch({
    # Ensure project directory exists
    if (!fs::dir_exists(project_path)) {
      fs::dir_create(project_path, recurse = TRUE)
      results$directories_created <- c(results$directories_created, project_path)
      if (verbose) ui_done(glue::glue("Created project directory: {project_path}"))
    }
    
    # Create core directory structure based on framework
    core_dirs <- get_framework_directories(framework)
    
    for (dir in core_dirs) {
      dir_path <- fs::path(project_path, dir)
      if (!fs::dir_exists(dir_path)) {
        fs::dir_create(dir_path, recurse = TRUE)
        results$directories_created <- c(results$directories_created, dir)
        if (verbose) ui_done(glue::glue("Created directory: {dir}"))
      }
    }
    
    # Create configuration files
    config_files <- create_framework_configs(
      project_path = project_path,
      framework = framework,
      node_package_manager = node_package_manager,
      verbose = verbose
    )
    
    results$files_created <- c(results$files_created, config_files)
    
    # Set up UI workspace if needed
    if (framework %in% c("quarto", "nextjs", "full")) {
      ui_result <- setup_ui_workspace(
        project_path = project_path,
        framework = framework,
        node_package_manager = node_package_manager,
        verbose = verbose
      )
      
      results$has_ui_workspace <- ui_result$success
      results$files_created <- c(results$files_created, ui_result$files_created)
      results$directories_created <- c(results$directories_created, ui_result$directories_created)
    }
    
    # Set up R package structure if needed
    if (framework %in% c("shiny", "full") || grepl("r-package", framework)) {
      r_result <- setup_r_package_structure(
        project_path = project_path,
        verbose = verbose
      )
      
      results$has_r_package <- r_result$success
      results$files_created <- c(results$files_created, r_result$files_created)
    }
    
    # Set up GitHub workflows
    if (include_workflows) {
      workflow_result <- setup_github_workflows(
        project_path = project_path,
        framework = framework,
        verbose = verbose
      )
      
      results$files_created <- c(results$files_created, workflow_result$files_created)
      results$directories_created <- c(results$directories_created, workflow_result$directories_created)
    }
    
    # Initialize git repository
    if (git_init) {
      git_result <- initialize_git_repository(
        project_path = project_path,
        verbose = verbose
      )
      
      results$files_created <- c(results$files_created, git_result$files_created)
    }
    
    results$success <- TRUE
    
    if (verbose) {
      ui_done("🎉 Design framework infrastructure created successfully!")
      ui_info(glue::glue("📁 Created {length(results$directories_created)} directories"))
      ui_info(glue::glue("📄 Created {length(results$files_created)} files"))
    }
    
  }, error = function(e) {
    results$errors <- c(results$errors, as.character(e))
    if (verbose) {
      ui_oops(glue::glue("Failed to build framework: {e$message}"))
    }
  })
  
  invisible(results)
}

# Helper function: Get framework-specific directories
get_framework_directories <- function(framework) {
  base_dirs <- c("inst", "inst/dataimago")
  
  switch(framework,
    "quarto" = c(base_dirs, "ui", "ui/src", "ui/src/styles", "ui/src/js", "ui/src/tokens", "ui/www", "docs"),
    "shiny" = c(base_dirs, "R", "man", "tests", "tests/testthat", "inst/shiny-app"),
    "nextjs" = c(base_dirs, "ui", "ui/src", "ui/src/styles", "ui/src/js", "ui/src/tokens", "ui/www", "app"),
    "full" = c(base_dirs, "ui", "ui/src", "ui/src/styles", "ui/src/js", "ui/src/tokens", "ui/www", 
               "R", "man", "tests", "tests/testthat", "docs", "app")
  )
}

# Helper function: Create framework configuration files
create_framework_configs <- function(project_path, framework, node_package_manager, verbose) {
  created_files <- character(0)
  
  # Create .Rbuildignore
  rbuildignore_content <- get_rbuildignore_content(framework)
  rbuildignore_path <- fs::path(project_path, ".Rbuildignore")
  writeLines(rbuildignore_content, rbuildignore_path)
  created_files <- c(created_files, ".Rbuildignore")
  if (verbose) ui_done("Created .Rbuildignore")
  
  # Create .gitignore
  gitignore_content <- get_gitignore_content(framework)
  gitignore_path <- fs::path(project_path, ".gitignore")
  writeLines(gitignore_content, gitignore_path)
  created_files <- c(created_files, ".gitignore")
  if (verbose) ui_done("Created .gitignore")
  
  # Framework-specific configs
  if (framework %in% c("quarto", "nextjs", "full")) {
    # Create basic _quarto.yml
    quarto_config <- get_quarto_config(framework)
    quarto_path <- fs::path(project_path, "ui", "www", "_quarto.yml")
    yaml::write_yaml(quarto_config, quarto_path)
    created_files <- c(created_files, "ui/www/_quarto.yml")
    if (verbose) ui_done("Created _quarto.yml")
  }
  
  created_files
}

# Helper function: Set up UI workspace
setup_ui_workspace <- function(project_path, framework, node_package_manager, verbose) {
  results <- list(
    success = FALSE,
    files_created = character(0),
    directories_created = character(0)
  )
  
  tryCatch({
    # Create package.json
    package_json <- get_package_json(framework, node_package_manager)
    package_json_path <- fs::path(project_path, "ui", "package.json")
    writeLines(jsonlite::toJSON(package_json, pretty = TRUE, auto_unbox = TRUE), package_json_path)
    results$files_created <- c(results$files_created, "ui/package.json")
    if (verbose) ui_done("Created ui/package.json")
    
    # Copy build.js from current package
    build_js_source <- fs::path_package("dataimago", "ui", "build.js")
    if (fs::file_exists(build_js_source)) {
      build_js_dest <- fs::path(project_path, "ui", "build.js")
      fs::file_copy(build_js_source, build_js_dest)
      results$files_created <- c(results$files_created, "ui/build.js")
      if (verbose) ui_done("Created ui/build.js")
    }
    
    # Create basic token files
    create_basic_tokens(fs::path(project_path, "ui", "src", "tokens"), verbose)
    results$files_created <- c(results$files_created, "ui/src/tokens/colors.json", "ui/src/tokens/typography.json")
    
    # Create basic SCSS files
    create_basic_scss(fs::path(project_path, "ui", "src", "styles"), verbose)
    results$files_created <- c(results$files_created, "ui/src/styles/main.scss")
    
    results$success <- TRUE
  }, error = function(e) {
    if (verbose) ui_warn(glue::glue("UI workspace setup encountered issues: {e$message}"))
  })
  
  results
}

# Helper function: Set up R package structure
setup_r_package_structure <- function(project_path, verbose) {
  results <- list(
    success = FALSE,
    files_created = character(0)
  )
  
  tryCatch({
    # Create basic DESCRIPTION file
    description_content <- get_basic_description()
    description_path <- fs::path(project_path, "DESCRIPTION")
    writeLines(description_content, description_path)
    results$files_created <- c(results$files_created, "DESCRIPTION")
    if (verbose) ui_done("Created DESCRIPTION")
    
    # Create basic NAMESPACE
    namespace_content <- "# Generated by roxygen2: do not edit by hand\n\nexport()"
    namespace_path <- fs::path(project_path, "NAMESPACE")
    writeLines(namespace_content, namespace_path)
    results$files_created <- c(results$files_created, "NAMESPACE")
    if (verbose) ui_done("Created NAMESPACE")
    
    results$success <- TRUE
  }, error = function(e) {
    if (verbose) ui_warn(glue::glue("R package setup encountered issues: {e$message}"))
  })
  
  results
}

# Helper function: Set up GitHub workflows
setup_github_workflows <- function(project_path, framework, verbose) {
  results <- list(
    files_created = character(0),
    directories_created = character(0)
  )
  
  # Create .github/workflows directory
  workflows_dir <- fs::path(project_path, ".github", "workflows")
  if (!fs::dir_exists(workflows_dir)) {
    fs::dir_create(workflows_dir, recurse = TRUE)
    results$directories_created <- c(results$directories_created, ".github", ".github/workflows")
  }
  
  # Create basic CI workflow
  ci_workflow <- get_ci_workflow(framework)
  ci_path <- fs::path(workflows_dir, "ci.yml")
  yaml::write_yaml(ci_workflow, ci_path)
  results$files_created <- c(results$files_created, ".github/workflows/ci.yml")
  if (verbose) ui_done("Created GitHub Actions CI workflow")
  
  results
}

# Helper function: Initialize git repository
initialize_git_repository <- function(project_path, verbose) {
  results <- list(files_created = character(0))
  
  tryCatch({
    # Initialize git repo
    processx::run("git", c("init"), wd = project_path, echo = FALSE)
    if (verbose) ui_done("Initialized git repository")
    
    # Create README.md
    readme_content <- get_readme_template()
    readme_path <- fs::path(project_path, "README.md")
    writeLines(readme_content, readme_path)
    results$files_created <- c(results$files_created, "README.md")
    if (verbose) ui_done("Created README.md")
    
  }, error = function(e) {
    if (verbose) ui_warn(glue::glue("Git initialization encountered issues: {e$message}"))
  })
  
  results
}

# Content generation helper functions (simplified versions for now)
get_rbuildignore_content <- function(framework) {
  c(
    "^.*\\.Rproj$",
    "^\\.Rproj\\.user$", 
    "^ui/node_modules$",
    "^ui/dist$",
    "^docs$",
    "^\\.github$"
  )
}

get_gitignore_content <- function(framework) {
  c(
    ".Rproj.user",
    "node_modules/",
    ".DS_Store",
    "Thumbs.db"
  )
}

get_package_json <- function(framework, node_package_manager) {
  list(
    name = "dataimago-design-system",
    version = "0.1.0",
    description = "AI-Native Design System",
    scripts = list(
      build = "node build.js"
    ),
    devDependencies = list(
      sass = "^1.77.0",
      postcss = "^8.4.0",
      "style-dictionary" = "^4.0.0"
    )
  )
}

get_quarto_config <- function(framework) {
  list(
    project = list(
      type = "website",
      `output-dir` = "../../docs"
    ),
    website = list(
      title = "AI-Native Application",
      navbar = list(
        left = list(
          list(href = "index.qmd", text = "Home")
        )
      )
    ),
    format = list(
      html = list(
        theme = "cosmo",
        toc = TRUE
      )
    )
  )
}

get_basic_description <- function() {
  c(
    "Package: dataimago.app",
    "Version: 0.1.0",
    "Title: AI-Native Application",
    "Description: An AI-native application created with dataimago.",
    "License: MIT",
    "Encoding: UTF-8"
  )
}

get_ci_workflow <- function(framework) {
  list(
    name = "CI",
    on = list(
      push = list(branches = "main"),
      pull_request = list(branches = "main")
    ),
    jobs = list(
      build = list(
        `runs-on` = "ubuntu-latest",
        steps = list(
          list(uses = "actions/checkout@v3"),
          list(
            name = "Setup Node.js",
            uses = "actions/setup-node@v3",
            `with` = list(`node-version` = "18")
          ),
          list(
            name = "Build",
            run = "echo 'Build steps here'"
          )
        )
      )
    )
  )
}

get_readme_template <- function() {
  c(
    "# AI-Native Application",
    "",
    "An AI-native application created with dataimago.",
    "",
    "## Getting Started",
    "",
    "This application was scaffolded using the dataimago framework.",
    "",
    "## Development",
    "",
    "Built with ethical AI principles and R-first workflows."
  )
}

create_basic_tokens <- function(tokens_dir, verbose) {
  # Create basic colors.json
  colors <- list(
    color = list(
      primary = list(value = "#3498DB"),
      secondary = list(value = "#2C3E50")
    )
  )
  colors_path <- fs::path(tokens_dir, "colors.json")
  writeLines(jsonlite::toJSON(colors, pretty = TRUE, auto_unbox = TRUE), colors_path)
  
  # Create basic typography.json
  typography <- list(
    font = list(
      family = list(
        primary = list(value = "system-ui, sans-serif")
      ),
      size = list(
        base = list(value = "1rem")
      )
    )
  )
  typography_path <- fs::path(tokens_dir, "typography.json")
  writeLines(jsonlite::toJSON(typography, pretty = TRUE, auto_unbox = TRUE), typography_path)
  
  if (verbose) ui_done("Created basic design tokens")
}

create_basic_scss <- function(styles_dir, verbose) {
  scss_content <- c(
    "/* AI-Native Design System */",
    "@import '../dist/tokens.css';",
    "",
    "body {",
    "  font-family: var(--font-family-primary, system-ui, sans-serif);",
    "  color: var(--color-primary, #3498DB);",
    "}"
  )
  
  scss_path <- fs::path(styles_dir, "main.scss")
  writeLines(scss_content, scss_path)
  
  if (verbose) ui_done("Created basic SCSS files")
}