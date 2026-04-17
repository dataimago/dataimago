#' @importFrom fs dir_exists path file_exists path_package file_copy
#' @importFrom rlang arg_match
#' @importFrom glue glue
#' @importFrom crayon green silver yellow red bold blue
NULL

#' Build Design Components and Content Structure
#'
#' Populates the framework with R package essentials, content templates,
#' AI components, and foundation documents aligned with dataimago principles.
#' When a source R package is provided, generates REST API scaffolding, MCP
#' tool definitions, and TypeScript utilities from the package's exported
#' functions -- implementing the "R as Source of Truth" pipeline.
#'
#' @param project_path Character. Root directory containing framework
#' @param source_pkg Character. Path to the source R package whose functions
#'   should be exposed as API endpoints and MCP tools. If NULL, only basic
#'   scaffolding is created.
#' @param features Character vector. Components to include:
#'   - "chat-interface": Conversational AI components
#'   - "document-analysis": Document processing and analysis
#'   - "data-viz": Interactive data visualization
#'   - "streaming": Real-time streaming interfaces
#'   - "model-management": AI model selection and management
#' @param ai_providers Character vector. AI service integrations to scaffold:
#'   - "openai": OpenAI GPT integration
#'   - "anthropic": Claude integration
#'   - "local": Local LLM support
#'   - "custom": Custom API endpoints
#' @param theme Character. Visual theme for generated components: "professional", "academic", "minimal", "ethical"
#' @param foundation_docs Logical. Include philosophical foundation documents. Default: TRUE
#' @param ethical_framework Logical. Include ethical AI guidelines. Default: TRUE
#' @param r_package Logical. Create R package structure. Default: TRUE
#' @param verbose Logical. Print detailed progress. Default: TRUE
#'
#' @return List with generated components, R functions, and content metadata
#'
#' @details
#' **Components Generated:**
#' - **REST API scaffolding** (api.R): RestRserve endpoints for each exported R function
#' - **MCP tool definitions** (mcp-schema.json): AI agent tool schemas from roxygen docs
#' - **TypeScript utilities** (shared-utils/): Types + dual-mode API client
#' - **Foundation Documents**: Mission, philosophy, ethical guidelines as .qmd files
#' - **Content Templates**: Page layouts, component libraries, design patterns
#'
#' **Meta-Tool Pipeline:**
#' When \code{source_pkg} is provided, the full dataimago derivation chain is
#' executed: R functions -> REST API -> MCP tools -> TypeScript types -> React components.
#' Each generated artifact inherits the ethical constraints from dataimago-design.
#'
#' @examples
#' \dontrun{
#' # Generate full pipeline from an R package
#' build_design_components("./my-project",
#'                        source_pkg = "path/to/my-rpkg",
#'                        theme = "professional")
#'
#' # Basic scaffolding without source package
#' build_design_components("./my-project",
#'                        features = "chat-interface",
#'                        theme = "professional")
#' }
#'
#' @export
build_design_components <- function(project_path,
                                    source_pkg = NULL,
                                    features = NULL,
                                    ai_providers = NULL,
                                    theme = c("professional", "academic", "minimal", "ethical"),
                                    foundation_docs = TRUE,
                                    ethical_framework = TRUE,
                                    r_package = TRUE,
                                    verbose = TRUE) {
  # Validate arguments
  theme <- rlang::arg_match(theme)

  if (verbose) {
    ui_info(glue::glue("\U0001F4E6 Building design components and content"))
    ui_info(glue::glue("\U0001F4C1 Path: {project_path}"))
    ui_info(glue::glue("\U0001F3A8 Theme: {theme}"))
    if (!is.null(source_pkg)) {
      ui_info(glue::glue("\U0001F4E6 Source package: {source_pkg}"))
    }
    if (!is.null(features)) {
      ui_info(glue::glue("\u26A1 Features: {paste(features, collapse = ', ')}"))
    }
    if (!is.null(ai_providers)) {
      ui_info(glue::glue("\U0001F916 AI Providers: {paste(ai_providers, collapse = ', ')}"))
    }
  }

  # Initialize results
  results <- list(
    project_path = project_path,
    source_pkg = source_pkg,
    features = features,
    ai_providers = ai_providers,
    theme = theme,
    foundation_docs = foundation_docs,
    ethical_framework = ethical_framework,
    files_created = character(0),
    components_generated = character(0),
    timestamp = Sys.time(),
    success = FALSE,
    errors = character(0),
    implementation_status = if (!is.null(source_pkg)) "full" else "scaffold"
  )

  tryCatch(
    {
      # Validate project path exists
      if (!fs::dir_exists(project_path)) {
        stop(glue::glue("Project path '{project_path}' does not exist. Run build_design_framework() first."),
          call. = FALSE
        )
      }

      # ====================================================================
      # META-TOOL PIPELINE: Generate from source R package
      # ====================================================================
      if (!is.null(source_pkg)) {
        if (!fs::dir_exists(source_pkg)) {
          stop(glue::glue("Source package path '{source_pkg}' does not exist."), call. = FALSE)
        }

        if (verbose) {
          ui_info("\U0001F310 Running meta-tool derivation pipeline: R -> API -> MCP -> TypeScript")
        }

        # Step 1: Generate REST API scaffolding
        api_output_dir <- fs::path(project_path, "R")
        if (!fs::dir_exists(api_output_dir)) {
          fs::dir_create(api_output_dir, recurse = TRUE)
        }

        api_result <- generate_api_scaffolding(
          pkg_path = source_pkg,
          output_dir = api_output_dir,
          verbose = verbose
        )
        results$files_created <- c(results$files_created, api_result$files_created)
        results$components_generated <- c(results$components_generated, "rest-api")

        # Step 2: Generate MCP tool definitions
        mcp_output_path <- fs::path(project_path, "mcp-schema.json")

        generate_mcp_tools(
          pkg_path = source_pkg,
          output_path = mcp_output_path,
          verbose = verbose
        )
        results$files_created <- c(results$files_created, "mcp-schema.json")
        results$components_generated <- c(results$components_generated, "mcp-tools")

        # Step 3: Generate TypeScript types and dual-mode API client
        types_output_dir <- fs::path(project_path, "shared-utils")

        types_result <- generate_shared_utils(
          pkg_path = source_pkg,
          output_dir = types_output_dir,
          verbose = verbose
        )
        results$files_created <- c(
          results$files_created,
          paste0("shared-utils/", types_result$files_created)
        )
        results$components_generated <- c(
          results$components_generated,
          "typescript-types", "dual-mode-api-client"
        )
      }

      # ====================================================================
      # CONTENT SCAFFOLDING: Basic templates and documentation
      # ====================================================================

      # Create basic index.qmd if ui/www exists
      if (fs::dir_exists(fs::path(project_path, "ui", "www"))) {
        index_content <- create_basic_index_qmd(theme, features, verbose)
        index_path <- fs::path(project_path, "ui", "www", "index.qmd")
        writeLines(index_content, index_path)
        results$files_created <- c(results$files_created, "ui/www/index.qmd")
        results$components_generated <- c(results$components_generated, "index-page")
        if (verbose) ui_done("Created basic index.qmd")
      }

      # Add foundation documents if requested
      if (foundation_docs) {
        foundation_result <- add_foundation_documents(
          project_path = project_path,
          theme = theme,
          verbose = verbose
        )

        results$files_created <- c(results$files_created, foundation_result$files_created)
        results$components_generated <- c(results$components_generated, foundation_result$components_generated)
      }

      # Add ethical framework documentation if requested
      if (ethical_framework) {
        ethical_result <- add_ethical_framework(
          project_path = project_path,
          verbose = verbose
        )

        results$files_created <- c(results$files_created, ethical_result$files_created)
        results$components_generated <- c(results$components_generated, ethical_result$components_generated)
      }

      # Create feature-specific files
      if (!is.null(features)) {
        features_result <- create_feature_stubs(
          project_path = project_path,
          features = features,
          theme = theme,
          verbose = verbose
        )

        results$files_created <- c(results$files_created, features_result$files_created)
        results$components_generated <- c(results$components_generated, features_result$components_generated)
      }

      results$success <- TRUE

      if (verbose) {
        ui_done("\U0001F389 Design components completed!")
        ui_info(glue::glue("\U0001F4C4 Created {length(results$files_created)} files"))
        ui_info(glue::glue("\U0001F9E9 Generated {length(results$components_generated)} components"))
        if (!is.null(source_pkg)) {
          ui_info("\U0001F504 Meta-tool pipeline: R \u2192 API \u2192 MCP \u2192 TypeScript \u2714")
        }
      }
    },
    error = function(e) {
      results$errors <- c(results$errors, as.character(e))
      if (verbose) {
        ui_oops(glue::glue("Failed to build components: {e$message}"))
      }
    }
  )

  invisible(results)
}

# Helper function: Create basic index.qmd
create_basic_index_qmd <- function(theme, features, verbose) {
  title <- switch(theme,
    "professional" = "Professional AI-Native Application",
    "academic" = "Academic Research Platform",
    "minimal" = "Minimal AI Interface",
    "ethical" = "Ethical AI Framework",
    "AI-Native Application"
  )

  features_text <- if (!is.null(features)) {
    paste0("This application includes: ", paste(features, collapse = ", "))
  } else {
    "This is a basic AI-native application scaffold."
  }

  c(
    "---",
    glue::glue("title: \"{title}\""),
    "subtitle: \"Built with dataimago\"",
    "---",
    "",
    "# Welcome to Your AI-Native Application",
    "",
    features_text,
    "",
    "## Getting Started",
    "",
    "This application was created using the dataimago framework, which embeds ethical AI principles",
    "at every level of development.",
    "",
    "## Next Steps",
    "",
    "- Customize your content and components",
    "- Configure AI integrations",
    "- Deploy with confidence in ethical AI practices",
    "",
    "---",
    "",
    "*Built with \u2764\uFE0F using dataimago - ethical AI-native development*"
  )
}

# Helper function: Add foundation documents (stub)
add_foundation_documents <- function(project_path, theme, verbose) {
  results <- list(
    files_created = character(0),
    components_generated = character(0)
  )

  # Create inst/dataimago directory if it doesn't exist
  dataimago_dir <- fs::path(project_path, "inst", "dataimago")
  if (!fs::dir_exists(dataimago_dir)) {
    fs::dir_create(dataimago_dir, recurse = TRUE)
  }

  # Create basic mission.qmd
  mission_content <- c(
    "---",
    "title: \"Mission\"",
    "subtitle: \"Our Purpose and Vision\"",
    "---",
    "",
    "# Mission Statement",
    "",
    "This AI-native application embeds ethical principles and responsible development",
    "practices at every level of implementation.",
    "",
    "## Core Values",
    "",
    "- **Transparency**: Clear, interpretable AI operations",
    "- **Accountability**: Responsible AI development and deployment",
    "- **Fairness**: Bias mitigation and equitable outcomes",
    "- **Privacy**: User data protection and consent",
    "",
    "*Generated by dataimago framework*"
  )

  mission_path <- fs::path(dataimago_dir, "mission.qmd")
  writeLines(mission_content, mission_path)
  results$files_created <- c(results$files_created, "inst/dataimago/mission.qmd")
  results$components_generated <- c(results$components_generated, "mission-document")

  if (verbose) ui_done("Created foundation mission document")

  results
}

# Helper function: Add ethical framework (stub)
add_ethical_framework <- function(project_path, verbose) {
  results <- list(
    files_created = character(0),
    components_generated = character(0)
  )

  # Create ethical guidelines document
  dataimago_dir <- fs::path(project_path, "inst", "dataimago")

  ethical_content <- c(
    "---",
    "title: \"Ethical AI Framework\"",
    "subtitle: \"Responsible Development Guidelines\"",
    "---",
    "",
    "# Ethical AI Development Framework",
    "",
    "This document outlines the ethical considerations embedded in this application.",
    "",
    "## Development Principles",
    "",
    "1. **Human-Centered Design**: AI serves human needs and values",
    "2. **Bias Mitigation**: Proactive identification and correction of biases",
    "3. **Transparency**: Explainable AI decisions and processes",
    "4. **Privacy Protection**: Data minimization and user consent",
    "5. **Accountability**: Clear responsibility chains for AI decisions",
    "",
    "## Implementation Guidelines",
    "",
    "- All AI components include bias testing",
    "- User consent mechanisms for data processing",
    "- Regular ethical audits and reviews",
    "- Documentation of AI decision pathways",
    "",
    "*Powered by dataimago ethical AI framework*"
  )

  ethical_path <- fs::path(dataimago_dir, "ethical-framework.qmd")
  writeLines(ethical_content, ethical_path)
  results$files_created <- c(results$files_created, "inst/dataimago/ethical-framework.qmd")
  results$components_generated <- c(results$components_generated, "ethical-framework")

  if (verbose) ui_done("Created ethical AI framework document")

  results
}

# Helper function: Create feature-specific stub files
create_feature_stubs <- function(project_path, features, theme, verbose) {
  results <- list(
    files_created = character(0),
    components_generated = character(0)
  )

  www_dir <- fs::path(project_path, "ui", "www")

  for (feature in features) {
    feature_content <- create_feature_stub_content(feature, theme)
    feature_filename <- glue::glue("{gsub('-', '_', feature)}.qmd")
    feature_path <- fs::path(www_dir, feature_filename)

    if (fs::dir_exists(www_dir)) {
      writeLines(feature_content, feature_path)
      results$files_created <- c(results$files_created, fs::path("ui", "www", feature_filename))
      results$components_generated <- c(results$components_generated, feature)

      if (verbose) ui_done(glue::glue("Created {feature} stub"))
    }
  }

  results
}

# Helper function: Create feature-specific content
create_feature_stub_content <- function(feature, theme) {
  feature_title <- switch(feature,
    "chat-interface" = "AI Chat Interface",
    "document-analysis" = "Document Analysis",
    "data-viz" = "Data Visualization",
    "streaming" = "Real-time Streaming",
    "model-management" = "AI Model Management",
    tools::toTitleCase(gsub("-", " ", feature))
  )

  c(
    "---",
    glue::glue("title: \"{feature_title}\""),
    "subtitle: \"AI-Native Component\"",
    "---",
    "",
    glue::glue("# {feature_title}"),
    "",
    "\U0001F6A7 **Stub Implementation**",
    "",
    glue::glue("This {feature} component is currently a placeholder."),
    "Full implementation will include:",
    "",
    get_feature_description(feature),
    "",
    "## Ethical AI Integration",
    "",
    "This component will include:",
    "- Bias detection and mitigation",
    "- Transparent decision processes",
    "- User consent and privacy protection",
    "- Regular ethical auditing",
    "",
    "*To be implemented with dataimago AI component library*"
  )
}

# Helper function: Get feature descriptions
get_feature_description <- function(feature) {
  switch(feature,
    "chat-interface" = paste0(
      "- Real-time conversational AI interface\n",
      "- Message history and context management\n",
      "- Ethical response filtering\n",
      "- User preference learning"
    ),
    "document-analysis" = paste0(
      "- Automated document processing\n",
      "- Content extraction and summarization\n",
      "- Sentiment and topic analysis\n",
      "- Bias detection in content"
    ),
    "data-viz" = paste0(
      "- Interactive chart generation\n",
      "- Real-time data visualization\n",
      "- Accessible design patterns\n",
      "- Ethical data representation"
    ),
    "streaming" = paste0(
      "- Real-time data streaming\n",
      "- Live update interfaces\n",
      "- Performance optimization\n",
      "- Privacy-preserving streaming"
    ),
    "model-management" = paste0(
      "- AI model selection interface\n",
      "- Performance monitoring\n",
      "- Bias evaluation tools\n",
      "- Model lifecycle management"
    ),
    paste0(
      "- Component-specific functionality\n",
      "- Ethical AI integration\n",
      "- User-centered design\n",
      "- Performance optimization"
    )
  )
}
