# Page-Specific Styles

This directory contains SCSS source files for page-specific styling that accompanies individual `.qmd` files in the Quarto website.

## 🎯 Purpose

While the core design system (`/ui/src/styles/`) provides consistent branding and components, individual pages may require specialized layouts, features, or styling. This directory enables that flexibility while maintaining the source-of-truth principle.

## 📁 Structure

```
pages/
├── README.md              # This file
├── r-package.scss         # R package documentation (api_reference.qmd)  
├── index.scss             # Landing page (index.qmd)
└── shared/                # Reusable page components
    ├── enhanced-toc.scss  # Enhanced right-sidebar TOC
    └── navigation.scss    # Advanced navigation features
```

## 🔄 Build Process

Page-specific SCSS files are compiled by `build.js` and distributed to:
- `ui/www/assets/css/` (website development)
- `ui/www/_extensions/.../assets/css/` (Quarto extension)
- `docs/assets/css/` (rendered website)

## 📋 Usage Guidelines

### Creating Page-Specific Styles

1. **Create SCSS file**: `pages/my-page.scss`
2. **Import base styles**:
   ```scss
   @import '../tokens';
   @import '../styles/base';
   ```
3. **Add page-specific styles**:
   ```scss
   .my-page-section {
     // Page-specific styling
   }
   ```
4. **Run build**: `build_design_system()` in R

### Naming Convention

- Use kebab-case matching QMD filename: `my-page.qmd` → `my-page.scss`
- R package docs: `r-package.scss` (universal pattern for R packages)
- Shared components: `shared/component-name.scss`

## 🎨 Design Principles

- **Import core tokens**: Always start with `@import '../tokens'`
- **Extend, don't override**: Build upon the core design system
- **Component thinking**: Shared components go in `shared/` directory
- **Responsive design**: Use design tokens for consistent breakpoints
- **Accessibility**: Maintain WCAG AA compliance

