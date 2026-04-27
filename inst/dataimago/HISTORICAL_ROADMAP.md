# Historical Asset Consolidation Roadmap

> **Status: HISTORICAL / SUPERSEDED.** This document describes an early
> (Aug 2025) asset-consolidation plan that targeted a
> `/ui/src/js/{vendor,pages,utils}/` structure. That architecture was
> never implemented; `ui/src/` briefly evolved into the
> `dataimago-design` git submodule, which was itself retired in
> `dataimago` 0.0-4.0 in favour of the package-channel model
> (`@dataimago/tokens`, `@dataimago/css`, `@dataimago/ui` on public npm;
> see 0.0-5.0 for the scope unification).
> The current roadmap lives in the sibling `dataimago-design` repo at
> `wiki/analyses/development-roadmap.md` (clone that repo directly; no
> submodule link remains). Kept here for historical reference only --
> do not use as a source of current architectural truth.

## Objective (Historical)
Bring all remaining orphaned assets under the `/ui/src/` source-of-truth architecture to complete the "AI-Native Web Application Development Workspace" vision.

---

## 🚀 **Phase 1: JavaScript Consolidation** (Priority: HIGH)

### **Assets to Migrate:**
- `jquery.sticky-kit.min.js` → `ui/src/js/vendor/`
- `landing-page-enhanced.js` → `ui/src/js/pages/`  
- `scroll.js` → `ui/src/js/utils/`

### **Implementation Steps:**

#### **1.1 Create Directory Structure**
```bash
mkdir -p ui/src/js/{vendor,pages,utils}
```

#### **1.2 Move Assets to Source**
```bash
# Third-party libraries
mv ui/www/assets/js/jquery.sticky-kit.min.js ui/src/js/vendor/

# Page-specific JS
mv ui/www/assets/js/landing-page-enhanced.js ui/src/js/pages/
mv ui/www/assets/js/scroll.js ui/src/js/utils/
```

#### **1.3 Update Build System**
Enhance `build.js` to handle subdirectories:
```javascript
// Process JS files recursively
function processJSFiles(srcDir, distDir) {
  const processDirectory = (dir, relativePath = '') => {
    const items = fs.readdirSync(dir);
    
    items.forEach(item => {
      const srcPath = path.join(dir, item);
      const stats = fs.statSync(srcPath);
      
      if (stats.isDirectory()) {
        // Recursively process subdirectories
        processDirectory(srcPath, path.join(relativePath, item));
      } else if (item.endsWith('.js')) {
        // Process JS files with directory preservation
        const distPath = path.join(distDir, 'js', relativePath, item);
        // ... processing logic
      }
    });
  };
  
  processDirectory(srcDir);
}
```

---

## 🎨 **Phase 2: CSS Page Architecture** (Priority: HIGH)

### **Assets to Migrate:**
- `api-reference-dual.css` (900+ lines)
- `documents.css` (400+ lines)  
- `enhanced-right-toc.css`
- `index.css`
- `presentations.css`
- Orphaned SCSS files

### **Implementation Steps:**

#### **2.1 Create Page-Specific Structure**
```bash
mkdir -p ui/src/styles/{pages,vendor}
```

#### **2.2 Migrate CSS to SCSS Source**
```bash
# Convert CSS to SCSS with imports
mv ui/www/assets/css/api-reference-dual.css ui/src/styles/pages/api-reference.scss
mv ui/www/assets/css/documents.css ui/src/styles/pages/documents.scss
mv ui/www/assets/css/enhanced-right-toc.css ui/src/styles/components/toc.scss
mv ui/www/assets/css/index.css ui/src/styles/pages/landing.scss
mv ui/www/assets/css/presentations.css ui/src/styles/pages/presentations.scss
mv ui/www/assets/css/lenis-integration.scss ui/src/styles/vendor/
```

#### **2.3 Enhance Each File with Token Integration**
Add design token imports to each file:
```scss
// ui/src/styles/pages/api-reference.scss
@import '../dist/tokens.css';

/* Original CSS content with token replacements */
.page-layout-full .page-columns {
  grid-template-columns: var(--layout-sidebar-width, 280px) 1fr var(--layout-toc-width, 240px);
  gap: var(--spacing-layout-gap, 2rem);
  /* ... rest of styles with token integration */
}
```

#### **2.4 Create Page-Specific Build Targets**
Update `build.js` to compile page-specific CSS:
```javascript
// Step: Compile page-specific SCSS
const pageStyles = fs.readdirSync(path.join(config.stylesDir, 'pages'))
  .filter(file => file.endsWith('.scss'));

pageStyles.forEach(file => {
  const srcPath = path.join(config.stylesDir, 'pages', file);
  const distPath = path.join(config.distDir, file.replace('.scss', '.css'));
  
  execSync(`npx sass ${srcPath}:${distPath} --style=expanded --source-map`);
});
```

---

## 🖼️ **Phase 3: Asset Management System** (Priority: MEDIUM)

### **Implementation Steps:**

#### **3.1 Create Asset Source Structure**
```bash
mkdir -p ui/src/assets/{img/{logos,icons,favicons},fonts,data}
```

#### **3.2 Move Images to Source**
```bash
# Move all images to source
mv ui/www/assets/img/* ui/src/assets/img/logos/
```

#### **3.3 Implement Image Optimization**
Add to `build.js`:
```javascript
// Step: Optimize and distribute images
const sharp = require('sharp'); // Add sharp for image optimization

function processImages() {
  const imgSource = path.join(config.srcDir, 'assets', 'img');
  const imgDist = path.join(config.distDir, 'img');
  
  // Process SVGs (copy directly)
  // Process PNGs (optimize with sharp)
  // Generate favicon variants
  // Distribute to all channels
}
```

#### **3.4 Version Control Integration**
```javascript
// Generate image manifest with hashes for cache busting
const generateImageManifest = () => {
  const manifest = {};
  // Hash each image file
  // Create versioned references
  // Output manifest.json
};
```

---

## 🧠 **Phase 4: AI-Native Components** (Priority: FUTURE)

### **Component Architecture:**
```
ui/src/components/
├── ai/
│   ├── chat-interface.scss
│   ├── model-selector.scss
│   ├── prompt-editor.scss
│   └── streaming-response.scss
├── forms/
│   ├── validation.scss
│   ├── inputs.scss
│   └── submission-states.scss
└── data-viz/
    ├── charts.scss
    ├── metrics.scss
    └── dashboards.scss
```

### **JavaScript AI Integration:**
```
ui/src/js/ai/
├── chat-client.js
├── streaming.js
├── model-management.js
└── prompt-templates.js
```

---

## 🛠️ **Enhanced Build System Requirements**

### **New Build Capabilities:**
1. **Recursive Directory Processing** - Handle nested src/ structure
2. **Page-Specific Bundles** - Generate targeted CSS/JS for different pages
3. **Image Optimization** - Sharp integration for PNG/JPG, SVG optimization
4. **Asset Hashing** - Cache-busting for production deployments
5. **Development Server** - Live reload during development
6. **Bundle Analysis** - Size reporting and optimization suggestions

### **Distribution Enhancement:**
```javascript
// Enhanced distribution with page-specific assets
const distributionManifest = {
  'core': ['tokens.css', 'dataimago.css', 'website-theme.css'],
  'pages': {
    'api-reference': ['api-reference.css', 'toc.css'],
    'documents': ['documents.css'],
    'landing': ['landing.css', 'hero-scroller.js']
  },
  'ai-components': ['chat-interface.css', 'streaming.js'],
  'images': generateImageManifest()
};
```

---

## 📅 **Implementation Timeline**

### **Week 1: JavaScript Consolidation**
- [x] ~~Directory structure~~ ✓ Already exists
- [ ] Move orphaned JS files
- [ ] Update build system for subdirectories
- [ ] Test asset distribution

### **Week 2: CSS Architecture**
- [ ] Create pages/ directory structure  
- [ ] Convert CSS to SCSS with token integration
- [ ] Update build system for page-specific CSS
- [ ] Test Quarto integration

### **Week 3: Asset Management**
- [ ] Create assets/ source structure
- [ ] Implement image optimization
- [ ] Add version control for assets
- [ ] Test multi-channel distribution

### **Future: AI-Native Components**
- [ ] Design AI component architecture
- [ ] Build chat interface components
- [ ] Create model integration utilities
- [ ] Develop prompt management system

---

## 🎯 **Success Metrics**

### **Immediate Goals (Phase 1-3):**
- ✅ **100% Source Coverage**: All assets traceable to `/ui/src/`
- ✅ **Build Consistency**: Single command generates all assets
- ✅ **Asset Optimization**: Automated image compression and versioning
- ✅ **R Integration**: All changes controllable via R functions

### **Long-term Vision (Phase 4):**
- 🚀 **Complete Development Environment**: R package contains entire web dev stack
- 🚀 **AI-Native Ready**: Components for modern AI applications built-in
- 🚀 **Community Shareable**: Other packages can extend the component library
- 🚀 **Professional Grade**: Production-ready applications from R commands

---

## 💡 **The End State**

When complete, a single R function call will create a production-ready, AI-native web application with:

```r
library(dataimago)

# Creates complete AI-native web application
create_ai_native_app("my-intelligent-app", 
  features = c("chat-interface", "document-analysis", "data-viz"),
  theme = "professional",
  ai_models = c("openai", "anthropic", "local-llama")
)

# Result: Complete application with:
# - Professional design system
# - AI chat components
# - Data visualization
# - Build pipeline
# - Development server
# - Production deployment scripts
```

This represents the full realization of "R as source of truth" for modern, AI-native web development.