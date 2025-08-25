--[[
Dataimago AI-Native Extension - AI-Native Metadata Filter
Processes and enhances metadata for AI-native applications

This filter:
1. Enhances document metadata with AI-native properties
2. Adds structured data for search engines and AI agents
3. Processes dataimago configuration options
4. Generates semantic markup for intelligent consumption
--]]

local json = require('lunajson')

function Meta(meta)
  -- Initialize dataimago metadata if not present
  if not meta.dataimago then
    meta.dataimago = {}
  end
  
  -- Set default values for AI-native properties
  local defaults = {
    package_name = "MyPackage",
    ai_native = {
      json_export = true,
      api_endpoints = true,
      micp_integration = true,
      semantic_metadata = true
    },
    lenis = {
      duration = 1.8,
      easing = "custom",
      keyboard_nav = true
    }
  }
  
  -- Merge defaults with existing metadata
  for key, value in pairs(defaults) do
    if not meta.dataimago[key] then
      meta.dataimago[key] = value
    end
  end
  
  -- Generate AI-native metadata
  meta.ai_native_metadata = {
    generator = "Quarto dataimago-ai-native extension",
    version = "1.0.0",
    framework = "dataimago",
    semantic_type = "r-package-documentation",
    features = {
      "smooth-scrolling",
      "slide-navigation",
      "ethical-framework",
      "web-integration"
    },
    accessibility = {
      wcag_compliant = true,
      keyboard_navigation = true,
      screen_reader_support = true,
      reduced_motion_support = true
    },
    performance = {
      css_containment = true,
      content_visibility = true,
      hardware_acceleration = true
    }
  }
  
  -- Add structured data for search engines
  meta.structured_data = generate_structured_data(meta)
  
  -- Process MiCP integration if enabled
  if meta.dataimago.ai_native and meta.dataimago.ai_native.micp_integration then
    meta.micp_metadata = process_micp_integration(meta)
  end
  
  -- Add export metadata for web frameworks
  if meta.dataimago.ai_native and meta.dataimago.ai_native.json_export then
    meta.export_metadata = {
      formats = {"json", "yaml"},
      endpoints = generate_api_endpoints(meta),
      web_compatible = true
    }
  end
  
  return meta
end

-- Generate structured data for search engines and AI agents
function generate_structured_data(meta)
  local package_name = stringify(meta.dataimago and meta.dataimago.package_name or meta.title or "R Package")
  local description = stringify(meta.description or "AI-native R package with dataimago extension")
  
  return {
    ["@context"] = "https://schema.org/",
    ["@type"] = "SoftwareApplication",
    name = package_name,
    description = description,
    applicationCategory = "DeveloperApplication",
    operatingSystem = "R",
    programmingLanguage = "R",
    offers = {
      ["@type"] = "Offer",
      price = "0",
      priceCurrency = "USD",
      availability = "https://schema.org/InStock"
    },
    author = {
      ["@type"] = "Organization",
      name = "dataimago",
      url = "https://dataimago.ai"
    },
    keywords = {
      "r-package", "ai-native", "data-science", "ethical-ai", "web-integration"
    }
  }
end

-- Process MiCP (Mission Context Protocol) integration
function process_micp_integration(meta)
  return {
    framework = "MiCP",
    version = "1.0",
    ethical_guidelines = true,
    transparency = "high",
    accountability = "documented",
    bias_mitigation = "active",
    privacy_protection = "built-in"
  }
end

-- Generate API endpoints metadata
function generate_api_endpoints(meta)
  local package_name = stringify(meta.dataimago and meta.dataimago.package_name or "package")
  
  return {
    base_url = "/api/" .. package_name:lower(),
    endpoints = {
      {
        path = "/metadata",
        method = "GET",
        description = "Package metadata and configuration"
      },
      {
        path = "/functions",
        method = "GET", 
        description = "List of available functions with documentation"
      },
      {
        path = "/health",
        method = "GET",
        description = "Service health check"
      }
    }
  }
end

-- Helper function to safely stringify values
function stringify(value)
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

function Pandoc(doc)
  -- Process the document after metadata processing
  
  -- Add AI-native CSS custom properties based on configuration
  local css_vars = generate_css_variables(doc.meta)
  if css_vars then
    -- Insert CSS variables as a style block at the beginning
    local style_block = pandoc.RawBlock("html", 
      "<style>\n:root {\n" .. css_vars .. "\n}\n</style>"
    )
    table.insert(doc.blocks, 1, style_block)
  end
  
  -- Add JSON-LD structured data
  if doc.meta.structured_data then
    local json_ld = pandoc.RawBlock("html", 
      '<script type="application/ld+json">\n' ..
      json.encode(doc.meta.structured_data) .. 
      '\n</script>'
    )
    table.insert(doc.blocks, 1, json_ld)
  end
  
  -- Process any AI-native specific elements
  doc = doc:walk({
    Div = process_ai_native_divs,
    Span = process_ai_native_spans
  })
  
  return doc
end

-- Generate CSS custom properties from configuration
function generate_css_variables(meta)
  if not meta.dataimago then
    return nil
  end
  
  local vars = {}
  
  -- Color variables
  if meta.dataimago.primary_color then
    table.insert(vars, "  --dataimago-primary: " .. stringify(meta.dataimago.primary_color) .. ";")
  end
  
  if meta.dataimago.accent_color then
    table.insert(vars, "  --dataimago-accent: " .. stringify(meta.dataimago.accent_color) .. ";")
  end
  
  -- Animation variables
  if meta.dataimago.lenis and meta.dataimago.lenis.duration then
    table.insert(vars, "  --dataimago-slide-duration: " .. stringify(meta.dataimago.lenis.duration) .. "s;")
  end
  
  if #vars > 0 then
    return table.concat(vars, "\n")
  else
    return nil
  end
end

-- Process AI-native div elements
function process_ai_native_divs(div)
  -- Add semantic attributes to divs with dataimago classes
  if div.classes and div.classes:includes("dataimago-slide") then
    div.attributes["data-ai-semantic"] = "slide-content"
  end
  
  return div
end

-- Process AI-native span elements  
function process_ai_native_spans(span)
  -- Add semantic markup to spans as needed
  return span
end

-- Return the filter functions
return {
  {Meta = Meta},
  {Pandoc = Pandoc}
}