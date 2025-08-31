# 🔍 dataimago Asset Source-of-Truth Audit

## 📊 Current Architecture Analysis

This audit identifies assets in `/ui/www/assets/` that lack source-of-truth representation in `/ui/src/` and proposes a complete "AI-Native Web Application Development Workspace" architecture.

---

## 🟢 **ASSETS WITH SOURCE OF TRUTH** ✅

### **✅ JavaScript (Mostly Complete)**
| File | Source | Status |
|------|--------|--------|
| `accessibility.js` | ✅ `ui/src/js/` | Managed |
| `custom-anchors.js` | ✅ `ui/src/js/` | Managed |
| `hero-scroller.js` | ✅ `ui/src/js/` | Managed |
| `lenis-integration.js` | ✅ `ui/src/js/` | Managed |
| `logo-switch.js` | ✅ `ui/src/js/` | Managed |
| `slide-navigation.js` | ✅ `ui/src/js/` | Managed |

### **✅ CSS (Recently Fixed)**
| File | Source | Status |
|------|--------|--------|
| `dataimago.css` | ✅ Built from `ui/src/styles/` | Managed |
| `dataimago.min.css` | ✅ Built from `ui/src/styles/` | Managed |
| `tokens.css` | ✅ Built from `ui/src/tokens/` | Managed |
| `website-*.scss` | ✅ Built from `ui/src/styles/themes/` | Managed |

### **✅ Design Tokens**
| Category | Source | Status |
|----------|--------|--------|
| Colors | ✅ `ui/src/tokens/colors.json` | Managed |
| Typography | ✅ `ui/src/tokens/typography.json` | Managed |
| Components | ✅ `ui/src/tokens/components.json` | Managed |
| Effects | ✅ `ui/src/tokens/effects.json` | Managed |

---

## 🔴 **ORPHANED ASSETS** ❌ 

### **❌ JavaScript (Missing Source)**
| File | Issue | Recommendation |
|------|-------|----------------|
| `jquery.sticky-kit.min.js` | Third-party lib | Move to `ui/src/js/vendor/` |
| `landing-page-enhanced.js` | Custom code | Move to `ui/src/js/` |
| `scroll.js` | Legacy code | Consolidate with other scroll JS |

### **❌ CSS (Page-Specific Orphans)**
| File | Issue | Source Needed |
|------|-------|---------------|
| `api-reference-dual.css` | 900+ lines | `ui/src/styles/pages/api-reference.scss` |
| `documents.css` | 400+ lines | `ui/src/styles/pages/documents.scss` |
| `enhanced-right-toc.css` | TOC styling | `ui/src/styles/components/toc.scss` |
| `index.css` | Landing page | `ui/src/styles/pages/landing.scss` |
| `presentations.css` | Presentation styling | `ui/src/styles/pages/presentations.scss` |
| `components.scss` | Orphaned SCSS | Consolidate with `ui/src/styles/components.scss` |
| `lenis-integration.scss` | Scroll integration | Move to `ui/src/styles/vendor/` |

### **❌ Images (No Management System)**
| Asset Type | Current | Needs |
|------------|---------|-------|
| SVG Logos | Manual placement | `ui/src/assets/img/` source |
| PNG Favicons | Manual placement | Build-time optimization |
| Brand Assets | No versioning | Source control integration |

---

## 🎯 **RECOMMENDED ARCHITECTURE: Complete Source-of-Truth**

### **Phase 1: JavaScript Consolidation**
```
ui/src/js/
├── vendor/                    # Third-party libraries
│   └── jquery.sticky-kit.min.js
├── pages/                     # Page-specific functionality
│   └── landing-page-enhanced.js
├── utils/                     # Shared utilities
│   └── scroll.js              # Consolidated scroll logic
└── [existing files]
```

### **Phase 2: CSS Page Architecture**
```
ui/src/styles/
├── pages/                     # Page-specific styles
│   ├── api-reference.scss     # API reference dual layout
│   ├── documents.scss         # Document listing page
│   ├── landing.scss           # Homepage styling  
│   └── presentations.scss     # Presentation layouts
├── components/
│   └── toc.scss               # Enhanced TOC component
├── vendor/
│   └── lenis-integration.scss # Third-party integrations
└── [existing structure]
```

### **Phase 3: Asset Management System**
```
ui/src/assets/
├── img/
│   ├── logos/                 # Brand logos (source SVG)
│   ├── icons/                 # UI icons
│   └── favicons/              # Favicon source files
├── fonts/                     # Custom fonts
└── data/                      # Static JSON/config files
```

### **Phase 4: Build System Enhancement**
```javascript
// Enhanced build.js
- Process page-specific CSS
- Optimize images automatically  
- Generate favicon variants
- Bundle vendor libraries
- Create development vs production builds
```

---

## 🚀 **AI-Native Web Application Development Workspace**

### **Complete Self-Contained Environment**

The R package should provide everything needed for AI-native web development:

#### **🎨 Frontend Foundation**
- ✅ Design system with tokens
- ✅ Theme management (light/dark)
- ✅ Component library
- ✅ Responsive utilities
- ⚠️ **MISSING**: Page templates, form components, data visualization components

#### **🧠 AI Integration Assets**
- ⚠️ **MISSING**: AI chat interface components
- ⚠️ **MISSING**: Streaming response handling
- ⚠️ **MISSING**: Model selection components
- ⚠️ **MISSING**: Prompt management interface

#### **📱 Interactive Components**
- ✅ Navigation systems
- ✅ Carousel/content display
- ✅ Accessibility features
- ⚠️ **MISSING**: Form validation, modals, notifications

#### **🔧 Development Tools**
- ✅ Build system
- ✅ Asset distribution
- ⚠️ **MISSING**: Development server, hot reload, testing utilities

---

## 📋 **Recommended Action Plan**

### **Priority 1: JavaScript Consolidation**
1. Move orphaned JS to `ui/src/js/`
2. Organize by purpose (pages/, vendor/, utils/)
3. Update build system to handle subdirectories

### **Priority 2: CSS Architecture**
1. Create `ui/src/styles/pages/` directory
2. Move page-specific CSS files to source
3. Consolidate component CSS files

### **Priority 3: Asset Management**
1. Create `ui/src/assets/` structure  
2. Implement image optimization in build system
3. Add favicon generation pipeline

### **Priority 4: AI-Native Components**
1. Build chat interface components
2. Create AI model integration utilities
3. Add streaming response handlers
4. Build prompt management interface

---

## 🎯 **Expected Benefits**

### **Immediate**
- ✅ Complete source-of-truth architecture
- ✅ No more orphaned assets
- ✅ Consistent build pipeline
- ✅ R-controlled web development

### **Long-term**
- 🚀 Self-contained AI web development environment
- 🚀 Rapid AI-native application scaffolding
- 🚀 Consistent brand/UX across all projects
- 🚀 Community-shareable web components

---

## 💡 **The Vision Realized**

Once complete, the R package will contain everything needed to bootstrap a professional AI-native web application:

```r
# Single R command creates complete web app environment
create_ai_native_app("my-app")
# → Includes: Design system, AI components, build pipeline, dev server
```

This would truly embody "R as source of truth" for modern web development while maintaining the sophistication expected of professional AI applications.

**Status**: Currently ~70% complete. The foundation is solid - we need to bring the remaining 30% under source control.