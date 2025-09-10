# dataimago: AI-Native Web-Application Development Framework for Data Science

<!-- badges: start -->

<!-- Core Package Status -->
[![Comprehensive Tests](https://github.com/dataimago/dataimago/workflows/Comprehensive%20Test%20Suite/badge.svg)](https://github.com/dataimago/dataimago/actions)
[![Quarto Deploy](https://github.com/dataimago/dataimago/workflows/Deploy%20Quarto%20Website/badge.svg)](https://github.com/dataimago/dataimago/actions)
[![Dependencies](https://github.com/dataimago/dataimago/workflows/Dependency%20Management/badge.svg)](https://github.com/dataimago/dataimago/actions)

<!-- Package Information -->
[![CRAN status](https://www.r-pkg.org/badges/version/dataimago)](https://CRAN.R-project.org/package=dataimago)
[![R Version](https://img.shields.io/badge/R-%E2%89%A5%204.1.0-blue.svg)](https://cran.r-project.org/)
[![Package Version](https://img.shields.io/badge/Version-0.0--0.3-brightgreen.svg)](https://github.com/dataimago/dataimago)

<!-- Technical Architecture -->
[![Node.js Version](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![Design System](https://img.shields.io/badge/Design%20System-Ethical%20AI-purple.svg)](ui/README.md)
[![CDN Ready](https://img.shields.io/badge/CDN-jsDelivr%20Ready-orange.svg)](https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@main/inst/quarto-assets/)

<!-- Philosophy & Standards -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Code Style](https://img.shields.io/badge/Code%20Style-140%20chars-lightblue.svg)](.lintr)
[![Accessibility](https://img.shields.io/badge/Accessibility-WCAG%20AA-green.svg)](ui/README.md#ethical-ai-features)
[![Ethical AI](https://img.shields.io/badge/Framework-Emancipatory%20AI-red.svg)](ARCHITECTURE.md)

<!-- badges: end -->

![dataimago Logo](inst/dataimago/04_dataimago_Content/Design_Assets/logos/dataimago.png)

## Overview

**dataimago** is a comprehensive development framework that accelerates the creation of data science web applications for both human developers and AI agents. It provides complete design system compilation, multi-platform deployment (Quarto, Shiny, Next.js), MCP-compatible tooling, and embedded ethical AI principles. Features R-first workflows that wrap modern web development tools in familiar interfaces, enabling rapid application scaffolding with consistent branding and best practices.

### Vision

To become the most transformative AI organization of the 21st century, aligning superintelligence with human emancipation, and using flow-based performance management to reshape how societies learn, heal, grow, and govern.

### Mission

To develop AI systems and analytic tools that reconcile meaning (hermeneutics) and measurement (positivism) in ways that reduce human suffering and enable agency at all levels of society—from individuals to high level policy makers.

## 🏗️ Package Architecture

The dataimago R package is designed as a **multi-layered foundation** for emancipatory AI development. Understanding the architecture is crucial for effective development and maintenance.

> 📋 **See [ARCHITECTURE.md](ARCHITECTURE.md) for comprehensive Mermaid diagrams** that visualize the complete system architecture, build processes, and philosophical integration patterns.

### System Overview

```mermaid
graph TB
    %% Main Package Architecture Overview
    subgraph "R Package Core"
        RP[dataimago Package]
        RF[R Functions]
        RF --> DOC[documentation_utils.R]
        RF --> DS[design_system.R]
        RF --> PKG[dataimago-package.R]
    end

    subgraph "Foundation Layer"
        INST[inst/ Directory]
        INST --> FOUND[dataimago/ Foundations]
        INST --> CDN[quarto-assets/ CDN]
        FOUND --> PHIL[Philosophy & Mission]
        FOUND --> ARCH[Architecture Blueprints]
        FOUND --> ASSETS[Design Assets]
    end

    subgraph "Design System"
        UI[ui/ Node.js Workspace]
        UI --> TOKENS[src/tokens/ JSON]
        UI --> SCSS[src/styles/ SCSS]
        UI --> DIST[dist/ Built Assets]
        
        TOKENS --> SD[Style Dictionary]
        SCSS --> SASS[Sass Compiler]
        SD --> PROPS[CSS Custom Properties]
        SASS --> CSS[Compiled CSS]
        CSS --> POST[PostCSS Optimization]
        POST --> DIST
    end

    subgraph "Distribution Channels"
        DIST --> CDN
        DIST --> EXT[_extensions/ Quarto]
        DIST --> NEXT[Next.js Integration]
    end

    subgraph "Documentation System"
        DOC --> QMD[Quarto Website]
        QMD --> API[API Reference]
        QMD --> FOUNDATIONS[Foundation Docs]
        QMD --> GUIDES[Development Guides]
    end

    subgraph "CI/CD Pipeline"
        GH[GitHub Actions]
        GH --> TEST[Multi-platform Testing]
        GH --> BUILD[Automated Builds]
        GH --> DEPLOY[Website Deployment]
        GH --> RELEASE[CDN Releases]
    end

    %% Connections
    RP --> INST
    RP --> UI
    RF --> QMD
    DS --> UI
    CDN --> JSDELIVR[jsDelivr CDN]
    EXT --> QUARTO[External Quarto Sites]
    NEXT --> APPS[Next.js Applications]

    %% Styling
    classDef rCore fill:#3498db,stroke:#2c3e50,stroke-width:2px,color:#fff
    classDef foundation fill:#e74c3c,stroke:#c0392b,stroke-width:2px,color:#fff
    classDef designSystem fill:#2ecc71,stroke:#27ae60,stroke-width:2px,color:#fff
    classDef distribution fill:#f39c12,stroke:#e67e22,stroke-width:2px,color:#fff
    classDef documentation fill:#9b59b6,stroke:#8e44ad,stroke-width:2px,color:#fff
    classDef cicd fill:#1abc9c,stroke:#16a085,stroke-width:2px,color:#fff

    class RP,RF,DOC,DS,PKG rCore
    class INST,FOUND,PHIL,ARCH,ASSETS foundation
    class UI,TOKENS,SCSS,DIST,SD,SASS,PROPS,CSS,POST designSystem
    class CDN,EXT,NEXT,JSDELIVR,QUARTO,APPS distribution
    class QMD,API,FOUNDATIONS,GUIDES documentation
    class GH,TEST,BUILD,DEPLOY,RELEASE cicd
```

### Directory Structure
```
dataimago/
├── R/                           # Core R functions
│   ├── dataimago-package.R      # Package documentation and exports
│   ├── documentation_utils.R    # Quarto documentation generation
│   └── design_system.R         # CSS build system (R-first)
├── inst/                       # Installed package assets
│   ├── dataimago/              # Foundation documents and assets
│   └── quarto-assets/          # CDN-ready CSS files (CRITICAL)
├── ui/                         # Node.js design system workspace
│   ├── src/                    
│   │   └── dataimago-design/   # Git submodule - SOURCE OF TRUTH
│   │       ├── src/
│   │       │   ├── tokens/     # JSON design tokens (colors, typography, etc.)
│   │       │   ├── styles/     # SCSS source files with proper imports
│   │       │   └── js/         # JavaScript modules
│   │       └── packages/       # npm workspace packages
│   ├── dist/                   # Built CSS assets (regenerable)
│   ├── build.js               # Build script adapted for submodule paths
│   └── package.json           # Node.js dependencies
├── ui/www/                    # Complete Quarto website structure
│   ├── _extensions/           # dataimago Quarto extension
│   ├── assets/               # Website-specific assets
│   └── *.qmd                 # Quarto content files
├── man/                      # R documentation (.Rd files)
└── .github/workflows/        # CI/CD automation
```

### 🔄 Build Flow & Dependencies

The package uses a sophisticated build system that maintains "R as source of truth" while leveraging modern web tooling. **Recent Update**: Established complete SCSS source-of-truth pipeline eliminating 404 errors and enabling confident asset management.

```mermaid
flowchart TD
    %% Design System Build Process
    START([Developer Initiates Build])
    
    subgraph "Input Sources"
        TOKENS[Design Tokens<br/>ui/src/tokens/*.json]
        SCSS[SCSS Styles<br/>ui/src/styles/*.scss]
        CONFIG[Build Configuration<br/>package.json, build.js]
    end

    subgraph "R Interface"
        WORKSPACE[create_ui_workspace<br/>Sets up Node.js environment]
        BUILD[build_design_system<br/>Orchestrates entire pipeline]
        DETECT{Sophisticated<br/>system exists?}
    end

    subgraph "Node.js Processing Pipeline"
        SD[Style Dictionary<br/>Token Processing]
        SASS_COMP[Sass Compiler<br/>SCSS → CSS]
        POSTCSS[PostCSS Pipeline<br/>Optimization]
        
        SD --> CUSTOM_PROPS[CSS Custom Properties]
        SASS_COMP --> COMPILED_CSS[Compiled CSS]
        POSTCSS --> MINIFIED[Minified CSS]
    end

    subgraph "Output Destinations"
        DIST[ui/dist/<br/>Development Assets]
        CDN_ASSETS[inst/quarto-assets/<br/>CDN Distribution]
        QUARTO_EXT[_extensions/<br/>Quarto Extension]
        NEXT_PRESET[tailwind-preset.js<br/>Next.js Integration]
    end

    subgraph "Distribution Channels"
        JSDELIVR[jsDelivr CDN<br/>External Projects]
        QUARTO_SITES[Quarto Websites<br/>Extension Usage]
        NEXTJS_APPS[Next.js Apps<br/>Preset Integration]
        R_PACKAGE[R Package<br/>system.file access]
    end

    %% Flow connections
    START --> BUILD
    BUILD --> DETECT
    DETECT -->|Yes| EXISTING[Use Existing System]
    DETECT -->|No| WORKSPACE
    WORKSPACE --> CREATE_MINIMAL[Create Minimal Fallback]
    EXISTING --> TOKENS
    CREATE_MINIMAL --> TOKENS
    
    TOKENS --> SD
    SCSS --> SASS_COMP
    CONFIG --> SD
    CONFIG --> SASS_COMP
    
    CUSTOM_PROPS --> POSTCSS
    COMPILED_CSS --> POSTCSS
    
    MINIFIED --> DIST
    DIST --> CDN_ASSETS
    DIST --> QUARTO_EXT
    DIST --> NEXT_PRESET
    
    CDN_ASSETS --> JSDELIVR
    CDN_ASSETS --> R_PACKAGE
    QUARTO_EXT --> QUARTO_SITES
    NEXT_PRESET --> NEXTJS_APPS

    %% Decision flows
    DETECT -->|Force Rebuild| WORKSPACE

    %% Styling
    classDef input fill:#3498db,stroke:#2c3e50,stroke-width:2px,color:#fff
    classDef rInterface fill:#e74c3c,stroke:#c0392b,stroke-width:2px,color:#fff
    classDef processing fill:#2ecc71,stroke:#27ae60,stroke-width:2px,color:#fff
    classDef output fill:#f39c12,stroke:#e67e22,stroke-width:2px,color:#fff
    classDef distribution fill:#9b59b6,stroke:#8e44ad,stroke-width:2px,color:#fff
    classDef decision fill:#1abc9c,stroke:#16a085,stroke-width:2px,color:#fff

    class TOKENS,SCSS,CONFIG input
    class WORKSPACE,BUILD,EXISTING,CREATE_MINIMAL rInterface
    class SD,SASS_COMP,POSTCSS,CUSTOM_PROPS,COMPILED_CSS,MINIFIED processing
    class DIST,CDN_ASSETS,QUARTO_EXT,NEXT_PRESET output
    class JSDELIVR,QUARTO_SITES,NEXTJS_APPS,R_PACKAGE distribution
    class DETECT decision
```

**Distribution Channels:**
- `ui/dist/` → Build artifacts (with source maps for development)
- `inst/quarto-assets/` → CDN distribution via jsDelivr 
- `_extensions/.../assets/` → Quarto extension packaging

### ⚠️ Critical Directories

**NEVER DELETE THESE:**
- `inst/quarto-assets/` - Enables CDN access via jsDelivr
- `ui/src/` - Source design tokens and SCSS files
- `_extensions/dataimago/ai-native/` - Quarto extension distribution

**OK TO REGENERATE:**
- `ui/dist/` - Build outputs (regenerated by build_design_system())
- `ui/node_modules/` - Dependencies (regenerated by pnpm install)

## Key Features

### ⚡ Rapid Application Development
- **`create_ui_workspace()`**: One-command setup for complete Node.js development environment
- **`build_design_system()`**: Automated CSS compilation from design tokens to production assets
- **`create_quarto_documentation()`**: Generate professional documentation with consistent branding
- **Multi-Platform Deployment**: Single source generates assets for Quarto, Shiny, Next.js, and CDN

### 🎨 Complete Design System
- **Design Tokens**: JSON-based system with CSS custom properties for consistent styling
- **SCSS Pipeline**: Style Dictionary + Sass compilation with PostCSS optimization  
- **SVG Visual Identity**: Theme-aware logos with automatic light/dark mode switching
- **WCAG AA Compliance**: Built-in accessibility with reduced motion and high contrast support

### 🤖 AI-Native Architecture
- **MCP-Compatible Functions**: Structured APIs designed for AI agent consumption
- **Deterministic Operations**: Reproducible builds with comprehensive error handling
- **Machine-Readable Outputs**: JSON-compatible results for programmatic integration
- **Agent Context Files**: Persistent AI context and coordination capabilities

### 🚀 Multi-Platform Distribution
- **CDN Assets**: jsDelivr-ready files with SRI hashes for global distribution
- **Quarto Extensions**: Complete `dataimago/ai-native` extension for documentation sites
- **Next.js Integration**: Generated Tailwind presets for seamless web application development
- **R Package Access**: Built-in asset management via `system.file()` for Shiny applications

### 📋 Framework Documentation
- **Architecture Patterns**: Technical blueprints and implementation best practices
- **Ethical AI Guidelines**: Embedded principles for human-centered development
- **Design System Guide**: Complete visual identity and branding specifications  
- **Development Workflows**: Step-by-step guidance for rapid application creation

### 🌐 Distribution Channels
- **`inst/quarto-assets/`**: CDN-ready files accessible via jsDelivr (external projects)
- **`_extensions/dataimago/ai-native/`**: Complete Quarto extension with filters and shortcodes  
- **`ui/dist/`**: Development assets with source maps and build metadata

### 🏗️ CDN Architecture
- **Template Assets**: `https://cdn.jsdelivr.net/gh/dataimago/dataimago@main/inst/quarto-assets/`
- **Package Assets**: Individual packages use own CDN for hex logos and custom styling
- **Hybrid Strategy**: Consistent branding + unique package identity
- **SVG Logo System**: Theme-aware switching with 4 variants per logo type (8 total SVG assets)

## Installation

```r
# Install from GitHub (when available)
# devtools::install_github("dataimago/dataimago")

# For development
devtools::load_all()
```

### Git Submodule Setup

The design system is managed as a git submodule. When cloning for development:

```bash
# Clone with submodules
git clone --recursive https://github.com/dataimago/dataimago-rpkg

# OR if already cloned, initialize submodules
git submodule update --init --recursive
```

## Quick Start - Application Development Workflow

### Complete Setup and First Build

```r
library(dataimago)

# 1. Initialize development workspace (one-time setup)
create_ui_workspace()

# 2. Build complete design system (UPDATED: now with SCSS source-of-truth)
result <- build_design_system(verbose = TRUE)

# 3. Generate professional documentation
create_quarto_documentation()

# Check results
if (result$success) {
  cat("✅ Framework ready! Generated", length(result$assets), "assets")
  cat("🔐 Security: SRI hashes generated") 
  cat("🚀 Deploy: Assets available for Quarto, Shiny, Next.js")
  cat("✅ Source-of-Truth: All changes in /ui/src/ propagate automatically")
}
```

### Development Workflow

```r
# Rapid iteration during development
build_design_system(force_rebuild = FALSE)  # Smart incremental builds

# Deploy updates to all platforms
build_design_system(update_extension = TRUE)  # Update Quarto extension
# CDN assets automatically updated via GitHub releases
```

### ✅ Confident Asset Management Workflow

**The following workflow now works end-to-end:**

```r
# 1. EDIT SOURCE FILES in /ui/src/
#    - Modify design tokens: ui/src/tokens/*.json
#    - Update styles: ui/src/styles/*.scss
#    - Adjust theme colors: ui/src/styles/themes/theme-variables.scss

# 2. RUN BUILD SYSTEM from R
result <- build_design_system(verbose = TRUE)

# 3. AUTOMATIC PROPAGATION to all deployment targets:
#    ✅ ui/dist/ (compiled development assets)
#    ✅ ui/www/assets/css/ (website development)  
#    ✅ ui/www/_extensions/dataimago/ai-native/assets/css/ (Quarto extension)
#    ✅ inst/quarto-assets/ (CDN distribution)
#    ✅ docs/ (rendered website)

# 4. NO BREAKAGE - Quarto render/preview work without 404 errors
```

**Key Achievement**: Fixed SCSS import chain eliminates runtime CSS import requests that caused 404 errors. Now everything compiles properly and distributes automatically.

### Deploy Design System

**Quarto Extension (Recommended):**
```yaml
# _quarto.yml
format:
  html:
    theme: dataimago/ai-native
```

**CDN Distribution:**
```yaml
# _quarto.yml
format:
  html:
    css:
      - https://cdn.jsdelivr.net/gh/dataimago/dataimago@main/inst/quarto-assets/dataimago.min.css
```

**Next.js Integration:**
```js
// tailwind.config.js
module.exports = {
  presets: [require('./ui/dist/tailwind-preset.js')]
};
```

### Application Scaffolding (Planned)

```r
# Generate complete application skeletons
# create_dataimago_app(name = "my-data-dashboard", type = "quarto+shiny")
# scaffold_nextjs_integration(path = "my-web-app")

# Access framework documentation
# get_architecture_pattern("data_visualization_best_practices")
# get_design_system_tokens("spacing", "colors")
```

## Package Structure

```
dataimago/
├── R/                          # Core functions
│   ├── documentation_utils.R   # Documentation generation
│   └── design_system.R         # R-first CSS build pipeline
├── ui/                         # Complete frontend development workspace
│   ├── src/
│   │   └── dataimago-design/   # Git submodule - design system repository
│   │       ├── src/
│   │       │   ├── tokens/     # Design tokens (JSON) - SOURCE OF TRUTH
│   │       │   ├── styles/     # SCSS source files - SOURCE OF TRUTH
│   │       │   └── js/         # JavaScript modules - SOURCE OF TRUTH
│   │       └── packages/       # npm workspace packages
│   ├── dist/                   # Built CSS assets (regenerable)
│   └── www/                    # Quarto website project
│       └── _extensions/dataimago/ai-native/ # Quarto extension
├── inst/
│   ├── dataimago/              # Complete foundation documents
│   │   ├── 01_Foundations/     # Mission, vision, philosophy
│   │   ├── 02_Manifesto/       # Critical theory content
│   │   ├── 03_Application_Architecture/
│   │   └── 04_dataimago_Content/ # Design assets
│   ├── quarto-assets/          # CDN-ready assets
│   ├── CLAUDE.md               # AI agent context
│   └── AGENT_INDEX.md          # Agent coordination

├── docs/                       # Rendered website
├── man/                        # Generated documentation
└── tests/                      # Package tests
```

## Documentation

- **Package Website**: [https://dataimago.github.io/dataimago/](https://dataimago.github.io/dataimago/)
- **API Reference**: Complete function documentation with ethical context
- **Foundation Documents**: Philosophical frameworks and architectural blueprints
- **Design System Guide**: Detailed implementation notes in `docs/development/`
- **Vignettes**: Long-form tutorials and conceptual guides

## Framework Philosophy

dataimago embeds ethical AI principles and consistent development patterns directly into the framework architecture. Rather than requiring developers to manually implement best practices, the framework provides pre-built components, automated tooling, and structured workflows that ensure applications are scalable, accessible, and aligned with human flourishing.

### Development Principles

- **R-First Workflows**: Familiar interfaces wrapping modern web development tools
- **Consistency by Default**: Automated application of design systems and best practices
- **AI-Native Design**: Built for both human developers and AI agent collaboration
- **Multi-Platform Thinking**: Single source generates assets for all deployment targets
- **Ethical Foundation**: Human-centered development embedded throughout the framework

## AI-Native Development Features

This framework is designed from the ground up for both human developers and AI agents:

### MCP-Compatible Tooling
- **Structured APIs**: All functions use consistent parameter patterns and return structured results
- **Comprehensive Documentation**: Detailed roxygen2 docs with examples and error handling
- **Machine-Readable Outputs**: JSON-compatible results for programmatic consumption
- **Agent Context Files**: `inst/CLAUDE.md` and `inst/AGENT_INDEX.md` provide persistent AI context

### AI-Optimized Workflows
- **Deterministic Operations**: Same inputs always produce same outputs
- **Clear Error Messages**: Detailed failure information for debugging and remediation
- **Incremental Builds**: Smart dependency detection avoids unnecessary rebuilds
- **Validation Pipelines**: Built-in checks ensure output quality and consistency

### Example MCP Tool Integration
```json
{
  "name": "build_design_system",
  "description": "Compile complete CSS design system for multi-platform deployment",
  "parameters": {
    "force_rebuild": "Force rebuild even if assets appear up-to-date",
    "include_sri": "Generate SRI hashes for CDN distribution", 
    "update_extension": "Update Quarto extension with compiled assets",
    "verbose": "Print detailed progress information"
  },
  "returns": {
    "success": "Boolean indicating overall build success",
    "assets": "Array of generated asset file paths",
    "sri_hashes": "Object containing SRI hashes for each CSS file",
    "build_time": "ISO timestamp of build completion"
  }
}
```

## AI-Powered Development with Repomix

The dataimago package integrates [Repomix](https://repomix.com) to enhance AI-assisted development workflows. Repomix packages the entire codebase into a single, AI-friendly file that provides complete context for Large Language Models (LLMs).

### What is Repomix?

Repomix is a tool that consolidates repository contents into a structured format optimized for AI consumption. This enables:
- **Complete Context**: AI assistants understand the entire codebase architecture
- **Philosophical Alignment**: Foundation documents are included for value-aligned suggestions
- **Efficient Collaboration**: Single file upload provides comprehensive project knowledge
- **Token Optimization**: Smart exclusion of build artifacts keeps token usage manageable

### Quick Start

Generate an AI-readable package of the codebase:

```bash
# From repository root
npx repomix@latest

# Output: repomix-output.xml containing the packaged codebase
```

### Configuration

The `.repomixignore` file is configured to:
- **Include**: Core R functions, foundation documents, design sources, documentation
- **Exclude**: Build artifacts (`ui/dist/`, `node_modules/`), git metadata, binary files

### Usage Examples

#### Code Review & Architecture Analysis
```
This file contains the dataimago R package codebase.
Review the architecture and suggest improvements aligned with 
the philosophical principles in inst/dataimago/ and CLAUDE.md.
```

#### Function Implementation
```
Based on existing patterns in R/ and philosophy in inst/dataimago/,
implement the planned function get_foundation_document() for
programmatic access to philosophical content.
```

#### Documentation Generation
```
Using function documentation in man/ and philosophical context
in inst/dataimago/, generate vignettes connecting technical
implementation to ethical foundations.
```

### Integration with AI Workflows

- **Claude Projects**: Upload `repomix-output.xml` to project knowledge base
- **ChatGPT**: Include in conversation for comprehensive context
- **GitHub Copilot**: Use as context file for enhanced suggestions
- **Local LLMs**: Feed complete codebase for offline development

### Best Practices

1. **Regenerate after significant changes**: `npx repomix@latest`
2. **Monitor token usage**: `npx repomix@latest --include-token-count`
3. **Security checks**: `npx repomix@latest --check-security`
4. **Custom output**: `npx repomix@latest --output dataimago-context.xml`

For detailed integration guidance, see [REPOMIX_INTEGRATION.md](REPOMIX_INTEGRATION.md).

## Development Status

### ✅ Phase 1: Foundation (COMPLETE)
- Package structure and metadata
- Foundation document organization
- Content curation via `.Rbuildignore`
- MIT licensing and proper attribution

### ✅ Phase 2: Documentation Generation (COMPLETE)
- `create_quarto_documentation()` function
- Rd2md integration for .Rd → .qmd conversion
- Philosophical context injection
- Complete Quarto website generation

### ✅ Phase 3: R-First Design System (COMPLETE)
- `create_ui_workspace()` - Node.js workspace setup
- `build_design_system()` - **FIXED**: Complete SCSS compilation with proper imports
- `update_quarto_extension()` - Extension asset management  
- `generate_cdn_assets()` - Multi-platform distribution
- **✅ Source-of-Truth Architecture**: Fixed 404 errors, established `/ui/src/` as authoritative
- **✅ Asset Propagation**: Single source → multiple deployment targets working perfectly

### ✅ Phase 4: CI/CD Automation (COMPLETE)
- **Multi-platform testing**: R CMD check across Windows, macOS, Linux
- **Automated CDN releases**: jsDelivr distribution via git tags
- **Website deployment**: GitHub Pages with Quarto rendering
- **Dependency monitoring**: Security scanning and update automation

### 🔄 Phase 5: Foundation Access Functions (PLANNED)
- `get_foundation_document()` - Programmatic access to philosophical content
- `create_dataimago_app()` - Generate application skeletons
- `bootstrap_emancipatory_framework()` - Initialize projects with ethical foundations

## Contributing

This package embodies ethical AI development principles. Contributions should:

1. **Align with Philosophy**: All additions must serve emancipatory goals
2. **Include Ethical Context**: New functions require philosophical documentation
3. **Maintain Transparency**: Implementation assumptions must be documented
4. **Test Thoroughly**: Both technical functionality and philosophical consistency

### Code Style

The package uses a configured linter (`.lintr`) with these standards:
- **Line Length**: 140 characters (accommodates comprehensive documentation)
- **Object Names**: Up to 40 characters (descriptive function names encouraged)
- **Standard R Style**: Consistent spacing, indentation, and naming conventions
- **Documentation Focus**: Optimized for packages with extensive ethical context

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.

## Citation

```r
citation("dataimago")
```

## Contact

- **Website**: [https://dataimago.github.io/dataimago/](https://dataimago.github.io/dataimago/)
- **Issues**: [https://github.com/dataimago/dataimago/issues/](https://github.com/dataimago/dataimago/issues/)
- **Maintainer**: Damian W. Betebenner <dbetebenner@gmail.com>

---

*"Would this object help an AI understand, improve, or operationalize emancipatory thinking? If yes, it belongs."* - dataimago development philosophy
