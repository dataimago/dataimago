# dataimago Design System Architecture

## 🏗️ Single Source of Truth Structure

This directory now contains the **complete source of truth** for all dataimago styling, including website themes. The old fragmented architecture has been consolidated into this unified system.

## 📁 Directory Structure

```
ui/src/styles/
├── themes/
│   ├── theme-variables.scss     # CSS custom properties for light/dark themes
│   ├── shared-components.scss   # Common components using CSS vars
│   └── website-features.scss    # Website-specific components (carousel, etc.)
├── backup/                      # Original theme files (safe to delete after verification)
├── base.scss                    # Typography and base styles
├── components.scss              # Reusable UI components
├── utilities.scss               # Utility classes
├── accessibility.scss           # Accessibility features
└── website-theme.scss          # Main website theme entry point
```

## 🔧 Build System Integration

### Source → Distribution Flow:

1. **Design Tokens** (`ui/src/tokens/`) → `tokens.css`
2. **Website Theme** (`ui/src/styles/website-theme.scss`) → `website-theme.css`
3. **Quarto Compatibility** → `website-light.scss` & `website-dark.scss` 
4. **Multi-Channel Distribution** → All asset destinations updated automatically

### Build Commands:
```bash
# Full build with asset distribution
npm run build

# R interface (recommended)
build_design_system()
```

## 🎯 Key Architectural Improvements

### 1. **Eliminated Orphaned Files**
- ❌ `ui/www/assets/css/website-*.scss` (now generated)
- ❌ Manual CSS duplication across 4 locations
- ✅ Single source generates all variants

### 2. **Fixed Navbar Issue**
- **Problem**: `nav .nav-item:not(.compact) { padding-top: 7px }` caused dropdown misalignment
- **Solution**: Changed to `padding-top: 0px` in `themes/shared-components.scss:94`
- **Applied Everywhere**: Automatically distributed to all theme variants

### 3. **CSS Custom Properties Architecture**
- **Theme Variables**: Light/dark color mappings in CSS vars
- **Component Integration**: All components use `var(--theme-*)` references
- **Automatic Theming**: No manual color management needed

### 4. **Separation of Concerns**

| File | Purpose | When to Edit |
|------|---------|-------------|
| `theme-variables.scss` | Color/theme mappings | Changing color schemes |
| `shared-components.scss` | Core UI components | Layout, navbar, typography fixes |
| `website-features.scss` | Complex features | Carousel, icons, specialized components |
| `website-theme.scss` | Entry point | Rarely (just imports) |

## 🚀 Developer Workflow

### Making Changes:

1. **Styling Changes**: Edit source files in `ui/src/styles/`
2. **Build**: Run `build_design_system()` or `npm run build`
3. **Auto-Distribution**: All channels updated automatically
4. **Test**: Changes appear across website, extension, docs, CDN

### Common Tasks:

| Task | File to Edit | Example |
|------|-------------|---------|
| Fix navbar spacing | `themes/shared-components.scss` | Line 94: `padding-top: 0px` |
| Change brand colors | `themes/theme-variables.scss` | Update `--theme-text-primary` |
| Add new component | `themes/website-features.scss` | New component styles |
| Adjust typography | `themes/shared-components.scss` | Update heading styles |

## 📊 Benefits Achieved

### **Before (Fragmented)**:
- 🔴 4 separate copies of website themes (1358 lines each)
- 🔴 Manual synchronization required
- 🔴 Orphaned files outside design system
- 🔴 Hardcoded values scattered across files

### **After (Unified)**:
- ✅ Single source of truth (consolidated architecture)
- ✅ Automatic multi-channel distribution  
- ✅ CSS custom properties for theme management
- ✅ Build system handles all complexity
- ✅ Developer-friendly separation of concerns

## 🎯 Architecture Validation

The new architecture successfully achieves:

1. ✅ **Single Source of Truth**: All styling originates from `ui/src/`
2. ✅ **Proper Separation**: Variables, components, features properly separated
3. ✅ **Automatic Distribution**: 4 channels updated from one build
4. ✅ **Issue Resolution**: Navbar dropdown positioning fixed at source
5. ✅ **Maintainability**: Clear file organization with focused responsibilities
6. ✅ **File Bloat Control**: Eliminated 4 duplicate 1300+ line files
7. ✅ **R-First Philosophy**: Build system callable from R functions

This architecture now properly embodies the "R as source of truth" philosophy while leveraging modern web development practices efficiently.