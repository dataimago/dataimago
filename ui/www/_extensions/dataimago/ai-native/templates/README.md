# Templates Directory

This directory contains template files for the dataimago-ai-native Quarto extension, providing ready-to-use page layouts and content structures.

## 📁 Directory Structure

```
templates/
├── index.qmd              # Complete homepage template
├── slides/                # Individual slide templates
│   ├── hero-slide.qmd     # Hero section template
│   ├── features-slide.qmd # Features showcase template
│   └── technical-slide.qmd # Technical documentation template
```

## 🏠 Main Templates

### `index.qmd`
Complete homepage template demonstrating:
- **Full slide-based layout** with three main sections
- **Hero section** with logo and content scroller
- **Features section** with showcase cards
- **Technical section** with documentation and MiCP integration
- **Proper metadata configuration** for all extension features

**Usage:**
```bash
# Copy to your project root
cp templates/index.qmd ./index.qmd

# Customize the dataimago configuration
# Edit package-name, logo, colors, etc.
```

## 📄 Slide Templates

### `hero-slide.qmd`
Landing slide template featuring:
- **Logo display** with branding elements
- **Package metadata** display
- **Hero scroller** for showcasing features
- **Action buttons** for navigation

**Usage:**
```markdown
{{< include templates/slides/hero-slide.qmd >}}
```

### `features-slide.qmd`
Features showcase template with:
- **Feature cards** in responsive grid layout
- **Icon integration** for visual appeal
- **Animation support** with fade-in effects
- **Flexible content structure**

**Configuration:**
```yaml
dataimago:
  slides:
    features:
      title: "Why Choose Our Package"
      description: "Key benefits and capabilities"
```

### `technical-slide.qmd`
Technical documentation template including:
- **Installation instructions** with code blocks
- **API documentation** examples
- **Integration guides** for web frameworks
- **MiCP ethical framework** display
- **Performance and testing information**

## ⚙️ Configuration

### Metadata Structure
All templates use consistent metadata structure:

```yaml
---
format: dataimago-ai-native-html
dataimago:
  package-name: "YourPackage"        # Package name
  logo: "assets/img/logo.png"        # Logo path
  primary-color: "#83838f"           # Brand colors
  accent-color: "#ff69b4"

  slides:                            # Slide configuration
    hero:
      title: "AI-Native R Package"
      content-items: 6
    features:
      cards: 3
    technical:
      include-micp: true

  lenis:                             # Smooth scrolling
    duration: 1.8
    easing: "custom"
    keyboard-nav: true

  ai-native:                         # AI integration
    json-export: true
    api-endpoints: true
    micp-integration: true
    semantic-metadata: true
---
```

## 🎨 Customization

### Template Modification
Templates are designed to be customized:

1. **Content replacement**: Update text and structure as needed
2. **Color theming**: Modify CSS custom properties
3. **Layout adjustments**: Change grid configurations
4. **Component selection**: Include/exclude features as needed

### Example Customizations
```yaml
# Custom branding
dataimago:
  package-name: "MyAnalytics"
  logo: "assets/img/my-logo.svg"
  primary-color: "#2563eb"
  accent-color: "#7c3aed"

# Custom slide content
slides:
  hero:
    title: "Advanced Analytics Platform"
    description: "Powerful R package for data analysis"
    content-items: 4
```

## 🧩 Shortcode Usage

Templates demonstrate all available shortcodes:

### Slide Container
```markdown
{{< slide-container type="hero" title="Landing Section" >}}
Content here...
{{< /slide-container >}}
```

### Hero Scroller
```markdown
{{< hero-scroller height="70vh" >}}
  {{< content-item title="Feature 1" icon="🚀" >}}
  Description of feature...
  {{< /content-item >}}
{{< /hero-scroller >}}
```

### Feature Box
```markdown
{{< feature-box title="Core Features" icon="⚙️" animate="fade-up" >}}
- List of features
- With bullet points
- Easy to scan
{{< /feature-box >}}
```

### MiCP Display
```markdown
{{< micp-display ethics="inst/micp/ethics.yaml" >}}
```

### JSON Export
```markdown
{{< json-export data="package-metadata" display="true" >}}
```

## 🎯 Template Types

### Complete Website Template (`index.qmd`)
- **Full-featured homepage** with all extension capabilities
- **Three-slide structure** for narrative flow
- **Professional presentation** ready for production use

### Component Templates (`slides/`)
- **Modular slide sections** for flexible composition
- **Reusable patterns** for consistency across projects
- **Customizable content areas** for different package types

## 📋 Best Practices

### Content Structure
1. **Clear hierarchy**: Use proper heading levels (h2, h3, h4)
2. **Scannable content**: Use bullet points and short paragraphs
3. **Visual breaks**: Separate sections with whitespace
4. **Call-to-action**: Include clear next steps for users

### Accessibility
1. **Semantic markup**: Use proper HTML elements and ARIA labels
2. **Alt text**: Provide descriptive alt text for images
3. **Color contrast**: Ensure sufficient contrast ratios
4. **Keyboard navigation**: Test with keyboard-only navigation

### Performance
1. **Image optimization**: Use appropriately sized images
2. **Content loading**: Consider above-the-fold content priority
3. **Animation performance**: Use CSS transforms for animations
4. **Bundle size**: Keep templates focused and minimal

## 🔧 Development Workflow

### Creating New Templates
1. **Start with existing template** as a base
2. **Modify content structure** as needed
3. **Update metadata configuration** appropriately
4. **Test across devices** and browsers
5. **Document customization options**

### Template Testing
```bash
# Test template with sample data
quarto render templates/index.qmd

# Test individual slides
quarto render templates/slides/hero-slide.qmd
```

## 🌐 Integration Examples

### R Package Integration
```r
# Generate template with package data
create_dataimago_site <- function(package_name, output_dir = ".") {
  template_path <- system.file("templates", "index.qmd", package = "dataimago")

  # Customize template with package information
  template_content <- readLines(template_path)
  template_content <- gsub("{{PACKAGE_NAME}}", package_name, template_content)

  writeLines(template_content, file.path(output_dir, "index.qmd"))
}
```

### Next.js Integration
```typescript
// Use template structure for web components
interface SlideData {
  type: 'hero' | 'features' | 'technical';
  title: string;
  content: string;
}

const SlideComponent = ({ slide }: { slide: SlideData }) => (
  <section className={`dataimago-slide dataimago-slide-${slide.type}`}>
    <h2>{slide.title}</h2>
    <div>{slide.content}</div>
  </section>
);
```

## 📚 Additional Resources

- **[Quarto Documentation](https://quarto.org)**: Official Quarto guides
- **[Extension API](https://quarto.org/docs/extensions/)**: Quarto extension development
- **[Lenis Documentation](https://github.com/darkroomengineering/lenis)**: Smooth scrolling library
- **[WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)**: Accessibility standards