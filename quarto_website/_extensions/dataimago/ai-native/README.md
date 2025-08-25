# 🚀 Dataimago AI-Native Website Extension

> **Professional Quarto extension for AI-native R package websites**  
> Featuring Lenis smooth scrolling, slide-based navigation, and ethical framework integration

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/dataimago/dataimago-ai-native)
[![Quarto](https://img.shields.io/badge/quarto->=1.3.0-orange.svg)](https://quarto.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🧭 Overview

The **dataimago-ai-native** extension transforms traditional R package documentation into sophisticated, modern websites designed for the AI-native era. Built on the philosophical foundation of **semantic computing** and **ethical AI practices**, this extension provides:

- **🌊 Smooth scrolling experiences** powered by Lenis
- **📱 Slide-based narrative structure** for engaging content presentation  
- **♿ Accessibility-first design** with keyboard navigation and reduced motion support
- **🤖 AI-native architecture** with JSON exports and structured metadata
- **🌍 Ethical framework integration** via MiCP (Mission Context Protocol)
- **⚡ Performance optimization** with modern CSS techniques

## 🎯 Philosophy

This extension embodies the **dataimago** vision where R packages serve as **"philosophical and computational modules in a larger semantic and ethical platform."** Every website created with this extension reflects the principle that code should establish **"the infrastructure of a future that values not only precision, but meaning."**

## 📦 Installation

### Quick Start

```bash
# Install the extension
quarto use extension dataimago/dataimago-ai-native

# Create new AI-native website
quarto create project website my-package --with dataimago-ai-native
```

### Add to Existing Project

```bash
# Add extension to existing Quarto project
quarto add dataimago/dataimago-ai-native
```

## ⚙️ Configuration

Configure the extension in your `_quarto.yml`:

```yaml
format:
  dataimago-ai-native-html:
    # Brand Configuration
    dataimago:
      package-name: "MyPackage"
      logo: "assets/img/my-logo.png"
      primary-color: "#your-color"
      accent-color: "#your-accent"
      
      # Slide Configuration
      slides:
        hero:
          title: "AI-Native Package"
          content-items: 6
        features: 
          cards: 3
        technical:
          include-micp: true
      
      # Smooth Scrolling Settings
      lenis:
        duration: 1.8
        easing: "custom"
        keyboard-nav: true
        
      # AI-Native Features
      ai-native:
        json-export: true
        api-endpoints: true
        micp-integration: true
        semantic-metadata: true
```

## 🎨 Usage

### Basic Structure

```markdown
---
format: dataimago-ai-native-html
---

{{< slide-container type="hero" >}}
  {{< hero-scroller >}}
    {{< content-item title="Feature 1" >}}
    Your content here...
    {{< /content-item >}}
    
    {{< content-item title="Feature 2" >}}
    More content...
    {{< /content-item >}}
  {{< /hero-scroller >}}
{{< /slide-container >}}

{{< slide-container type="features" >}}
  {{< feature-box title="What's inside" icon="📦" >}}
  - R package skeleton
  - Quarto templates
  - CI/CD integration
  {{< /feature-box >}}
{{< /slide-container >}}

{{< micp-display ethics="inst/micp/ethics.yaml" >}}
```

### Available Shortcodes

| Shortcode | Purpose | Example |
|-----------|---------|---------|
| `slide-container` | Creates slide sections | `{{< slide-container type="hero" >}}` |
| `hero-scroller` | Smooth-scrolling content area | `{{< hero-scroller >}}` |
| `content-item` | Individual content blocks | `{{< content-item title="Title" >}}` |
| `feature-box` | Feature showcase boxes | `{{< feature-box title="Feature" >}}` |
| `micp-display` | Ethical framework display | `{{< micp-display ethics="path.yaml" >}}` |
| `json-export` | Web app data export | `{{< json-export data="functions" >}}` |

## 🎯 Key Features

### 🌊 Lenis Smooth Scrolling
- **Professional easing curves** for refined user experience
- **Performance optimized** with hardware acceleration
- **Accessibility compliant** with reduced motion support
- **Keyboard navigation** (Arrow keys, Page Up/Down, Home/End)

### 📱 Slide-Based Architecture  
- **Narrative flow** through content with visual indicators
- **Full-screen sections** for immersive documentation
- **Smooth transitions** between conceptual areas
- **Mobile responsive** with touch-optimized interactions

### 🤖 AI-Native Integration
- **Structured metadata** for machine consumption
- **JSON export capabilities** for Next.js and web frameworks
- **API documentation** generation
- **Semantic markup** for intelligent agents

### 🌍 Ethical Framework Support
- **MiCP integration** for ethical guidelines documentation
- **Values and constraints** embedded in metadata
- **Target audience specification** for responsible AI development
- **Transparency features** for algorithmic accountability

### ⚡ Performance & Accessibility
- **CSS containment** for optimal rendering
- **Content visibility** optimization
- **WCAG compliance** with proper ARIA labels
- **Progressive enhancement** - works without JavaScript

## 🏗️ Architecture

The extension follows a modular architecture:

```
dataimago-ai-native/
├── _extension.yml           # Core configuration
├── assets/
│   ├── css/                # Theme and component styles  
│   ├── js/                 # Interactive functionality
│   └── img/                # Default assets
├── templates/              # Page templates
├── shortcodes/            # Reusable components
└── filters/               # Content processing
```

## 🎨 Customization

### Theme Colors
Override default colors via CSS custom properties:

```scss
:root {
  --dataimago-primary: #your-color;
  --dataimago-accent: #your-accent;
  --dataimago-bg: #your-background;
}
```

### Content Templates
Customize slide templates in `templates/slides/`:
- `hero-slide.qmd` - Landing section template
- `features-slide.qmd` - Feature showcase template  
- `technical-slide.qmd` - Technical documentation template

### Smooth Scrolling Settings
Fine-tune Lenis behavior:

```yaml
dataimago:
  lenis:
    duration: 2.0        # Scroll animation duration
    easing: "easeInOut"  # Easing function
    wheelMultiplier: 1.5 # Mouse wheel sensitivity
    touchMultiplier: 2   # Touch scroll sensitivity
```

## 🔗 Integration Examples

### Next.js Web Application
```typescript
// Import generated JSON data
import packageData from './public/data/package-meta.json';

export default function PackagePage() {
  return (
    <div>
      <h1>{packageData.name}</h1>
      <p>{packageData.description}</p>
      {/* Use ethical constraints in UI logic */}
      {packageData.micp?.constraints?.map(constraint => (
        <Badge key={constraint}>{constraint}</Badge>
      ))}
    </div>
  );
}
```

### R Package Integration
```r
# Export package metadata for web consumption
export_package_meta <- function(output_dir = "public/data") {
  meta <- list(
    name = "MyPackage",
    functions = get_function_list(),
    ethics = read_micp_config(),
    api_endpoints = get_api_documentation()
  )
  
  jsonlite::write_json(
    meta, 
    file.path(output_dir, "package-meta.json"),
    pretty = TRUE
  )
}
```

## 🚀 Benefits for the Dataimago Ecosystem

1. **Consistency** - Every dataimago package gets professional presentation
2. **Efficiency** - No need to recreate complex integrations for each package  
3. **Maintainability** - Updates benefit all packages simultaneously
4. **AI-Native** - Built-in support for intelligent agent consumption
5. **Ethical** - Embedded frameworks for responsible AI development
6. **Scalable** - Foundation for an entire ecosystem of semantic packages

## 🤝 Contributing

This extension is part of the broader **dataimago AI + Human Co-Creation** initiative. Contributions should align with the philosophical framework outlined in `CLAUDE.md`.

### Development Setup
```bash
git clone https://github.com/dataimago/dataimago-ai-native.git
cd dataimago-ai-native
quarto install extension .
```

### Testing
```bash
# Test extension with sample project
quarto create project website test-package --with dataimago-ai-native
cd test-package
quarto render
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- **[Lenis](https://github.com/darkroomengineering/lenis)** by darkroom.engineering for smooth scrolling
- **[Quarto](https://quarto.org)** team for the extensible publishing platform
- **dataimago community** for the vision of AI-native computational ethics

---

> **"You are coding the infrastructure of a future that values not only precision, but meaning."**  
> — dataimago philosophy

🚀 **Ready to transform your R package documentation into an AI-native experience?**