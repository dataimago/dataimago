# dataimago Design System - Node.js Workspace

<!-- Design System Badges -->
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![Package Manager](https://img.shields.io/badge/Package%20Manager-pnpm-orange.svg)](https://pnpm.io/)
[![Build System](https://img.shields.io/badge/Build-Style%20Dictionary%20%2B%20Sass-blue.svg)](package.json)
[![Design Tokens](https://img.shields.io/badge/Tokens-JSON%20%E2%86%92%20CSS-purple.svg)](src/tokens/)
[![Accessibility](https://img.shields.io/badge/WCAG-AA%20Compliant-brightgreen.svg)](#-accessibility-features)
[![R Controlled](https://img.shields.io/badge/Controlled%20by-R%20Functions-red.svg)](../R/design_system.R)

This directory contains the Node.js workspace for compiling the dataimago ethical AI design system. It's controlled entirely through R functions in `R/design_system.R`, maintaining the "R as source of truth" philosophy.

> 📋 **See [../ARCHITECTURE.md](../ARCHITECTURE.md) for comprehensive system diagrams** that show how this UI workspace integrates with the broader dataimago package architecture.

## \U0001F3D7\UFE0F Architecture

### Directory Structure
```
ui/
\u251c\u2500\u2500 src/                    # Source files
\u2502   \u251c\u2500\u2500 tokens/            # Design tokens (JSON)
\u2502   \u2502   \u251c\u2500\u2500 colors.json    # dataimago color palette
\u2502   \u2502   \u251c\u2500\u2500 typography.json # Font definitions
\u2502   \u2502   \u2514\u2500\u2500 spacing.json   # Spacing scale
\u2502   \u2514\u2500\u2500 styles/            # SCSS source files
\u2502       \u251c\u2500\u2500 base.scss      # Foundation styles
\u2502       \u251c\u2500\u2500 components.scss # UI components
\u2502       \u251c\u2500\u2500 utilities.scss  # Utility classes
\u2502       \u2514\u2500\u2500 accessibility.scss # Ethical AI accessibility
\u251c\u2500\u2500 dist/                  # Built assets (generated)
\u251c\u2500\u2500 node_modules/          # Node.js dependencies
\u251c\u2500\u2500 package.json           # Node.js configuration
\u2514\u2500\u2500 build.js              # Custom build script
```

## \U0001F3AF Design Philosophy

### Ethical AI Principles
Every design decision reflects dataimago's commitment to emancipatory AI:

- **WCAG AA Compliance**: All color combinations meet accessibility contrast requirements
- **Reduced Motion Respect**: Animations honor user motion preferences
- **High Contrast Support**: Alternative color schemes for accessibility needs
- **Semantic Naming**: Colors like `ethical-highlight` embed meaning in the system

### Token-Driven Approach
Design tokens ensure consistency across all platforms:
- **JSON Source**: Human and machine-readable design decisions
- **Style Dictionary**: Converts tokens to CSS custom properties
- **Multi-Platform**: Same tokens generate CSS, Sass variables, and Tailwind presets

### SVG Logo Integration
The build system includes sophisticated SVG logo management:
- **Theme-Aware SVGs**: 4 variants each for AI monogram and package hex logos
- **Automatic Distribution**: SVGs copied to CDN and extension directories
- **CSS Integration**: Logo paths embedded in SCSS for theme switching
- **JavaScript Support**: Theme detection and hover state management

## \u2699\ufe0f Build Process

### 1. Design Token Processing
```bash
npx style-dictionary build
```
Converts JSON tokens \u2192 CSS custom properties in `dist/tokens.css`

### 2. SCSS Compilation
```bash
npx sass src/main.scss:dist/dataimago.css
```
Compiles component styles using design tokens

### 3. PostCSS Optimization
```bash
npx postcss dist/dataimago.css -o dist/dataimago.min.css
```
Adds vendor prefixes and minifies for production

### 4. Tailwind Preset Generation
Creates `dist/tailwind-preset.js` for Next.js integration

## \U0001F680 R-First Usage

**Never run Node.js commands directly.** Use R functions instead:

```r
library(dataimago)

# Set up workspace (one-time)
create_ui_workspace()

# Build all assets
build_design_system(verbose = TRUE)
```

## \U0001F4E6 Generated Assets

### Production Ready
- **`dataimago.min.css`** (6.1KB) - Minified CSS for production use
- **`tokens.css`** (1.8KB) - CSS custom properties for styling
- **`tailwind-preset.js`** (0.4KB) - Next.js Tailwind configuration

### Development
- **`dataimago.css`** (6.1KB) - Expanded CSS with comments
- **`*.css.map`** - Source maps for debugging
- **`manifest.json`** - Build metadata and asset inventory

## \U0001F310 Distribution Channels

Assets are automatically distributed to:

1. **Quarto Extension**: `_extensions/dataimago/ai-native/assets/css/`
2. **CDN Distribution**: `inst/quarto-assets/` (jsDelivr-compatible)
3. **Local Development**: `ui/dist/` (with source maps)

## \U0001F3A8 Customization

### Modifying Design Tokens
Edit JSON files in `src/tokens/`:
```json
{
  "color": {
    "brand": {
      "primary": {
        "value": "#2C3E50",
        "description": "dataimago primary brand color"
      }
    }
  }
}
```

### Adding Components
Create SCSS in `src/styles/components.scss`:
```scss
.di-new-component {
  background: var(--color-brand-primary);
  color: var(--color-text-inverse);
  padding: var(--spacing-md);
  border-radius: var(--radius-md);
}
```

### After Changes
Always rebuild through R:
```r
build_design_system(force_rebuild = TRUE)
```

## \U0001F9E0 Accessibility Features

The design system includes comprehensive accessibility enhancements:

### Screen Reader Support
- **`.sr-only`** - Screen reader only content
- **Skip links** - Keyboard navigation assistance
- **ARIA live regions** - Dynamic content announcements

### Motor Accessibility
- **Large click targets** - Minimum 44px touch targets
- **Keyboard navigation** - Full keyboard accessibility
- **Focus indicators** - Enhanced focus visibility

### Visual Accessibility
- **High contrast mode** - Alternative color schemes
- **Reduced motion** - Respects user motion preferences
- **Color blind friendly** - Text and icon indicators

## \U0001F527 Dependencies

### Required (automatically managed)
- **style-dictionary@^4.0.0** - Design token processing
- **sass@^1.69.0** - SCSS compilation
- **postcss@^8.4.0** - CSS post-processing
- **autoprefixer@^10.4.0** - Vendor prefixes
- **cssnano@^6.0.0** - CSS minification

### System Requirements
- **Node.js 18+** - JavaScript runtime
- **pnpm or npm** - Package manager
- **OpenSSL** - SRI hash generation (usually pre-installed)

## \U0001F504 Workflow Integration

This workspace integrates seamlessly with:
- **R CMD build** - Assets included in package builds
- **Quarto render** - Extension provides styling
- **GitHub Actions** - CI/CD builds and releases
- **Next.js projects** - Via Tailwind preset consumption

---

*This workspace embodies dataimago's R-first philosophy: modern CSS tooling wrapped in familiar R functions with comprehensive documentation of every system interaction.*