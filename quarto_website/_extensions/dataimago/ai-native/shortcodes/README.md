# Shortcodes Directory

This directory contains Lua shortcode implementations that provide reusable components for the dataimago-ai-native Quarto extension.

## 📁 Shortcode Files

```
shortcodes/
├── slide-container.lua     # Slide-based content sections
├── hero-scroller.lua      # Smooth-scrolling content areas
├── content-item.lua       # Individual content blocks
├── feature-box.lua        # Feature showcase boxes
├── micp-display.lua       # Ethical framework display
└── json-export.lua        # Data export for web apps
```

## 🧩 Available Shortcodes

### `slide-container`
Creates slide-based content sections with proper semantic markup.

**Usage:**
```markdown
{{< slide-container type="hero" title="Landing Section" >}}
Content goes here...
{{< /slide-container >}}
```

**Parameters:**
- `type`: "hero", "features", "technical", or custom type
- `id`: Optional custom ID for the slide
- `class`: Additional CSS classes
- `title`: Optional slide title for screen readers

**Generated HTML:**
```html
<section class="dataimago-slide lenis-slide dataimago-slide-hero" 
         data-slide-type="hero" 
         role="region" 
         aria-label="Landing Section">
  <!-- Content -->
</section>
```

### `hero-scroller`
Creates smooth-scrolling hero content areas (carousel replacement).

**Usage:**
```markdown
{{< hero-scroller height="70vh" indicator="true" >}}
{{< content-item title="Item 1" >}}Content...{{< /content-item >}}
{{< content-item title="Item 2" >}}More content...{{< /content-item >}}
{{< /hero-scroller >}}
```

**Parameters:**
- `height`: Custom height (default: 60vh)
- `class`: Additional CSS classes  
- `id`: Custom container ID
- `indicator`: Show scroll progress indicator (default: true)

### `content-item`
Creates individual content items for hero scrollers.

**Usage:**
```markdown
{{< content-item title="Feature Title" icon="🚀" animate="fade-up" >}}
Description of the feature or content goes here.
{{< /content-item >}}
```

**Parameters:**
- `title`: The title of the content item (required)
- `icon`: Optional icon/emoji to display
- `animate`: Animation type for the item
- `class`: Additional CSS classes

### `feature-box`
Creates styled feature showcase boxes.

**Usage:**
```markdown
{{< feature-box title="Core Features" icon="⚙️" animate="fade-up" >}}
- List your main features here
- Each feature should be concise
- Use bullet points for clarity
{{< /feature-box >}}
```

**Parameters:**
- `title`: The title of the feature box (required)
- `icon`: Optional icon/emoji to display with title
- `animate`: Animation type (default: "fade-up")
- `class`: Additional CSS classes
- `color`: Optional accent color for the box

### `micp-display`
Displays Mission Context Protocol (MiCP) ethical framework information.

**Usage:**
```markdown
{{< micp-display ethics="inst/micp/ethics.yaml" >}}

{{< micp-display title="Custom Ethics Framework" >}}
must:
  - Protect user privacy
  - Ensure data accuracy
must_not:
  - Discriminate based on demographics
can:
  - Cache results for performance
{{< /micp-display >}}
```

**Parameters:**
- `ethics`: Path to YAML file containing MiCP configuration
- `title`: Custom title for the MiCP section
- `class`: Additional CSS classes

### `json-export`
Exports structured data for web application consumption.

**Usage:**
```markdown
{{< json-export data="package-metadata" format="pretty" display="true" >}}
{{< json-export data="functions" output="public/data/api.json" >}}
```

**Parameters:**
- `data`: Type of data to export ("package-metadata", "functions", "technical-documentation")
- `format`: "compact" or "pretty" (default: "pretty")
- `output`: Output file path (relative to project root)
- `display`: Whether to display the JSON in the document (default: false)

## 🔧 Shortcode Development

### Lua Implementation Pattern
All shortcodes follow a consistent pattern:

```lua
function Shortcode_name(args, kwargs, content)
  -- Get parameters
  local param1 = pandoc.utils.stringify(args[1] or kwargs.param1 or "default")
  
  -- Process content
  local processed_content = pandoc.read(content, "markdown").blocks
  
  -- Generate HTML
  local html_start = "<div class='component'>"
  local html_end = "</div>"
  
  -- Return structured blocks
  return {
    pandoc.RawBlock("html", html_start),
    processed_content,
    pandoc.RawBlock("html", html_end)
  }
end

return {
  ["shortcode-name"] = Shortcode_name
}
```

### Parameter Handling
```lua
-- Positional arguments
local title = pandoc.utils.stringify(args[1] or "")

-- Named arguments with defaults
local custom_class = pandoc.utils.stringify(kwargs.class or "")

-- Boolean parameters
local show_indicator = pandoc.utils.stringify(kwargs.indicator or "true") == "true"
```

### Content Processing
```lua
-- Process markdown content
if content and content ~= "" then
  local content_blocks = pandoc.read(content, "markdown").blocks
  processed_content = content_blocks
else
  processed_content = {}
end
```

## 🎨 Styling Integration

### CSS Classes
Each shortcode generates consistent CSS classes:

```css
/* Slide containers */
.dataimago-slide { /* Base slide styles */ }
.dataimago-slide-hero { /* Hero-specific styles */ }
.dataimago-slide-features { /* Features-specific styles */ }

/* Content components */
.dataimago-content-item { /* Content item styles */ }
.dataimago-feature-box { /* Feature box styles */ }
.dataimago-micp-container { /* MiCP display styles */ }
```

### Animation Classes
```css
/* Animation states */
[data-dataimago-animate] { /* Initial state */ }
[data-dataimago-animate].dataimago-animate-active { /* Animated state */ }

/* Animation types */
[data-dataimago-animate="fade-up"] { transform: translateY(30px); opacity: 0; }
[data-dataimago-animate="fade-left"] { transform: translateX(30px); opacity: 0; }
[data-dataimago-animate="scale"] { transform: scale(0.95); opacity: 0; }
```

## ♿ Accessibility Features

### Semantic Markup
All shortcodes generate proper semantic HTML:
- `role` attributes for complex components
- `aria-label` for screen reader descriptions
- `tabindex` for keyboard navigation
- Proper heading hierarchy

### Keyboard Navigation
Components support keyboard interaction:
- Tab navigation through interactive elements
- Arrow key navigation where appropriate
- Enter/Space for activation
- Escape for dismissal

### Screen Reader Support
- Live regions for dynamic announcements
- Descriptive labels for all interactive elements
- Progress indicators for scrolling content
- Slide change announcements

## 🚀 Performance Considerations

### Efficient HTML Generation
- Minimal DOM manipulation
- CSS-based animations over JavaScript
- Lazy loading for off-screen content
- Efficient event binding

### Rendering Optimization
- CSS containment for complex components
- Content-visibility for performance
- Hardware acceleration for animations
- Minimal reflows and repaints

## 🧪 Testing Shortcodes

### Basic Testing
```bash
# Test individual shortcode
echo '{{< slide-container type="test" >}}Content{{< /slide-container >}}' | quarto render --to html

# Test with parameters
echo '{{< feature-box title="Test" icon="🧪" >}}Testing content{{< /feature-box >}}' | quarto render --to html
```

### Integration Testing
```markdown
---
format: dataimago-ai-native-html
---

# Test Document

{{< slide-container type="hero" >}}
{{< hero-scroller >}}
{{< content-item title="Test Item" >}}
This is a test of nested shortcodes.
{{< /content-item >}}
{{< /hero-scroller >}}
{{< /slide-container >}}
```

## 🔄 Extending Shortcodes

### Adding New Shortcodes
1. **Create new `.lua` file** in shortcodes directory
2. **Follow naming convention**: `shortcode-name.lua`
3. **Implement function pattern** shown above
4. **Register shortcode** in return statement
5. **Update extension configuration** to include new shortcode

### Modifying Existing Shortcodes
1. **Maintain backward compatibility** for existing parameters
2. **Add new parameters** with sensible defaults
3. **Update documentation** with new features
4. **Test thoroughly** across different use cases

## 📚 References

- **[Quarto Shortcodes](https://quarto.org/docs/extensions/shortcodes.html)**: Official documentation
- **[Pandoc Lua API](https://pandoc.org/lua-filters.html)**: Lua scripting reference
- **[Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)**: WCAG compliance
- **[HTML Semantic Elements](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)**: MDN reference