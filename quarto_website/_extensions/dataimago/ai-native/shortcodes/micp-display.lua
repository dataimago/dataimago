--[[
Dataimago AI-Native Extension - MiCP Display Shortcode
Displays Mission Context Protocol (MiCP) ethical framework information

Usage:
{{< micp-display ethics="inst/micp/ethics.yaml" >}}

or with inline data:
{{< micp-display >}}
must:
  - Protect user privacy
  - Ensure data accuracy
must_not:
  - Discriminate based on demographics
  - Expose sensitive information
can:
  - Cache results for performance
  - Log aggregated usage statistics
{{< /micp-display >}}

Parameters:
- ethics: Path to YAML file containing MiCP configuration
- title: Custom title for the MiCP section
- class: Additional CSS classes
--]]

function Micp_display(args, kwargs, content)
  -- Get parameters
  local ethics_file = pandoc.utils.stringify(args[1] or kwargs.ethics or "")
  local custom_title = pandoc.utils.stringify(kwargs.title or "Ethical Framework (MiCP)")
  local extra_class = pandoc.utils.stringify(kwargs.class or "")
  
  -- Initialize MiCP data structure
  local micp_data = {
    must = {},
    must_not = {},
    can = {},
    target_audiences = {},
    version = "1.0",
    description = "Mission Context Protocol for ethical AI development"
  }
  
  -- Try to load from file if provided
  local file_loaded = false
  if ethics_file ~= "" then
    -- Note: In a real implementation, you would need to add file reading capability
    -- For now, we'll indicate that a file should be loaded
    file_loaded = true
    micp_data.description = "Loaded from " .. ethics_file
  end
  
  -- Parse inline content if provided and no file was specified
  if content and content ~= "" and type(content) == "string" and not file_loaded then
    -- Simple YAML-like parsing for demo purposes
    -- In a real implementation, you'd use a proper YAML parser
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
    
    local current_section = nil
    for _, line in ipairs(lines) do
      line = line:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace
      
      if line:match("^must:") then
        current_section = "must"
      elseif line:match("^must_not:") then
        current_section = "must_not"
      elseif line:match("^can:") then
        current_section = "can"
      elseif line:match("^target_audiences:") then
        current_section = "target_audiences"
      elseif line:match("^- ") and current_section then
        local item = line:gsub("^- ", "")
        table.insert(micp_data[current_section], item)
      end
    end
  end
  
  -- Build CSS classes
  local css_classes = {"dataimago-micp-container"}
  if extra_class ~= "" then
    table.insert(css_classes, extra_class)
  end
  
  -- Create container
  local container_start = '<div class="' .. table.concat(css_classes, " ") .. 
                         '" role="region" aria-label="Ethical framework information">'
  
  -- Build header
  local header_html = '<div class="dataimago-micp-header">' ..
                     '<h3>' .. custom_title .. '</h3>' ..
                     '<p>' .. micp_data.description .. '</p>' ..
                     '</div>'
  
  -- Build sections
  local sections_html = ""
  
  -- Must section
  if #micp_data.must > 0 then
    sections_html = sections_html .. '<div class="dataimago-micp-section">' ..
                   '<h4 data-icon="✓">Requirements</h4>' ..
                   '<ul class="dataimago-micp-rules">'
    
    for _, item in ipairs(micp_data.must) do
      sections_html = sections_html .. '<li class="must">' .. item .. '</li>'
    end
    
    sections_html = sections_html .. '</ul></div>'
  end
  
  -- Must not section
  if #micp_data.must_not > 0 then
    sections_html = sections_html .. '<div class="dataimago-micp-section">' ..
                   '<h4 data-icon="✗">Prohibitions</h4>' ..
                   '<ul class="dataimago-micp-rules">'
    
    for _, item in ipairs(micp_data.must_not) do
      sections_html = sections_html .. '<li class="must-not">' .. item .. '</li>'
    end
    
    sections_html = sections_html .. '</ul></div>'
  end
  
  -- Can section
  if #micp_data.can > 0 then
    sections_html = sections_html .. '<div class="dataimago-micp-section">' ..
                   '<h4 data-icon="◦">Permissions</h4>' ..
                   '<ul class="dataimago-micp-rules">'
    
    for _, item in ipairs(micp_data.can) do
      sections_html = sections_html .. '<li class="can">' .. item .. '</li>'
    end
    
    sections_html = sections_html .. '</ul></div>'
  end
  
  -- Add default content if no rules are defined
  if sections_html == "" then
    sections_html = '<div class="dataimago-micp-section">' ..
                   '<p><em>No specific ethical rules defined. Consider adding MiCP configuration to guide AI-native development.</em></p>' ..
                   '<p>Learn more about the Mission Context Protocol at <a href="https://dataimago.ai/micp" target="_blank">dataimago.ai/micp</a></p>' ..
                   '</div>'
  end
  
  local container_end = '</div>'
  
  -- Return as HTML block
  return pandoc.RawBlock("html", 
    container_start .. 
    header_html .. 
    sections_html .. 
    container_end
  )
end

-- Register the shortcode
return {
  ["micp-display"] = Micp_display
}