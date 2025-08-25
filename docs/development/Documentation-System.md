# dataimago R Documentation

This directory contains R documentation (.Rd) files generated automatically by roxygen2 from the R source code. These files provide the foundation for both R's built-in help system and the enhanced Quarto documentation.

## 📚 Documentation Philosophy

### Dual-Mode Documentation
dataimago maintains documentation that serves both:
1. **R developers** - Standard R help accessed via `?function_name`
2. **Web users** - Rich Quarto websites with ethical AI context

### Ethical AI Integration
Every function includes:
- **Technical documentation** - Parameters, return values, examples
- **Philosophical context** - Why the function exists and its ethical implications  
- **MCP compatibility** - Structured for AI agent consumption
- **Cross-references** - Links to foundation documents and related functions

## 🔧 Generated Files

### Documentation Generation Functions
- **`create_quarto_documentation.Rd`** - Master documentation generator
- **`parse_description_file.Rd`** - DESCRIPTION file processing
- **`convert_rd_files_to_qmd.Rd`** - .Rd to Quarto conversion
- **`post_process_md_to_qmd.Rd`** - Ethical AI annotation injection

### Design System Functions
- **`build_design_system.Rd`** - R-first CSS build pipeline
- **`create_ui_workspace.Rd`** - Node.js workspace setup
- **`update_quarto_extension.Rd`** - Extension asset management
- **`generate_cdn_assets.Rd`** - CDN distribution preparation

### Package Documentation
- **`dataimago-package.Rd`** - Package overview and philosophy

## 🌐 Enhanced Web Documentation

### Conversion Process
1. **Roxygen2** generates standard .Rd files from R source comments
2. **`create_quarto_documentation()`** converts .Rd → .qmd with enhancements:
   - Philosophical context boxes
   - Links to foundation documents
   - dataimago branding and styling
   - MCP-compatible metadata

### Web Output Features
- **Ethical AI annotations** on every function
- **Cross-references** to philosophical foundations  
- **Visual consistency** with dataimago design system
- **Accessibility compliance** (WCAG AA)
- **Mobile responsiveness** for all devices

## 📖 Documentation Standards

### Required Sections
Each function must include:
```r
#' @param parameter_name Description with validation and defaults
#' @return List or object description with structure details
#' @details Extended description including philosophical context
#' @examples Working examples showing real usage
#' @seealso Related functions and cross-references
#' @keywords Topical keywords for discoverability
#' @concept Conceptual tags for philosophical grouping
```

### Ethical Context Requirements
Every exported function includes:
- **Purpose statement** - Why this function exists
- **Ethical implications** - How it serves emancipatory goals
- **System interactions** - Documented external dependencies
- **AI agent guidance** - MCP integration considerations

## 🤖 MCP Tool Compatibility

### Structured Metadata
Documentation includes machine-readable elements:
- **Parameter schemas** with validation rules
- **Return value structures** with type information
- **Error conditions** with remediation guidance
- **Usage patterns** for common scenarios

### AI Agent Integration
Functions provide AI-friendly features:
- **Consistent naming** conventions across all functions
- **Structured outputs** (lists with success indicators)
- **Error handling** with informative messages
- **Philosophical grounding** for ethical reasoning

## 🔄 Generation Workflow

### Automatic Generation
```bash
# Generated automatically by roxygen2
R CMD roxygen2::roxygenise()
```

### Enhanced Web Documentation
```r
# Generate rich Quarto documentation
library(dataimago)
create_quarto_documentation()
```

### Quality Assurance
```bash
# Validate documentation completeness
R CMD check --no-manual
```

## 📋 File Maintenance

### Automatic Updates
- **Content**: Generated from roxygen2 comments in R source
- **Cross-references**: Automatically maintained by roxygen2
- **Package metadata**: Synchronized with DESCRIPTION file
- **Version information**: Updated with package builds

### Manual Review Required
- **Philosophical context** - Ensure ethical AI principles are clear
- **Example relevance** - Verify examples demonstrate real usage
- **Cross-reference accuracy** - Check links to foundation documents
- **Accessibility** - Ensure documentation works with screen readers

### Integration Testing
- **R help system** - `?function_name` works correctly
- **Quarto conversion** - No errors in .Rd → .qmd process
- **Web rendering** - Final HTML is accessible and well-formatted
- **MCP compatibility** - AI agents can parse and understand content

## 🌟 Enhancement Features

### Beyond Standard R Documentation
dataimago .Rd files include:
- **Extended examples** showing philosophical applications
- **Error scenarios** with ethical considerations
- **Performance notes** respecting user resources
- **Future compatibility** notes for evolving APIs

### Visual Enhancements (Web)
When converted to Quarto:
- **Syntax highlighting** for code examples
- **Interactive navigation** between related functions
- **Responsive design** for mobile and desktop
- **Search functionality** across all documentation

---

*This documentation embodies dataimago's commitment to transparency, accessibility, and ethical AI development - making complex technical concepts accessible to both humans and AI agents.*