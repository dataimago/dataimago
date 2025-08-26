# Dataimago Website Deployment Options

This document explains the available deployment options for the dataimago Quarto website.

## 🎯 Quick Start

**For immediate deployment**: Use Netlify (recommended)
**For GitHub integration**: Use GitHub Pages (after setup)

## 📋 Deployment Options

### Option 1: Netlify (Recommended) 🚀

**Advantages:**
- ✅ Superior performance and global CDN
- ✅ Automatic HTTPS with custom domains
- ✅ Advanced features (redirects, headers, forms)
- ✅ Better build caching and faster deployments
- ✅ No GitHub Pages permission issues

**Setup Required:**
1. Create Netlify account at [netlify.com](https://netlify.com)
2. Get your Netlify Site ID from your site dashboard
3. Generate Netlify Personal Access Token
4. Add GitHub repository secrets:
   - `NETLIFY_AUTH_TOKEN`: Your personal access token
   - `NETLIFY_SITE_ID`: Your site ID

**Workflow File:** `.github/workflows/netlify-deploy.yml`

### Option 2: GitHub Pages 📄

**Advantages:**
- ✅ Free hosting with your GitHub repository
- ✅ Automatic integration with GitHub
- ✅ No external dependencies
- ✅ Simple setup for public repositories

**Setup Required:**
1. Enable GitHub Pages in repository settings
2. Set source to "GitHub Actions"
3. Ensure repository has Pages enabled

**Workflow File:** `.github/workflows/quarto-deploy.yml`

## 🔧 Current Status

### GitHub Pages
- **Status**: Fixed OIDC permission issues
- **Issue Resolved**: Added missing `id-token: write` permission to deploy job
- **Ready**: Yes, should work after repository Pages setup

### Netlify
- **Status**: Ready to use
- **Setup Required**: Add Netlify secrets to repository
- **Benefits**: Better performance and reliability

## 🚀 Recommended Setup

### For Production: Netlify
```yaml
# Repository Secrets needed:
NETLIFY_AUTH_TOKEN=your_netlify_token
NETLIFY_SITE_ID=your_site_id
```

### For Development: GitHub Pages
- Enable in repository settings
- No additional secrets needed
- Works automatically with GitHub

## 🔄 Migration Strategy

**Option A: Use Both**
- Keep both workflows enabled
- GitHub Pages for backup/staging
- Netlify for production

**Option B: Choose One**
- Disable unused workflow
- Focus on single deployment target
- Simpler maintenance

## 📁 Build Output

Both workflows generate the same content:
- **Source**: `quarto_website/` directory
- **Build**: Rendered Quarto content
- **Output**: Static HTML/CSS/JS files
- **Assets**: Design system CSS and tokens

## 🐛 Troubleshooting

### GitHub Pages Issues
- Ensure Pages is enabled in repository settings
- Check permissions include `id-token: write`
- Verify environment is set to `github-pages`

### Netlify Issues  
- Verify `NETLIFY_AUTH_TOKEN` is valid
- Check `NETLIFY_SITE_ID` matches your site
- Ensure Netlify account has proper permissions

## 📞 Support

For deployment issues:
1. Check workflow logs in GitHub Actions
2. Verify all required secrets are set
3. Review platform-specific documentation
4. Test builds locally with `quarto render`
