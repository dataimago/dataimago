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
#'   \item \code{\link{ai}}: Meta-orchestration entry point. In 0.0-4.x only
#'     \code{mode = "remote"} is wired; the in-package local scaffolders
#'     were retired alongside the \code{ui/src/dataimago-design/} submodule.
#'   \item \code{\link{build_design_components}}: Run the R \eqn{\to} API \eqn{\to}
#'     MCP \eqn{\to} TypeScript meta-tool pipeline against an existing project.
#'   \item \code{\link{build_design_system}}: Consume the \code{@dataimago/*}
#'     packages from \code{ui/node_modules} and fan built assets out to
#'     \code{inst/quarto-assets/}, \code{ui/www/}, and \code{docs/}.
#' }
#'
#' ### Application Development Tools
#' \itemize{
#'   \item \code{\link{create_quarto_documentation}}: Generate a branded
#'     Quarto reference site from the package's \code{.Rd} files with
#'     ethical AI annotations.
#'   \item \code{\link{generate_ai_context}}: Produce Repomix-style AI
#'     context artifacts that cover \code{R/}, \code{man/}, \code{inst/},
#'     and the UI consumer layer.
#'   \item Multi-platform deployment to Quarto extensions, CDN, and Next.js applications
#' }
#'
#' ### Design System & Asset Management
#' \itemize{
#'   \item **Design Tokens**: Sourced from the \code{@dataimago/tokens} npm
#'     package (JSON + CSS custom properties + TS modules)
#'   \item **Compiled CSS**: Shipped by \code{@dataimago/css}
#'     (\code{dataimago.css}, \code{dataimago.min.css}, \code{tailwind-preset.js})
#'   \item **CDN Distribution**: jsDelivr-ready assets with SRI hashes served from
#'     \code{inst/quarto-assets/}
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
#'   \item **Package-Channel Bootstrap**: `pnpm install` under `ui/` fetches
#'     `@dataimago/tokens`, `@dataimago/css`, and `@dataimago/ui` from
#'     public npm (scoped via `ui/.npmrc`; no auth token required)
#'   \item **Automated Asset Pipeline**: `build_design_system()` runs
#'     `ui/build.js`, which redistributes the installed packages into
#'     `ui/dist/`, `inst/quarto-assets/`, and `docs/`
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
#' Set up the UI consumer layer and rebuild branded assets:
#' \preformatted{
#' library(dataimago)
#'
#' # 1. Install the design-system packages (one-time; no auth token
#' #    required — all @dataimago/* packages ship from public npm)
#' #    Run this in a shell from the package root:
#' #      cd ui && pnpm install
#'
#' # 2. Build design system assets (copies node_modules/@dataimago/*
#' #    into ui/dist/ and fans out to inst/, docs/, ui/www/)
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
