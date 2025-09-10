# Sass Module System Migration Guide

## Overview

The dataimago design system has been migrated to use the Sass 3.0 module system (`@use` and `@forward`) instead of the deprecated `@import` statements. This future-proofs the codebase for Dart Sass 3.0 and provides better namespace management, performance, and maintainability.

## Key Changes

### Before (Deprecated @import)
```scss
@import '../tokens';
@import 'themes/theme-variables';
@import 'themes/shared-components';
```

### After (Modern @use/@forward)
```scss
@use '../tokens' as *;
@use 'themes/theme-variables' as *;
@use 'themes/shared-components' as *;
```

## Architecture

### Module Entry Points

1. **`styles/_index.scss`** - Main module entry point
   - Forwards all style modules
   - Provides namespace control
   - Single import point for external consumers

2. **`_tokens.scss`** - Token module wrapper
   - Forwards generated tokens from build process
   - Provides fallback values during initial setup

### Build Process Integration

The `build.js` script has been updated to:
- Generate main.scss using `@use` statements
- Add `--quiet-deps` flag to suppress migration warnings
- Maintain full backward compatibility with Quarto and Next.js

## Usage Patterns

### Basic Import (Global Namespace)
```scss
// Import everything into global namespace
@use 'styles' as *;
```

### Namespaced Import
```scss
// Import with namespace
@use 'styles';
// Use as: styles.$variable-name
```

### Custom Namespace
```scss
// Import with custom namespace
@use 'styles' as dataimago;
// Use as: dataimago.$variable-name
```

### Selective Import
```scss
// Import only specific modules
@use 'styles/base';
@use 'styles/components';
```

## Benefits

1. **No Duplicate CSS** - Files are only loaded once
2. **Namespace Isolation** - Prevents variable conflicts
3. **Private Members** - Use `_` prefix for private variables/mixins
4. **Explicit Dependencies** - Clear visibility of imports
5. **Better Performance** - Faster compilation
6. **Future-Proof** - Ready for Dart Sass 3.0

## Compatibility

### Quarto
- ✅ Fully compatible - Quarto uses compiled CSS files
- Website themes work with `website-light.scss` and `website-dark.scss`
- No changes needed to `_extension.yml`

### Next.js/Tailwind
- ✅ Fully compatible - Uses CSS custom properties
- Tailwind preset continues to work unchanged
- No impact on JavaScript imports

### R Package
- ✅ Fully compatible - `build_design_system()` works unchanged
- Build process handles all compilation
- No R code changes required

## Migration Checklist

- [x] Create module entry points (`_index.scss`)
- [x] Update `website-theme.scss` to use `@use`
- [x] Update `build.js` to generate `@use` statements
- [x] Add `--quiet-deps` flag to sass commands
- [x] Test build process
- [x] Verify R function compatibility
- [x] Verify Quarto extension works
- [x] Document changes

## Troubleshooting

### Error: "It's not clear which file to import"
**Solution**: Ensure unique file names or use explicit paths with extensions.

### Error: "Undefined variable"
**Solution**: Variables now need explicit namespace or `as *` import.

### Warning: "@import is deprecated"
**Solution**: Already suppressed with `--quiet-deps` flag.

## Future Considerations

1. **Gradual Module Refinement**
   - Consider splitting large modules into smaller, focused ones
   - Create mixins and functions modules
   - Implement configuration modules

2. **Variable Namespacing**
   - Consider keeping some imports namespaced for clarity
   - Document which variables are public vs private

3. **Performance Optimization**
   - Leverage `@forward` with `show` and `hide` for selective exports
   - Use `with` for configuration when importing

## Resources

- [Sass Module System Documentation](https://sass-lang.com/documentation/at-rules/use)
- [Migration Guide](https://sass-lang.com/documentation/breaking-changes/import)
- [Dart Sass 3.0 Plans](https://github.com/sass/sass/issues/3902)

## Summary

The migration to the Sass module system positions the dataimago design system for long-term sustainability while maintaining full backward compatibility with existing integrations. The changes are transparent to end users and provide a more robust foundation for future development.