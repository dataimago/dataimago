# dataimago R Functions

This directory contains the core R functions that implement dataimago's ethical AI framework and R-first design system.

## Core Modules

### 📚 `documentation_utils.R`
**Ethical AI Documentation Generation**

Functions for converting R package documentation into Quarto websites with embedded philosophical context:

- **`create_quarto_documentation()`** - Master function for generating comprehensive API documentation
- **`parse_description_file()`** - Extract and format package metadata
- **`convert_rd_files_to_qmd()`** - Convert .Rd files using Rd2md with dataimago customizations
- **`post_process_md_to_qmd()`** - Inject ethical AI annotations into documentation
- **`update_dataimago_assets()`** - Manage visual identity and branding assets

### 🎨 `design_system.R`
**R-First CSS Build Pipeline**

Functions that wrap modern CSS build tools (Style Dictionary, Sass, PostCSS) in well-documented R functions:

- **`create_ui_workspace()`** - Set up Node.js workspace with design tokens and SCSS source
- **`build_design_system()`** - Master build function orchestrating CSS compilation
- **`update_quarto_extension()`** - Copy built assets to Quarto extension structure
- **`generate_cdn_assets()`** - Prepare assets for CDN distribution with SRI hashes

## Philosophy

### Code-as-Philosophy Commitments

Every function in this directory embodies dataimago's core principles:

- **R as Source of Truth**: Developers never need to leave R or learn Node.js tooling
- **Hermeneutic Transparency**: All system calls are documented with clear explanations
- **Ethical Reflexivity**: Functions include philosophical context about their purpose
- **Structured Outputs**: Return values are designed for both human and AI consumption

### Documentation Standards

All functions follow consistent patterns:
- **Comprehensive `@details`** sections explaining both technical and philosophical context
- **Clear `@param`** documentation with default values and validation
- **Structured `@return`** values as lists with success indicators and metadata
- **Working `@examples`** that demonstrate both basic and advanced usage
- **Error handling** with informative messages and suggested remediation

### MCP Tool Integration

Functions are designed for Model Context Protocol (MCP) integration:
- **Deterministic outputs** for AI reasoning
- **Machine-readable metadata** in return values  
- **Clear success/failure indicators** for automated workflows
- **Contextual error messages** for debugging assistance

## Usage Patterns

### Basic Workflow
```r
# 1. Generate documentation with ethical context
create_quarto_documentation()

# 2. Set up CSS build environment (one-time)
create_ui_workspace()

# 3. Compile design system assets
build_design_system(verbose = TRUE)
```

### Development Workflow
```r
# Check function results programmatically
result <- build_design_system(verbose = FALSE)
if (result$success) {
  cat("Built", length(result$assets), "assets")
} else {
  stop("Build failed:", paste(result$errors, collapse = "; "))
}
```

### AI Agent Integration
```r
# Structured output for AI reasoning
doc_result <- create_quarto_documentation(
  include_foundation_links = TRUE,
  template = "dataimago"
)

# AI can parse the metadata
metadata <- doc_result$metadata
philosophical_context <- doc_result$foundation_links
```

## Dependencies

This module requires several R packages:
- **Core**: `fs`, `processx`, `jsonlite`, `digest`, `usethis`
- **Documentation**: `Rd2md`, `tools`, `crayon`, `glue` 
- **Optional**: `quarto` (for website rendering)

And Node.js tools (managed automatically):
- **pnpm/npm** for package management
- **Style Dictionary** for design token processing
- **Sass** for SCSS compilation
- **PostCSS** with autoprefixer and cssnano

## Future Enhancements

Planned additions include:
- **`get_foundation_document()`** - Programmatic access to philosophical content
- **`create_dataimago_app()`** - Generate application skeletons
- **`bootstrap_emancipatory_framework()`** - Initialize projects with ethical foundations
- **SRI hash validation** for CDN security
- **Automated GitHub Actions** integration for CI/CD