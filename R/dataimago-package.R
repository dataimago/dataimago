#' dataimago: Ethical AI-Native Data Science Foundation Package
#'
#' @description
#' The `dataimago` package contains the philosophical foundations, technical 
#' architecture, and application templates for dataimago's emancipatory data 
#' science platform. It provides versioned access to critical theory frameworks, 
#' application blueprints, and packageSkeleton functionality for creating 
#' AI-native data science applications that reconcile meaning (hermeneutics) 
#' and measurement (positivism).
#'
#' @details
#' ## Package Philosophy
#' 
#' dataimago represents a fundamental inversion: instead of embedding culture in AI, 
#' we **embed AI in culture** for emancipatory ends. This approach transforms AI 
#' from an instrument of domination into a force for human flourishing.
#' 
#' ## Core Components
#' 
#' ### Foundation Documents (`inst/dataimago/`)
#' \itemize{
#'   \item **01_Foundations/**: Mission, vision, philosophy, governance documents
#'   \item **02_Manifesto/**: Critical theory content and paradigm contrasts
#'   \item **03_Application_Architecture/**: Technical blueprints and best practices
#'   \item **04_dataimago_Content/**: Design assets and visual identity
#' }
#' 
#' ### Documentation Generation
#' \itemize{
#'   \item \code{\link{create_quarto_documentation}}: Convert R packages to 
#'     ethical AI documentation websites
#'   \item Automated integration of philosophical context into technical docs
#'   \item dataimago branding and visual identity application
#'   \item MCP-compatible structured outputs for AI agent integration
#' }
#' 
#' ### Planned Functionality
#' \itemize{
#'   \item Foundation access functions for programmatic content retrieval
#'   \item Application skeleton generation with embedded ethical frameworks
#'   \item Flow-based performance management tools
#'   \item NextJS + R integration templates
#' }
#' 
#' ## For AI Agents and MCP Integration
#' 
#' This package is explicitly designed for AI agent integration:
#' 
#' ### Structured Metadata
#' \itemize{
#'   \item Comprehensive roxygen2 documentation with philosophical context
#'   \item Consistent parameter naming and return value structures
#'   \item Machine-readable ethical annotations in generated documentation
#'   \item JSON-compatible outputs where appropriate
#' }
#' 
#' ### AI Context Files
#' \itemize{
#'   \item `inst/CLAUDE.md`: Persistent context for AI interactions
#'   \item `inst/AGENT_INDEX.md`: Agent coordination and capabilities
#'   \item Foundation documents provide philosophical grounding for AI reasoning
#' }
#' 
#' ### MCP Tool Compatibility
#' All exported functions include:
#' \itemize{
#'   \item Detailed parameter descriptions with types and constraints
#'   \item Clear return value specifications
#'   \item Comprehensive examples showing typical usage patterns
#'   \item Error conditions and handling guidance
#'   \item Philosophical context explaining the "why" behind each function
#' }
#' 
#' ## Code-as-Philosophy Commitments
#' 
#' \itemize{
#'   \item **Hermeneutic Transparency**: All modeling assumptions documented and interpretable
#'   \item **Positivistic Rigor**: Empirical operations robust, efficient, and replicable
#'   \item **Ethical Reflexivity**: Tools include affordances for users to interrogate usage
#'   \item **Iterative Design**: Each commit is dialectical step toward future aspirations
#' }
#' 
#' ## Getting Started
#' 
#' Load the package and generate documentation:
#' \preformatted{
#' library(dataimago)
#' create_quarto_documentation()
#' }
#' 
#' Access foundation documents (planned):
#' \preformatted{
#' get_foundation_document("mission")
#' get_manifesto_content("critical_theory")
#' }
#' 
#' Generate applications (planned):
#' \preformatted{
#' create_dataimago_app(name = "my-project", type = "nextjs")
#' bootstrap_emancipatory_framework(path = "my-project")
#' }
#'
#' @section Package Metadata:
#' \itemize{
#'   \item **Version**: 0.0-0.2 (using dataimago semantic versioning)
#'   \item **License**: MIT
#'   \item **Maintainer**: Damian W. Betebenner <dbetebenner@nciea.org>
#'   \item **Website**: https://dataimago.github.io/dataimago/
#'   \item **Repository**: https://github.com/dataimago/dataimago/
#' }
#'
#' @section Citation:
#' To cite dataimago in publications:
#' \preformatted{
#' citation("dataimago")
#' }
#'
#' @section Philosophy in Practice:
#' "Would this object help an AI understand, improve, or operationalize 
#' emancipatory thinking? If yes, it belongs." - dataimago development philosophy
#'
#' @keywords package ethical-ai documentation-generation critical-theory
#' @concept dataimago emancipatory-ai MCP-compatible foundation-package
"_PACKAGE"
