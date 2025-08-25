# dataimago Package Installation Assets

This directory contains all assets that are installed with the dataimago R package, providing programmatic and web-based access to the complete dataimago ethical AI framework.

## 📚 Directory Structure

### `dataimago/` - Complete Foundation Documents
The canonical dataimago content organized for both human access and programmatic consumption:

```
dataimago/
├── 01_Foundations/         # Mission, vision, and philosophical frameworks
├── 02_Manifesto/          # Critical theory manifesto and positioning  
├── 03_Application_Architecture/  # Technical blueprints and best practices
└── 04_dataimago_Content/  # Design assets, branding, and visual identity
```

Each directory contains:
- **Core documents** in Markdown and Quarto formats
- **Supporting materials** like diagrams and references
- **Metadata** for programmatic access
- **Cross-references** linking philosophical and technical content

### `quarto-assets/` - CDN Distribution
Ready-to-serve assets for web distribution via jsDelivr or other CDN services:

- **`dataimago.min.css`** - Production-ready CSS (6.1KB)
- **`dataimago.css`** - Development CSS with comments
- **`tokens.css`** - Design system CSS custom properties  
- **Future**: JavaScript libraries, fonts, and additional web assets

### Configuration Files
- **`CLAUDE.md`** - Persistent context for AI agent interactions
- **`AGENT_INDEX.md`** - Coordination system for multiple AI agents
- **`README.md`** - This overview document

## 🎯 Design Philosophy

### R as Source of Truth
All content in this directory represents the **canonical dataimago ecosystem**:
- **Version controlled** alongside R package releases
- **Programmatically accessible** via R functions
- **Web distributable** for broader ecosystem integration
- **AI-agent friendly** with structured metadata

### Multi-Modal Access
Content is designed for multiple consumption modes:

1. **Human readers** - Rich Markdown with cross-references
2. **R functions** - Structured data via package functions  
3. **Web applications** - Direct HTTP access to assets
4. **AI agents** - Machine-readable metadata and context

## 🌐 Web Distribution

### CDN Access Pattern
Assets in `quarto-assets/` become available via jsDelivr once tagged:

```html
<!-- Production CSS -->
<link rel="stylesheet" 
      href="https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@v0.1.0/inst/quarto-assets/dataimago.min.css"
      integrity="sha384-[SRI-HASH]"
      crossorigin="anonymous">
```

### Quarto Integration
```yaml
# _quarto.yml
format:
  html:
    css:
      - https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@v0.1.0/inst/quarto-assets/dataimago.min.css
```

### Next.js Integration
```js
// Import CSS custom properties
import 'https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@v0.1.0/inst/quarto-assets/tokens.css'

// Or use Tailwind preset from ui/dist/
module.exports = {
  presets: [require('./path/to/tailwind-preset.js')]
}
```

## 📖 Foundation Documents

### 01_Foundations/
**Philosophical and theoretical foundations**
- Mission and vision statements
- Governance structures and principles
- Theoretical frameworks (Frankfurt School, alignment discourse)
- Implementation philosophy and methodologies

### 02_Manifesto/ 
**Critical theory manifesto and positioning**
- Critique of existing paradigms (e.g., Palantir analysis)
- Emancipatory AI principles
- Societal transformation goals
- Ethical frameworks for AI development

### 03_Application_Architecture/
**Technical blueprints and implementation guides**
- Next.js + R integration patterns
- API design principles  
- Data pipeline architectures
- Performance management frameworks

### 04_dataimago_Content/
**Design assets and brand identity**
- Visual identity guidelines
- Logo files and brand assets
- Design system documentation
- Communication templates

## 🤖 AI Agent Integration

### Structured Context
The `CLAUDE.md` and `AGENT_INDEX.md` files provide:
- **Persistent context** for AI interactions
- **Capability mapping** for agent coordination  
- **Philosophical grounding** for AI reasoning
- **Task delegation** patterns for complex workflows

### Programmatic Access
Future R functions will provide structured access:
```r
# Planned functionality
foundation_doc <- get_foundation_document("mission")
manifesto_content <- get_manifesto_content("critical_theory") 
architecture_guide <- get_architecture_blueprint("nextjs_integration")
```

## 🔧 Development Workflow

### Content Updates
1. **Edit source** in foundation directories
2. **Update version** in DESCRIPTION  
3. **Run R CMD build** to package new content
4. **Create git tag** for CDN distribution

### Asset Updates  
1. **Modify design tokens** in `ui/src/tokens/`
2. **Run `build_design_system()`** in R
3. **Assets automatically sync** to `inst/quarto-assets/`
4. **Rebuild package** for distribution

### Quality Assurance
- **R CMD check** validates package integrity
- **Content review** ensures philosophical consistency  
- **Link validation** maintains cross-reference integrity
- **Version alignment** keeps assets synchronized

## 📋 File Inventory

### Always Included
- **Foundation documents** - Complete philosophical and technical framework
- **Design assets** - Essential branding and visual identity
- **Configuration files** - AI context and coordination

### Build-Generated
- **CSS assets** - Compiled design system output
- **Metadata files** - Build manifests and inventories
- **Cross-reference indices** - Document relationship mapping

### Excluded via .Rbuildignore
- **Development artifacts** - Work-in-progress documents
- **Large binaries** - RAW design files and presentations
- **Sensitive content** - Internal strategic documents

## 🎉 Integration Examples

### Academic Papers
```r
library(dataimago)
create_quarto_documentation()
# Generates websites linking technical docs to philosophical foundations
```

### Web Applications
```html
<link rel="stylesheet" href="[CDN]/dataimago.min.css">
<!-- Instantly applies ethical AI design system -->
```

### R Shiny Apps  
```r
# Use CDN assets for consistent branding
tags$link(rel="stylesheet", href="[CDN]/dataimago.min.css")
```

---

*This directory represents the complete dataimago ecosystem packaged for distribution, enabling both human understanding and machine reasoning about ethical AI development.*