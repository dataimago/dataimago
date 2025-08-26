# dataimago CDN Distribution Assets

## 🎯 Purpose

This directory contains **CDN-ready CSS assets** that enable external projects to directly link to dataimago design system files via jsDelivr CDN. These files are **critical infrastructure** for the dataimago ecosystem.

## ⚠️ CRITICAL WARNING

**NEVER DELETE THIS DIRECTORY OR ITS CONTENTS**

These files enable:
- 🌐 **CDN Distribution**: External projects can link directly via jsDelivr
- 📦 **R Package Access**: Users can find files with `system.file()`
- 🚀 **External Integration**: Third-party websites can use dataimago styling

## 📁 File Inventory

| File | Size | Purpose |
|------|------|---------|
| `dataimago.css` | ~6.1KB | **Unminified** CSS for development & debugging |
| `dataimago.min.css` | ~6.1KB | **Minified** CSS for production use |
| `tokens.css` | ~1.8KB | **Design tokens** as CSS custom properties |

## 🌐 CDN Usage

### External Project Integration

```html
<!-- Production (minified) -->
<link rel="stylesheet" 
      href="https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@v0.1.0/inst/quarto-assets/dataimago.min.css"
      integrity="sha384-[SRI-HASH]"
      crossorigin="anonymous">

<!-- Development (with comments) -->
<link rel="stylesheet" 
      href="https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@v0.1.0/inst/quarto-assets/dataimago.css">

<!-- Design tokens only -->
<link rel="stylesheet" 
      href="https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@v0.1.0/inst/quarto-assets/tokens.css">
```

### R Package Access

```r
# Find CSS files in installed package
css_path <- system.file("quarto-assets/dataimago.min.css", package = "dataimago")
tokens_path <- system.file("quarto-assets/tokens.css", package = "dataimago")

# Programmatic access
if (file.exists(css_path)) {
  cat("dataimago CSS available at:", css_path)
}
```

## 🔄 How These Files Are Generated

These files are **automatically generated** by the design system build process:

```r
library(dataimago)

# 1. Ensure sophisticated UI workspace exists
create_ui_workspace()  # Preserves existing sophisticated system

# 2. Build all assets including CDN distribution
build_design_system(
  include_sri = TRUE,      # Generate security hashes
  update_extension = TRUE, # Update Quarto extension
  verbose = TRUE          # Show detailed progress
)

# 3. Files automatically copied from ui/dist/ to inst/quarto-assets/
```

## 🏗️ Build Process Flow

```
ui/src/tokens/*.json  →  Style Dictionary  →  CSS Custom Properties
ui/src/styles/*.scss  →  Sass Compiler    →  Compiled CSS
Compiled CSS         →  PostCSS          →  Minified & Optimized
Final CSS           →  Copy Process     →  inst/quarto-assets/
```

## 📋 Maintenance

### When to Update

Files are automatically updated when:
- Design tokens are modified (`ui/src/tokens/*.json`)
- SCSS source files are changed (`ui/src/styles/*.scss`)
- `build_design_system()` is executed

### Manual Updates

```r
# Force complete rebuild and distribution
build_design_system(force_rebuild = TRUE)

# Verify files were updated
list.files("inst/quarto-assets/", full.names = TRUE)
```

### Verification

```r
# Check file sizes (should be substantial)
file.info("inst/quarto-assets/dataimago.min.css")$size  # ~6KB
file.info("inst/quarto-assets/tokens.css")$size        # ~1.8KB

# Check content quality
readLines("inst/quarto-assets/tokens.css", n = 5)  # Should show CSS variables
```

## 🚨 Troubleshooting

### Problem: Files Are Missing
```r
# Regenerate from build system
build_design_system(force_rebuild = TRUE)
```

### Problem: Files Are Too Small (< 1KB)
This indicates a **minimal fallback system** was generated instead of the sophisticated build:
```r
# Check if sophisticated UI system exists
list.files("ui/src/", recursive = TRUE)  # Should show tokens/ and styles/

# If missing, restore from backup or repository
# Then rebuild
build_design_system(force_rebuild = TRUE)
```

### Problem: CDN Links Don't Work
- Check that the repository has been **tagged** for release
- Verify the **version number** in the CDN URL matches the tag
- Ensure files exist in the **specific tagged version**

## 🔗 Related Documentation

- `ui/README.md` - Complete design system documentation
- `R/design_system.R` - Build system functions
- Main `README.md` - Package architecture overview
- `CLAUDE.md` - Technical details for AI assistance

## 🎨 Design System Integration

These files are part of the larger dataimago design system:

- **Foundation**: Based on ethical AI principles (WCAG AA, reduced motion)
- **Token-Driven**: Generated from semantic JSON design tokens  
- **Multi-Platform**: Same source generates CSS, Tailwind presets, and more
- **Sophisticated**: Built with Style Dictionary + SCSS + PostCSS pipeline

---

*These assets enable external projects to adopt dataimago's ethical AI design principles through simple CSS links. They represent the visual expression of our philosophical commitment to emancipatory AI development.*
