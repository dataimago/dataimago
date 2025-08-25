# dataimago Website CSS Assets

This directory contains CSS assets for the dataimago Quarto website. These files are being transitioned to the new R-first design system located in `ui/` and distributed via the AI-native Quarto extension.

## 🔄 Migration Status

This directory is being **superseded by the new R-first design system**:

### ✅ **New System** (Recommended)
- **Source**: `ui/src/tokens/` and `ui/src/styles/`
- **Build**: `build_design_system()` R function
- **Distribution**: `_extensions/dataimago/ai-native/`
- **CDN**: `inst/quarto-assets/dataimago.min.css`

### 📋 **Legacy Files** (Transitional)
- `dataimago.scss` - Original dataimago styling (superseded by design system)
- `documents.css` - Document page styling (to be migrated)
- `website-*.scss` - Theme variations (replaced by light/dark tokens)

### 🎯 **Migration Path**
1. New projects should use the AI-native extension
2. Existing customizations will be migrated to design tokens
3. Legacy files will be removed in future versions

## CSS Architecture

### Primary Stylesheet (`website-custom.scss`)

This comprehensive SCSS file includes:

#### **Core Design System**
- **Color Palette**: Sophisticated grey/black theme with RGB(237,237,235) base
- **Typography**: Professional font stack with enhanced heading hierarchy
- **SCSS Variables**: Logo paths and customizable defaults

#### **Advanced Navbar System**
- **Dynamic Background**: Smooth color transitions on scroll
- **Logo Integration**: Hover effects with color switching
- **Responsive Dropdown Menus**: 
  - Rounded corners with subtle shadows
  - Animated caret rotation (up ↔ down)
  - Inset hover effects with multi-layer shadows
  - Active state indication (black text + caret)

#### **Interactive Elements**
- **Link Styling**: Consistent grey-to-black hover transitions
- **Anchor Links**: Smooth color transitions with no underlines
- **Navigation**: Clean sidebar styling without underlines
- **Code Blocks**: Enhanced backgrounds and borders

#### **Advanced Animations**
- **Smooth Transitions**: 0.3s ease timing throughout
- **Hover Effects**: Left-to-right underline animations
- **Dropdown Animations**: Caret rotation with state management
- **Scroll Effects**: Dynamic navbar shrinking

### Specialized Styling (`documents.css`)

The documents page maintains its own dedicated stylesheet for:
- **Document Cards**: Grid layout with hover animations
- **Typography**: Document-specific heading and text styling  
- **Interactive Elements**: Buttons, tags, and action components
- **Responsive Design**: Mobile-optimized layouts

## Technical Implementation

### Color System
```scss
// Primary background colors
$body-bg: rgb(237, 237, 235);
body { background-color: rgb(237, 237, 235); }
body.shrink { background-color: rgb(237, 237, 238); }

// Dropdown menu colors
background-color: rgb(227, 227, 225);
hover: rgb(237, 237, 235);

// Link colors
default: #7c7c7c;
hover: #000;
```

### Advanced Shadow Effects
```scss
// Multi-layer inset shadows for dropdown items
box-shadow: inset 0 2px 4px rgba(222, 222, 220, 0.8), 
            inset 0 1px 2px rgba(222, 222, 220, 0.8),
            inset 0 -1px 2px rgba(222, 222, 220, 0.8),
            inset 0 -2px 4px rgba(222, 222, 220, 0.8);
```

### JavaScript Integration

The CSS works in conjunction with JavaScript for:
- **Dropdown State Management**: Caret rotation and color changes
- **Scroll Effects**: Dynamic navbar shrinking
- **Smooth Animations**: State transitions and hover effects

## File Organization

### Current Structure
```
assets/css/
├── website-custom.scss  (527 lines - MAIN STYLESHEET)
│   ├── SCSS Variables & Defaults
│   ├── Body & Layout Styling  
│   ├── Advanced Navbar System
│   ├── Dropdown Menu Animations
│   ├── Link & Typography Styling
│   ├── Enhanced Code Blocks
│   └── Responsive Design
└── documents.css        (197 lines - PAGE-SPECIFIC)
    ├── Document Grid Layout
    ├── Card Components
    ├── Interactive Elements
    └── Mobile Responsiveness
```

### Consolidation Benefits

1. **Performance**: Reduced HTTP requests (2 files vs. 4 previously)
2. **Maintainability**: Single source of truth for main styling
3. **Consistency**: Unified color palette and design language
4. **Modularity**: Page-specific styles remain separate

## 🚀 New R-First Workflow

### For New Development
```r
# 1. Set up design system workspace (one-time)
library(dataimago)
create_ui_workspace()

# 2. Modify design tokens in ui/src/tokens/*.json
# 3. Edit SCSS in ui/src/styles/*.scss

# 4. Build all assets
build_design_system(verbose = TRUE)

# 5. Use in Quarto projects
# Option A: Extension
# _quarto.yml: theme: dataimago/ai-native

# Option B: CDN
# css: https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@v0.1.0/inst/quarto-assets/dataimago.min.css
```

### Design Token Customization
```json
// ui/src/tokens/colors.json
{
  "color": {
    "brand": {
      "primary": { "value": "#2C3E50" },
      "accent": { "value": "#3498DB" }
    }
  }
}
```

### Benefits of New System
1. **R-First**: No Node.js knowledge required
2. **Multi-Platform**: Same tokens → Quarto + Next.js + R Shiny  
3. **Accessibility**: WCAG AA compliance built-in
4. **Versioned**: CDN distribution with SRI hashes
5. **Ethical**: Reduced motion and high contrast support

## Technical Dependencies

### Quarto Integration
```yaml
# _quarto.yml configuration
theme:
  - cosmo
  - ./assets/css/website-custom.scss
css: 
  - ./assets/css/documents.css
```

### JavaScript Dependencies
- `scroll.js` - Navbar shrinking and dropdown management
- `jquery` - DOM manipulation and event handling
- Bootstrap classes - Dropdown state management (.show, .open) 