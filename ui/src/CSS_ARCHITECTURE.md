# dataimago CSS Architecture Guide

## 🎯 File Organization Philosophy

**Clear Separation of Concerns + Intuitive Naming = Maintainable CSS**

## 📁 Source-of-Truth Structure (`ui/src/`)

### **🎨 Design Tokens (`tokens/`)**
```
ui/src/tokens/
├── README.md              # Token usage guidelines
├── colors.json            # Brand colors, semantic colors
├── typography.json        # Font families, sizes, weights  
├── spacing.json           # Margins, padding, grid scales
├── effects.json           # Shadows, transitions, borders
├── components.json        # Component-specific tokens
└── theme-colors.json      # Light/dark theme mappings
```

**Purpose**: Atomic design values, JSON-based, consumed by Style Dictionary

### **🧱 Core Styles (`styles/`)**
```
ui/src/styles/
├── README.md              # Core styling guidelines
├── _index.scss            # Main entry point (imports all)
├── tokens.scss            # Design tokens as SCSS variables
├── base/                  # Foundation styles
│   ├── reset.scss         # CSS reset/normalize  
│   ├── typography.scss    # Base text styles
│   └── layout.scss        # Grid, container, spacing
├── components/            # Reusable UI components
│   ├── buttons.scss       # Button variants
│   ├── forms.scss         # Form elements
│   ├── navigation.scss    # Nav, breadcrumbs, pagination
│   └── cards.scss         # Card layouts
└── themes/                # Theme-specific styles
    ├── variables.scss     # CSS custom properties mapping
    ├── light.scss         # Light theme overrides
    └── dark.scss          # Dark theme overrides
```

**Purpose**: Systematic, reusable styles that work across all pages

### **📄 Page-Specific Styles (`pages/`)**
```
ui/src/pages/
├── README.md              # Page styling guidelines
├── landing.scss           # Home page (index.qmd)
├── documentation.scss     # R package docs (r_package.qmd)  
├── shared/                # Cross-page components
│   ├── enhanced-toc.scss  # Right sidebar TOC
│   ├── hero-sections.scss # Reusable hero patterns
│   └── feature-cards.scss # Feature showcase components
└── legacy/                # Deprecated/migration files
    └── [deprecated files] # Keep temporarily during migration
```

**Purpose**: Page-specific layouts and unique features

## 📦 Generated Assets (`ui/dist/`)

### **🎯 Clear Naming Convention**
```
ui/dist/
├── core/                  # Core design system
│   ├── dataimago.css      # Complete design system
│   ├── dataimago.min.css  # Minified version
│   └── tokens.css         # Design tokens only
├── themes/                # Theme-specific builds
│   ├── light.scss         # Light theme entry point
│   ├── dark.scss          # Dark theme entry point  
│   └── theme-base.css     # Shared theme foundation
└── pages/                 # Page-specific builds
    ├── landing.css        # Home page styles
    ├── documentation.css  # R package documentation
    └── shared/            # Shared page components
        ├── enhanced-toc.css
        └── hero-sections.css
```

## 🎨 Naming Conventions

### **Files Should Indicate:**
1. **Scope**: `global-`, `page-`, `component-`
2. **Purpose**: `layout`, `theme`, `interactive`  
3. **Content**: `navigation`, `forms`, `typography`

### **Examples:**
- ✅ `component-buttons.scss` (scope + content)
- ✅ `page-landing.scss` (scope + page)
- ✅ `theme-variables.scss` (purpose + content)
- ❌ `styles.scss` (too generic)
- ❌ `misc.scss` (unclear purpose)

### **Token Files:**
- ✅ `colors.json` (content type)
- ✅ `spacing.json` (content type)
- ❌ `design-tokens.json` (too generic)
- ❌ `values.json` (unclear)

## 🔄 Build Process Mapping

### **Source → Generated → Distributed**
```
SOURCE                    GENERATED               DISTRIBUTED
ui/src/tokens/*.json  →   ui/dist/tokens.css  →   [all targets]
ui/src/styles/_index  →   ui/dist/dataimago.*  →   [all targets]
ui/src/pages/landing  →   ui/dist/pages/      →   [website only]
```

## 🧹 File Lifecycle

### **Creation:**
1. Identify scope (tokens/core/page)
2. Choose clear, descriptive name
3. Add purpose comment at top
4. Document in appropriate README

### **Maintenance:**
1. Keep related styles together
2. Use imports rather than duplication
3. Comment complex selectors
4. Update README when adding features

### **Deprecation:**
1. Move to `legacy/` folder
2. Add deprecation comment with replacement
3. Plan removal after migration period
4. Update build process to exclude

## 📋 Quick Reference

### **"Where Does This Style Go?"**
- **Brand colors** → `tokens/colors.json`
- **Button design** → `styles/components/buttons.scss`
- **Landing page hero** → `pages/landing.scss`
- **Dark theme colors** → `styles/themes/dark.scss`
- **Navigation component** → `styles/components/navigation.scss`
- **API docs layout** → `pages/documentation.scss`
- **Reusable TOC** → `pages/shared/enhanced-toc.scss`

### **"What's In This File?"**
Look for:
1. **File header comment** with purpose
2. **README.md** in same directory
3. **Imports section** showing dependencies
4. **File size** indicating complexity
