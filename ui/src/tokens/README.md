# dataimago Design Tokens - Developer Guide

## Overview
This directory contains the **single source of truth** for all design tokens in the dataimago system. These tokens are processed into CSS custom properties that work across light and dark themes.

## Token Structure

### 🎨 **theme-colors.json** - Theme-Aware Colors
Your carefully tuned light/dark color scheme:

```json
{
  "color": {
    "surface": {
      "page": {
        "light": "rgb(237, 237, 235)",  // Your warm light gray
        "dark": "rgb(20, 20, 16)"       // Your warm dark background
      }
    },
    "content": {
      "primary": {
        "light": "#000000",             // Black text on light
        "dark": "rgb(237, 237, 235)"    // Warm white on dark
      },
      "secondary": {
        "light": "#7c7c7c",             // Your tuned light gray
        "dark": "#83838f"               // Your tuned dark gray
      }
    }
  }
}
```

### 🏃 **frequent.json** - High-Change Values
Most commonly adjusted in DevTools:

```json
{
  "spacing": {
    "component": {
      "padding": "1rem",    // Card/button internal spacing
      "margin": "1.5rem",   // Between-component spacing
      "gap": "0.75rem"      // Flex/grid gaps
    }
  },
  "contrast": {
    "readable": "...",      // Comfortable reading contrast
    "medium": "...",        // Secondary information
    "subtle": "..."         // De-emphasized text
  }
}
```

### 🎯 **effects.json** - Theme-Aware Effects
Shadows and borders that adapt to themes:

```json
{
  "shadow": {
    "subtle": {
      "light": "0 1px 2px 0 rgb(0 0 0 / 0.05)",
      "dark": "0 1px 2px 0 rgb(255 255 255 / 0.03)"
    }
  },
  "border": {
    "subtle": {
      "light": "rgba(0, 0, 0, 0.1)",
      "dark": "rgba(255, 255, 255, 0.1)"
    }
  }
}
```

### 🧩 **components.json** - Component References
Components reference semantic tokens:

```json
{
  "card": {
    "background": "surface.elevated",
    "padding": "spacing.component.padding",
    "shadow": "shadow.moderate"
  }
}
```

## DevTools → Token Workflow

### Common Adjustments:

| **DevTools Change** | **Edit This Token** | **CSS Variable Generated** |
|---------------------|--------------------|-----------------------------|
| Card padding too tight | `frequent.json` → `spacing.component.padding` | `--spacing-component-padding` |
| Text too light in dark | `theme-colors.json` → `content.secondary.dark` | `--color-content-secondary` |
| Button needs more emphasis | `theme-colors.json` → `interactive.primary` | `--color-interactive-primary` |
| Borders invisible | `effects.json` → `border.subtle.dark` | `--color-border-subtle` |

### Quick Edit Workflow:

```bash
# 1. Edit token JSON file
edit ui/src/tokens/frequent.json

# 2. Quick rebuild
cd ui && npm run watch  # Auto-rebuilds on save

# 3. Changes appear instantly in browser
```

## Generated CSS Structure

The build system creates theme-aware CSS custom properties:

```css
/* Theme-agnostic values */
:root {
  --color-brand-dataimago-primary: #3498DB;
  --spacing-component-padding: 1rem;
}

/* Light theme */
:root, [data-bs-theme="light"] {
  --color-surface-page: rgb(237, 237, 235);
  --color-content-primary: #000000;
}

/* Dark theme */
[data-bs-theme="dark"], @media (prefers-color-scheme: dark) {
  --color-surface-page: rgb(20, 20, 16);
  --color-content-primary: rgb(237, 237, 235);
}
```

## Token Naming Convention

**Pattern**: `category-purpose-variant`

- `--color-surface-page` = Color for surface/page level
- `--color-content-primary` = Color for content/primary emphasis  
- `--spacing-component-padding` = Spacing for component/padding use
- `--shadow-moderate` = Shadow for moderate elevation

## Theme Philosophy

- **Semantic naming** = Describes purpose, not appearance
- **Your colors preserved** = Light/dark values from your tuned SCSS files
- **DevTools friendly** = Easy to find the token you need to change
- **Automatic theming** = Components work in both themes without extra code

## Integration with Existing System

- **Quarto themes** continue working (website-light.scss, website-dark.scss)
- **New tokens** complement existing system
- **Backward compatible** = Old CSS still works during transition
- **Build system** automatically distributes to all channels

Your carefully tuned color relationships are now systematized and ready for efficient DevTools-driven development! 🎯