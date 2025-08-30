# Filters Directory

This directory contains Lua filter implementations that process and enhance content during the Quarto rendering pipeline for the dataimago-ai-native extension.

## 📁 Filter Files

```
filters/
├── ai-native-meta.lua     # Metadata processing and enhancement
└── json-export.lua        # JSON export processing and generation
```

## 🔧 Filter Functions

### `ai-native-meta.lua`
Processes and enhances metadata for AI-native applications.

**Functions:**
- **`Meta(meta)`**: Enhances document metadata with AI-native properties
- **`Pandoc(doc)`**: Processes document structure and adds generated content

**Features:**
- Adds structured data for search engines (JSON-LD)
- Generates CSS custom properties from configuration
- Creates semantic markup for AI consumption
- Processes MiCP (Mission Context Protocol) integration
- Adds accessibility enhancements

**Example Output:**
```html
<!-- Generated JSON-LD structured data -->
<script type="application/ld+json">
{
  "@context": "https://schema.org/",
  "@type": "SoftwareApplication",
  "name": "MyPackage",
  "description": "AI-native R package"
}
</script>

<!-- Generated CSS variables -->
<style>
:root {
  --dataimago-primary: #83838f;
  --dataimago-accent: #ff69b4;
  --dataimago-slide-duration: 1.8s;
}
</style>
```

### `json-export.lua`
Processes JSON export requests and generates structured data files.

**Functions:**
- **`Pandoc(doc)`**: Finds and processes JSON export script tags
- **`process_export_request()`**: Generates export data based on document content
- **`generate_export_data()`**: Creates structured data for different export types

**Export Types:**
- `package-metadata`: Package information and configuration
- `functions`: API documentation and function reference
- `technical-documentation`: Installation and integration guides

## 🔄 Filter Pipeline

### Processing Order
1. **Meta filter** runs first to enhance metadata
2. **Content filters** process document structure
3. **Export filter** runs last to generate output files

### Data Flow
```
Document Metadata → Meta Filter → Enhanced Metadata
Document Content → Export Filter → Generated JSON Files
```

## 📊 Metadata Enhancement

### AI-Native Properties
```yaml
# Enhanced metadata structure
ai_native_metadata:
  generator: "Quarto dataimago-ai-native extension"
  version: "1.0.0"
  framework: "dataimago"
  semantic_type: "r-package-documentation"
  features:
    - "smooth-scrolling"
    - "slide-navigation"
    - "ethical-framework"
  accessibility:
    wcag_compliant: true
    keyboard_navigation: true
    screen_reader_support: true
```

### Structured Data Generation
```json
{
  "@context": "https://schema.org/",
  "@type": "SoftwareApplication",
  "name": "Package Name",
  "applicationCategory": "DeveloperApplication",
  "operatingSystem": "R",
  "programmingLanguage": "R",
  "author": {
    "@type": "Organization",
    "name": "dataimago"
  }
}
```

## 📤 JSON Export System

### Export Data Types
```lua
-- Package metadata export
{
  package = {
    name = "PackageName",
    version = "1.0.0",
    description = "Package description"
  },
  features = {
    ai_native = true,
    smooth_scrolling = true,
    slide_navigation = true
  },
  configuration = { /* dataimago config */ }
}

-- Functions export
{
  functions = [
    {
      name = "main_function",
      description = "Primary processing function",
      parameters = [/* parameter info */],
      examples = [/* usage examples */]
    }
  ],
  api_info = {
    base_url = "/api/package",
    version = "v1"
  }
}
```

### Output Files
Generated files are created in structured format:
- `public/data/package-metadata.json`
- `public/data/functions.json`
- `public/data/technical-documentation.json`

## 🧪 Filter Development

### Lua Filter Pattern
```lua
function Meta(meta)
  -- Process metadata
  meta.enhanced_property = generate_enhanced_data(meta)
  return meta
end

function Pandoc(doc)
  -- Process document structure
  doc = doc:walk({
    Div = process_divs,
    Span = process_spans
  })
  return doc
end

-- Return filter functions
return {
  {Meta = Meta},
  {Pandoc = Pandoc}
}
```

### Element Processing
```lua
function process_divs(div)
  -- Add semantic attributes
  if div.classes:includes("dataimago-slide") then
    div.attributes["data-ai-semantic"] = "slide-content"
  end
  return div
end
```

### Metadata Manipulation
```lua
function enhance_metadata(meta)
  -- Add default values
  if not meta.dataimago then
    meta.dataimago = {}
  end

  -- Merge with defaults
  local defaults = { /* default values */ }
  meta.dataimago = merge_tables(defaults, meta.dataimago)

  return meta
end
```

## 🎨 CSS Generation

### Dynamic CSS Properties
Filters can generate CSS based on document metadata:

```lua
function generate_css_variables(meta)
  local vars = {}

  if meta.dataimago.primary_color then
    table.insert(vars, "--dataimago-primary: " .. meta.dataimago.primary_color)
  end

  return table.concat(vars, ";\n")
end
```

### Responsive Integration
Generated CSS integrates with responsive design:

```css
/* Generated by filter */
:root {
  --dataimago-primary: #83838f;
  --dataimago-accent: #ff69b4;
}

/* Used in components */
.dataimago-slide-indicator {
  border-color: var(--dataimago-primary);
}
```

## 🔍 Content Analysis

### Function Extraction
Filters can analyze document content to extract function information:

```lua
function extract_functions(blocks)
  local functions = {}

  for _, block in pairs(blocks) do
    if block.t == "CodeBlock" and block.classes:includes("r") then
      -- Parse R code for function definitions
      local func_info = parse_r_function(block.text)
      if func_info then
        table.insert(functions, func_info)
      end
    end
  end

  return functions
end
```

### Documentation Mining
Extract documentation patterns:

```lua
function extract_documentation(blocks)
  local docs = {}

  -- Look for documentation patterns
  for i, block in pairs(blocks) do
    if is_function_documentation(block, blocks[i+1]) then
      table.insert(docs, parse_documentation(block, blocks[i+1]))
    end
  end

  return docs
end
```

## 🌐 Web Integration

### API Endpoint Generation
```lua
function generate_api_endpoints(meta)
  local package_name = stringify(meta.dataimago.package_name)

  return {
    base_url = "/api/" .. package_name:lower(),
    endpoints = {
      {path = "/metadata", method = "GET"},
      {path = "/functions", method = "GET"},
      {path = "/health", method = "GET"}
    }
  }
end
```

### Next.js Compatibility
```lua
function generate_nextjs_config(meta)
  return {
    package_info = extract_package_info(meta),
    api_routes = generate_api_routes(meta),
    static_exports = list_static_exports(meta)
  }
end
```

## 📋 Best Practices

### Error Handling
```lua
function safe_stringify(value)
  if value == nil then
    return ""
  elseif type(value) == "string" then
    return value
  elseif type(value) == "table" and value.text then
    return table.concat(value.text, " ")
  else
    return tostring(value)
  end
end
```

### Performance Optimization
- **Lazy processing**: Only process when needed
- **Efficient table operations**: Use appropriate data structures
- **Minimal DOM walking**: Targeted element processing
- **Caching**: Store computed values when possible

### Debugging
```lua
function debug_log(message, data)
  if os.getenv("DATAIMAGO_DEBUG") then
    print("DEBUG: " .. message)
    if data then
      print("DATA: " .. tostring(data))
    end
  end
end
```

## 🧪 Testing Filters

### Unit Testing
```bash
# Test metadata enhancement
echo '---
title: Test
dataimago:
  package-name: TestPkg
---' | quarto render --to html --lua-filter filters/ai-native-meta.lua
```

### Integration Testing
```bash
# Test full pipeline
quarto render test-document.qmd --to dataimago-ai-native-html
```

### Debug Mode
```bash
# Enable debugging output
DATAIMAGO_DEBUG=1 quarto render document.qmd
```

## 🔧 Extending Filters

### Adding New Filters
1. **Create new `.lua` file** with descriptive name
2. **Implement required functions** (Meta, Pandoc, etc.)
3. **Add to extension configuration** in `_extension.yml`
4. **Document functionality** and usage
5. **Test thoroughly** with sample content

### Modifying Existing Filters
1. **Maintain backward compatibility** for existing functionality
2. **Add feature flags** for new capabilities
3. **Update documentation** with changes
4. **Version appropriately** for breaking changes

## 📚 References

- **[Pandoc Lua Filters](https://pandoc.org/lua-filters.html)**: Official documentation
- **[Quarto Filters](https://quarto.org/docs/extensions/filters.html)**: Quarto-specific guidance
- **[Lua Reference](https://www.lua.org/manual/5.4/)**: Lua language documentation
- **[JSON-LD](https://json-ld.org/)**: Structured data format
- **[Schema.org](https://schema.org/)**: Structured data vocabulary