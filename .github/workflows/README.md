# dataimago GitHub Actions CI/CD

<!-- CI/CD Badges -->
[![Workflows](https://img.shields.io/badge/Workflows-7%20Comprehensive-blue.svg)](.)
[![Multi-Platform](https://img.shields.io/badge/Testing-macOS%20%7C%20Windows%20%7C%20Ubuntu-green.svg)](test-suite.yml)
[![R Versions](https://img.shields.io/badge/R%20Versions-4.1%2B%20%7C%20Latest%20%7C%20Devel-orange.svg)](test-suite.yml)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B%20Integration-purple.svg)](test-suite.yml)
[![Deployment Options](https://img.shields.io/badge/Deployment-GitHub%20Pages%20%7C%20Netlify-brightgreen.svg)](DEPLOYMENT.md)
[![Security](https://img.shields.io/badge/Dependencies-Auto%20Monitored-red.svg)](dependencies.yml)

This directory contains comprehensive GitHub Actions workflows for the dataimago R package, providing automated testing, building, and deployment across multiple platforms.

## 🔄 Workflows Overview

### 1. **R-CMD-check.yml** - Core Package Testing
- **Triggers**: Push to main/develop, PRs, weekly schedule
- **Platforms**: macOS, Windows, Ubuntu (multiple R versions)
- **Features**:
  - Cross-platform R CMD check
  - Node.js design system integration
  - Automated dependency management
  - Build artifact caching

### 2. **quarto-deploy.yml** - GitHub Pages Deployment
- **Triggers**: Push to main, manual dispatch
- **Features**:
  - Automated API documentation generation
  - Design system asset compilation
  - Quarto website rendering
  - GitHub Pages deployment with OIDC authentication

### 3. **netlify-deploy.yml** - Netlify Deployment (Recommended)
- **Triggers**: Push to main, manual dispatch
- **Features**:
  - Identical build process to GitHub Pages
  - Superior performance with global CDN
  - Advanced deployment features (redirects, headers, forms)
  - Requires NETLIFY_AUTH_TOKEN and NETLIFY_SITE_ID secrets

### 4. **release-cdn.yml** - CDN Release Automation
- **Triggers**: Git tags (v*.*.*), manual dispatch
- **Features**:
  - Versioned CDN asset generation
  - SRI hash computation for security
  - jsDelivr cache purging
  - GitHub release creation with assets

### 5. **test-suite.yml** - Comprehensive Testing
- **Triggers**: Push, pull requests
- **Features**:
  - R code linting and style checks
  - Design system build validation
  - Documentation generation testing
  - Quarto rendering verification

### 6. **dependencies.yml** - Dependency Management
- **Triggers**: Weekly schedule, dependency file changes
- **Features**:
  - R and Node.js dependency monitoring
  - Security vulnerability scanning
  - Automated update PRs
  - Outdated package reporting

## 🌐 Deployment Options

The dataimago website can be deployed to two platforms:

### 📄 GitHub Pages (Fixed)
- **Status**: ✅ OIDC permissions resolved
- **Setup**: Enable Pages in repository settings
- **Workflow**: `quarto-deploy.yml`
- **Best for**: Simple GitHub integration

### 🚀 Netlify (Recommended)
- **Status**: ✅ Ready to use
- **Setup**: Add `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID` secrets
- **Workflow**: `netlify-deploy.yml`
- **Best for**: Production websites with superior performance

📋 **See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed setup instructions**

## 🚀 Usage Workflows

### Development Workflow
1. **Push to develop branch** → Triggers comprehensive testing
2. **Create PR to main** → Full test suite + cross-platform checks
3. **Merge to main** → Website deployment + CDN preparation

### Release Workflow
1. **Create git tag** (`v1.0.0`) → Triggers CDN release automation
2. **Assets built and published** → jsDelivr CDN, GitHub releases
3. **Documentation updated** → Website reflects new version

### Manual Operations
- **Workflow dispatch** available on all workflows
- **Emergency deployments** via manual triggers
- **Dependency updates** can be triggered manually

## 📦 CDN Distribution

### jsDelivr URLs (Auto-generated)
```
https://cdn.jsdelivr.net/gh/dataimago/dataimago@v{VERSION}/inst/quarto-assets/dataimago.min.css
https://cdn.jsdelivr.net/gh/dataimago/dataimago@v{VERSION}/inst/quarto-assets/tokens.css
```

### Quarto Integration
```yaml
format:
  html:
    css:
      - https://cdn.jsdelivr.net/gh/dataimago/dataimago@latest/inst/quarto-assets/dataimago.min.css
```

## 🔐 Security Features

- **SRI hashes** automatically generated for all CSS assets
- **Dependency vulnerability scanning** for both R and Node.js
- **Security audit failures** block releases
- **Integrity verification** included in release notes

## 🔧 Configuration

### Required Secrets
- `GITHUB_TOKEN` (automatic, for repository access)

### Required Permissions
- **Contents**: write (for releases)
- **Pages**: write (for GitHub Pages)
- **ID token**: write (for Pages deployment)

### Branch Protection
Recommended settings for `main` branch:
- Require PR reviews
- Require status checks: "R-CMD-check", "test-suite"
- Require up-to-date branches
- Include administrators in restrictions

## 🎯 Benefits

✅ **Automated Quality Assurance** - Every commit tested across platforms
✅ **Zero-Touch Releases** - Tag creation triggers full CDN deployment
✅ **Documentation Sync** - Website always reflects current package state
✅ **Security Monitoring** - Automatic vulnerability detection
✅ **Dependency Management** - Proactive updates via automated PRs
✅ **Multi-Platform Support** - Windows, macOS, Linux testing
✅ **CDN Distribution** - Global asset delivery via jsDelivr

This CI/CD setup embodies dataimago's principle of **R as source of truth** while leveraging best practices for modern package distribution and deployment automation.