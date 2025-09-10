# Git Submodule Workflow for dataimago Design System

## Overview

The dataimago design system is managed as a git submodule located at `ui/src/dataimago-design/`. This architecture provides version control, reusability across projects, and clear separation between the R package and the design system.

## Repository Structure

```
dataimago-rpkg/
└── ui/
    └── src/
        ├── dataimago-design/     # Git submodule (design system repository)
        │   ├── src/
        │   │   ├── tokens/       # Design tokens (JSON)
        │   │   ├── styles/       # SCSS source files
        │   │   └── js/           # JavaScript modules
        │   ├── packages/         # npm workspace packages
        │   └── tools/            # Build and validation tools
        └── dataimago-design-old/ # Legacy backup (can be removed)
```

## Developer Workflows

### Initial Setup

When first cloning the repository:

```bash
# Clone with submodules included
git clone --recursive https://github.com/dataimago/dataimago-rpkg

# OR if already cloned without submodules
cd dataimago-rpkg/dataimago
git submodule update --init --recursive
```

### Updating the Design System

To pull the latest changes from the design system repository:

```bash
# Navigate to the submodule
cd ui/src/dataimago-design

# Pull latest changes
git pull origin main

# Return to parent repository
cd ../../..

# Commit the submodule reference update
git add ui/src/dataimago-design
git commit -m "Update design system to latest version"
```

### Making Design System Changes

When you need to modify the design system:

```bash
# Navigate to the submodule
cd ui/src/dataimago-design

# Create a feature branch (recommended)
git checkout -b feature/update-colors

# Make your changes
# Edit files in src/tokens/, src/styles/, etc.

# Commit changes in the submodule
git add .
git commit -m "Update color tokens for improved accessibility"

# Push to the design system repository
git push origin feature/update-colors

# Create a PR in the design system repository
# Once merged, update the parent repository:

# Pull the merged changes
git checkout main
git pull origin main

# Return to parent repository
cd ../../..

# Update the submodule reference
git add ui/src/dataimago-design
git commit -m "Update design system with new color tokens"
```

### Building After Design System Updates

After updating the design system, rebuild the CSS:

```r
# In R
library(dataimago)
build_design_system(force_rebuild = TRUE, verbose = TRUE)
```

Or from the command line:

```bash
cd ui
pnpm install
pnpm run build
```

## Common Tasks

### Check Submodule Status

```bash
# See current submodule commit
git submodule status

# See if submodule has uncommitted changes
cd ui/src/dataimago-design
git status
```

### Update to Specific Version

```bash
cd ui/src/dataimago-design
git checkout v1.2.3  # or specific commit hash
cd ../../..
git add ui/src/dataimago-design
git commit -m "Pin design system to v1.2.3"
```

### Fix Detached HEAD State

If the submodule is in a detached HEAD state:

```bash
cd ui/src/dataimago-design
git checkout main
git pull origin main
```

## CI/CD Considerations

GitHub Actions workflows must include submodule checkout:

```yaml
- uses: actions/checkout@v4
  with:
    submodules: recursive
```

This is already configured in:
- `.github/workflows/R-CMD-check.yml`
- `.github/workflows/test-suite.yml`
- `.github/workflows/quarto-deploy.yml`

## Build System Integration

The `build.js` script automatically uses the submodule paths:

```javascript
const config = {
  tokensDir: path.join(__dirname, 'src', 'dataimago-design', 'src', 'tokens'),
  stylesDir: path.join(__dirname, 'src', 'dataimago-design', 'src', 'styles'),
  jsDir: path.join(__dirname, 'src', 'dataimago-design', 'src', 'js')
};
```

The R function `build_design_system()` calls this script, so no R code changes are needed when working with the submodule.

## Troubleshooting

### Submodule Not Initialized

**Error**: `fatal: No url found for submodule path 'ui/src/dataimago-design'`

**Solution**:
```bash
git submodule update --init --recursive
```

### Build Fails After Update

**Error**: `Error: Can't find stylesheet to import`

**Solution**:
1. Ensure submodule is updated: `git submodule update --recursive`
2. Rebuild: `R -e "dataimago::build_design_system(force_rebuild = TRUE)"`

### Merge Conflicts in Submodule

**Solution**:
```bash
cd ui/src/dataimago-design
# Resolve conflicts as normal
git add .
git commit -m "Resolve merge conflicts"
cd ../../..
git add ui/src/dataimago-design
git commit -m "Update submodule after resolving conflicts"
```

## Best Practices

1. **Always test builds** after updating the submodule
2. **Commit submodule updates separately** from other changes for clarity
3. **Document breaking changes** in the design system in commit messages
4. **Use semantic versioning** tags in the design system repository
5. **Keep the submodule on main/stable branches** for production

## Migration from Legacy Structure

The old structure (`ui/src/tokens/`, `ui/src/styles/`) is preserved in `ui/src/dataimago-design-old/` for reference. Once confident in the submodule setup:

```bash
# Remove legacy backup
rm -rf ui/src/dataimago-design-old
git add -u
git commit -m "Remove legacy design system backup"
```

## Resources

- Design System Repository: https://github.com/dataimago/dataimago-design
- Git Submodules Documentation: https://git-scm.com/book/en/v2/Git-Tools-Submodules
- Parent Repository: https://github.com/dataimago/dataimago-rpkg