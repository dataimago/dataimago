#' dataimago: AI-Native Web-Application Development Framework
#'
#' @description
#' The `dataimago` package is a comprehensive development framework that accelerates
#' the creation of data science web applications for both human developers and AI agents.
#' It provides complete design system compilation, multi-platform deployment
#' (Quarto, Shiny, Next.js), MCP-compatible tooling, and embedded ethical AI principles.
#' Features R-first workflows that wrap modern web development tools in familiar
#' interfaces, enabling rapid application scaffolding with consistent branding and best practices.
#'
#' @details
#' ## Framework Philosophy
#'
#' dataimago is an AI-native development framework that embeds ethical principles
#' and consistent patterns into every aspect of application development. Rather than
#' requiring developers to manually implement best practices, the framework provides
#' pre-built components, automated tooling, and structured workflows that ensure
#' applications are scalable, accessible, and aligned with human flourishing.
#'
#' ## Framework Components
#' ### AI-Native Application Generation
#' \itemize{
#'   \item \code{\link{ai}}: Meta-orchestration function for complete AI-native application creation
#'   \item \code{\link{build_design_framework}}: Create foundational infrastructure and directory scaffolding
#'   \item \code{\link{build_design_components}}: Generate content, AI components, and ethical frameworks
#'   \item \code{\link{build_design_system}}: Complete CSS compilation pipeline from design tokens to production assets
#' }
#'
#' ### Application Development Tools
#' \itemize{
#'   \item \code{\link{create_quarto_documentation}}: Generate professional documentation
#'     websites with consistent branding and ethical AI annotations
#'   \item \code{\link{create_ui_workspace}}: Set up Node.js development environment
#'     with modern web tooling
#'   \item Multi-platform deployment to Quarto extensions, CDN, and Next.js applications
#' }
#'
#' ### Design System & Asset Management
#' \itemize{
#'   \item **Design Tokens**: JSON-based design system with CSS custom properties
#'   \item **SCSS Compilation**: Style Dictionary + Sass pipeline for consistent styling
#'   \item **CDN Distribution**: jsDelivr-ready assets with SRI hashes for security
#'   \item **Visual Identity**: SVG-based logos with automatic theme switching
#' }
#'
#' ### Framework Documentation (`inst/dataimago/`)
#' \itemize{
#'   \item **01_Foundations/**: Framework philosophy and governance principles
#'   \item **02_Manifesto/**: Ethical AI approach and paradigm differentiation
#'   \item **03_Application_Architecture/**: Technical implementation patterns and best practices
#'   \item **04_dataimago_Content/**: Complete design system assets and branding guidelines
#' }
#'
#' ## AI-Native Development Features
#'
#' This framework is designed from the ground up for both human developers and AI agents:
#'
#' ### MCP-Compatible Tooling
#' \itemize{
#'   \item **Structured APIs**: All functions use consistent parameter patterns and return structured results
#'   \item **Comprehensive Documentation**: Detailed roxygen2 docs with examples and error handling
#'   \item **Machine-Readable Outputs**: JSON-compatible results for programmatic consumption
#'   \item **Agent Context Files**: `inst/CLAUDE.md` and `inst/AGENT_INDEX.md` provide persistent AI context
#' }
#'
#' ### Rapid Development Workflow
#' \itemize{
#'   \item **One-Command Setup**: `create_ui_workspace()` initializes complete development environment
#'   \item **Automated Asset Pipeline**: `build_design_system()` handles design token compilation to production CSS
#'   \item **Multi-Platform Deployment**: Single source generates assets for Quarto, Shiny, Next.js, and CDN
#'   \item **Consistent Branding**: Automatic application of design system and ethical AI principles
#' }
#'
#' ### AI Agent Integration
#' Framework functions are optimized for AI-driven development:
#' \itemize{
#'   \item **Deterministic Operations**: Same inputs always produce same outputs
#'   \item **Clear Error Messages**: Detailed failure information for debugging and remediation
#'   \item **Incremental Builds**: Smart dependency detection avoids unnecessary rebuilds
#'   \item **Validation Pipelines**: Built-in checks ensure output quality and consistency
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
#' ## Quick Start - Application Development Workflow
#'
#' Set up development environment and build your first application:
#' \preformatted{
#' library(dataimago)
#'
#' # 1. Initialize development workspace
#' create_ui_workspace()
#'
#' # 2. Build design system assets
#' result <- build_design_system()
#'
#' # 3. Generate professional documentation
#' create_quarto_documentation()
#'
#' # 4. Deploy to multiple platforms
#' # - Quarto extension: Available automatically
#' # - CDN assets: Available via jsDelivr
#' # - Next.js: Use generated tailwind-preset.js
#' }
#'
#' Access framework documentation (planned):
#' \preformatted{
#' get_foundation_document("architecture_patterns")
#' get_design_system_tokens("colors")
#' }
#'
#' Generate application scaffolding (planned):
#' \preformatted{
#' create_dataimago_app(name = "my-data-app", type = "quarto+shiny")
#' scaffold_nextjs_integration(path = "my-project")
#' }
#'
#' @section Package Metadata:
#' \itemize{
#'   \item **Version**: 0.0-3.0 (using dataimago semantic versioning)
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
