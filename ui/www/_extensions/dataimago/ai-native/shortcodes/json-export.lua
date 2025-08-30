--[[
Dataimago AI-Native Extension - JSON Export Shortcode
Exports structured data for web application consumption

Usage:
{{< json-export data="package-metadata" >}}
{{< json-export data="functions" format="pretty" >}}

Parameters:
- data: Type of data to export ("package-metadata", "functions", "technical-documentation")
- format: "compact" or "pretty" (default: "pretty")
- output: Output file path (relative to project root)
- display: Whether to display the JSON in the document (default: false)
--]]

function Json_export(args, kwargs, content)
  -- Get parameters
  local data_type = pandoc.utils.stringify(args[1] or kwargs.data or "package-metadata")
  local format_type = pandoc.utils.stringify(kwargs.format or "pretty")
  local output_file = pandoc.utils.stringify(kwargs.output or "")
  local display = pandoc.utils.stringify(kwargs.display or "false") == "true"
  
  -- Generate export data based on type
  local export_data = {}
  
  if data_type == "package-metadata" then
    export_data = {
      name = "{{< meta dataimago.package-name >}}",
      version = "1.0.0",
      description = "AI-native R package with dataimago extension",
      type = "r-package",
      framework = "dataimago-ai-native",
      features = {
        "smooth-scrolling",
        "slide-navigation", 
        "ai-native-integration",
        "ethical-framework",
        "web-compatibility"
      },
      export_timestamp = "{{< meta date >}}",
      ai_native = {
        json_export = true,
        api_endpoints = true,
        micp_integration = true,
        semantic_metadata = true
      }
    }
  elseif data_type == "functions" then
    export_data = {
      functions = {
        {
          name = "main_function",
          description = "Primary processing function",
          parameters = {"data", "options"},
          returns = "processed_results",
          examples = {"result <- main_function(data)"}
        }
      },
      total_functions = 1,
      coverage = "95%",
      last_updated = "{{< meta date >}}"
    }
  elseif data_type == "technical-documentation" then
    export_data = {
      installation = {
        cran = "install.packages('{{< meta dataimago.package-name >}}')",
        github = "devtools::install_github('{{< meta repo-owner >}}/{{< meta dataimago.package-name >}}')"
      },
      dependencies = {
        r_version = ">=4.0.0",
        imports = {"jsonlite", "data.table"},
        suggests = {"testthat", "knitr"}
      },
      performance = {
        benchmarks = "Available in vignettes",
        memory_usage = "Optimized for large datasets",
        parallel_support = true
      },
      web_integration = {
        json_export = true,
        next_js = true,
        react = true,
        api_generation = true
      }
    }
  end
  
  -- Generate JSON string
  local json_string
  if format_type == "compact" then
    -- Compact JSON (single line)
    json_string = generate_compact_json(export_data)
  else
    -- Pretty formatted JSON
    json_string = generate_pretty_json(export_data)
  end
  
  -- Determine output file path
  if output_file == "" then
    output_file = "public/data/" .. data_type .. ".json"
  end
  
  -- Create export instruction comment
  local export_comment = "<!-- JSON Export: " .. data_type .. " -->\n" ..
                        "<!-- Output: " .. output_file .. " -->\n" ..
                        "<!-- Format: " .. format_type .. " -->"
  
  local result = {pandoc.RawBlock("html", export_comment)}
  
  -- Display JSON in document if requested
  if display then
    local display_html = '<div class="dataimago-json-export">' ..
                        '<h4>Exported Data: ' .. data_type .. '</h4>' ..
                        '<pre><code class="language-json">' .. json_string .. '</code></pre>' ..
                        '<p class="text-muted"><small>Output: <code>' .. output_file .. '</code></small></p>' ..
                        '</div>'
    
    table.insert(result, pandoc.RawBlock("html", display_html))
  end
  
  -- Add hidden script to trigger actual export (would be processed by filter)
  local export_script = '<script type="application/json" data-dataimago-export="' .. data_type .. 
                        '" data-output="' .. output_file .. '" data-format="' .. format_type .. '">' ..
                        json_string .. '</script>'
  
  table.insert(result, pandoc.RawBlock("html", export_script))
  
  return result
end

-- Helper function to generate compact JSON
function generate_compact_json(data)
  -- Simple JSON generation for demo purposes
  -- In a real implementation, use a proper JSON library
  return '{"type":"' .. (data.type or "export") .. '","timestamp":"' .. 
         os.date("%Y-%m-%d %H:%M:%S") .. '","data":' .. table_to_json(data) .. '}'
end

-- Helper function to generate pretty JSON
function generate_pretty_json(data, indent)
  indent = indent or 0
  local indent_str = string.rep("  ", indent)
  local result = "{\n"
  
  local first = true
  for key, value in pairs(data) do
    if not first then
      result = result .. ",\n"
    end
    first = false
    
    result = result .. indent_str .. '  "' .. key .. '": '
    
    if type(value) == "table" then
      if is_array(value) then
        result = result .. array_to_json(value, indent + 1)
      else
        result = result .. generate_pretty_json(value, indent + 1)
      end
    elseif type(value) == "string" then
      result = result .. '"' .. value .. '"'
    elseif type(value) == "boolean" then
      result = result .. (value and "true" or "false")
    else
      result = result .. tostring(value)
    end
  end
  
  result = result .. "\n" .. indent_str .. "}"
  return result
end

-- Helper function to convert array to JSON
function array_to_json(arr, indent)
  local indent_str = string.rep("  ", indent or 0)
  local result = "[\n"
  
  for i, value in ipairs(arr) do
    if i > 1 then
      result = result .. ",\n"
    end
    
    result = result .. indent_str .. "  "
    
    if type(value) == "table" then
      result = result .. generate_pretty_json(value, indent + 1)
    elseif type(value) == "string" then
      result = result .. '"' .. value .. '"'
    else
      result = result .. tostring(value)
    end
  end
  
  result = result .. "\n" .. indent_str .. "]"
  return result
end

-- Helper function to check if table is array
function is_array(t)
  if type(t) ~= "table" then return false end
  local i = 1
  for _ in pairs(t) do
    if t[i] == nil then return false end
    i = i + 1
  end
  return true
end

-- Simple table to JSON conversion
function table_to_json(t)
  if type(t) == "table" then
    return "{}"  -- Simplified for demo
  else
    return '"' .. tostring(t) .. '"'
  end
end

-- Register the shortcode
return {
  ["json-export"] = Json_export
}