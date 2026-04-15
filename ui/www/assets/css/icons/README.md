# dataimago Icon System

A token-driven icon system for the dataimago design system that provides theme-aware, accessible SVG icons with semantic meaning.

## 📁 Directory Structure

```
icons/
├── src/
│   ├── brand/              # Core dataimago brand assets
│   │   └── ai_monogram.svg
│   ├── social/             # Social media platform icons
│   │   ├── github_logo.svg
│   │   └── bluesky_logo.svg
│   ├── platform/           # Technology platform icons
│   │   ├── netlify_logo.svg
│   │   └── quarto_logo.svg
│   └── generated/          # Build outputs
│       ├── optimized/      # SVGO-processed files
│       └── sprites/        # SVG sprite sheets
└── tokens/                 # Icon-specific design tokens
    ├── sizing.json         # Icon size scale
    ├── colors.json         # Theme-aware icon colors
    ├── states.json         # Hover, active, disabled states
    ├── semantic.json       # Semantic icon mappings
    └── transitions.json    # Animation tokens
```

## 🎯 Design Philosophy

Icons in the dataimago system are treated as **"visual discourse acts"** - they communicate intent and meaning, not just decoration. Following the system's multi-modal philosophy:

- **Visual**: SVG graphics with theme-aware coloring
- **Semantic**: Meaningful names and ARIA labels
- **Accessible**: Minimum touch targets, screen reader support
- **Ethical**: Respects motion preferences, provides alternatives

## 🔨 Usage

### In Quarto Websites

The system is designed to work with Quarto's Lua filter that converts `<img>` tags to inline SVGs:

```html
<!-- In your .qmd file -->
<img src="/icons/brand/ai_monogram.svg" class="icon icon--brand icon--logo-header" alt="dataimago">
```

After Lua filter processing, this becomes an inline SVG that can be styled with CSS:

```html
<svg class="icon icon--brand icon--logo-header" data-icon="ai_monogram">
  <!-- SVG content -->
</svg>
```

### CSS Classes

```css
/* Size modifiers */
.icon--xs     /* 16px */
.icon--sm     /* 20px */
.icon--md     /* 24px (default) */
.icon--lg     /* 32px */
.icon--xl     /* 48px */

/* Logo-specific sizes */
.icon--logo-header  /* 48px */
.icon--logo-footer  /* 32px */

/* Type modifiers */
.icon--brand    /* Brand colors on hover */
.icon--github   /* GitHub-specific colors */
.icon--bluesky  /* Bluesky brand color */
.icon--netlify  /* Netlify brand color */
.icon--quarto   /* Quarto brand color */

/* State modifiers */
.icon--interactive  /* Ensures 44px minimum touch target */
.disabled           /* Disabled state styling */
```

### Theme-Aware Styling

Icons automatically adapt to light/dark themes:

```css
/* Light theme (default) */
.icon--github:hover path {
  fill: #000000; /* Black for light theme */
}

/* Dark theme */
[data-theme="dark"] .icon--github:hover path {
  fill: #EDEDE8; /* Light grey for dark theme */
}
```

## 🎨 Token Integration

All icon styling is driven by design tokens:

### Size Tokens
- `--icon-size-xs` through `--icon-size-xl`
- `--icon-size-logo-header`, `--icon-size-logo-footer`
- `--icon-touchTarget-minimum` (44px WCAG requirement)

### Color Tokens
- `--icon-color-default` (#83838F - neutral grey)
- `--icon-color-hover-primary` (brand primary color)
- `--icon-color-social-[platform]-hover` (platform-specific colors)

### State Tokens
- `--icon-state-default-opacity` (0.8)
- `--icon-state-hover-opacity` (1.0)
- `--icon-state-hover-scale` (1.05)
- `--icon-state-disabled-opacity` (0.4)

### Transition Tokens
- `--icon-transition-duration-fast` (150ms)
- `--icon-transition-easing-default` (ease-out)

## ♿ Accessibility Features

1. **Screen Reader Support**
   - All icons include semantic `alt` text
   - ARIA labels provide context
   - Decorative icons use `aria-hidden="true"`

2. **Keyboard Navigation**
   - Focus states with visible outlines
   - Focus ring uses `--icon-state-focus-outline-*` tokens

3. **Touch Targets**
   - Minimum 44px touch targets via `.icon--interactive`
   - Padding added to meet WCAG requirements

4. **Motion Preferences**
   ```css
   @media (prefers-reduced-motion: reduce) {
     /* Transitions disabled */
     /* Scale transforms removed */
   }
   ```

5. **High Contrast Mode**
   ```css
   @media (prefers-contrast: high) {
     /* Full opacity */
     /* Added stroke for visibility */
   }
   ```

## 🔧 Building Icons

The icon CSS is generated from tokens:

```bash
# Build icon CSS from tokens
pnpm run build:icons

# Build everything including icons
pnpm run build
```

This generates `packages/css/dist/dataimago-icons.css` with:
- CSS custom properties for all icon tokens
- Utility classes for common patterns
- Theme-aware styling
- Accessibility features

## 📦 R Package Integration

For R packages using hex logos:

1. Place your `package_hex_logo.svg` in `inst/assets/`
2. Use consistent naming across all packages
3. Reference in Quarto with:
   ```html
   <img src="package_hex_logo.svg" class="icon icon--hex" alt="Package Name">
   ```

## 🚀 Future Enhancements

- [ ] SVG optimization pipeline with SVGO
- [ ] Icon sprite generation for performance
- [ ] React/Vue component generation
- [ ] Icon font generation (optional)
- [ ] Automated accessibility testing
- [ ] Multi-color icon support
- [ ] Animation presets for icon transitions

## 📚 Related Documentation

- [Main README](../../README.md)
- [Token Architecture](../../TOKEN_ARCHITECTURE.md)
- [Integration Guide](../../INTEGRATION.md)
- [Phase 1 Completion](../../PHASE4-COMPLETE.md)

---

*The icon system embodies dataimago's philosophy: icons are not mere decoration but meaningful communication that respects human dignity and accessibility.*