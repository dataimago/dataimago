-- Minimal SVG Inline Filter for Testing (Quarto Logo Only)
-- This filter will inline only the Quarto logo for testing purposes

local function readfile(path)
  -- Handle relative paths by making them relative to the current working directory
  local normalized_path = pandoc.path.normalize(path)
  
  -- Try as-is first
  local f = io.open(normalized_path, "rb")
  if f then
    local s = f:read("*a")
    f:close()
    return s
  end
  
  -- If path starts with '/', try removing the leading slash
  if path:match("^/") then
    local relative_path = path:sub(2) -- Remove leading slash
    f = io.open(relative_path, "rb")
    if f then
      local s = f:read("*a")
      f:close()
      return s
    end
  end
  
  return nil
end

local function process_quarto_logo(src, class_attr, style_attr, title_attr, alt_attr)
  -- Only process quarto_logo.svg
  if not src:match("quarto_logo%.svg") then return nil end
  
  local svg = readfile(src)
  if not svg then return nil end

  -- Strip XML declaration if present
  svg = svg:gsub("<%?xml.-%?>", "")

  -- Add the original classes and style to the root <svg>
  local svg_attrs = {}
  
  if class_attr then
    table.insert(svg_attrs, 'class="' .. class_attr .. '"')
  end
  
  if style_attr then
    table.insert(svg_attrs, 'style="' .. style_attr .. '"')
  end
  
  if title_attr then
    table.insert(svg_attrs, 'title="' .. title_attr .. '"')
  end
  
  if alt_attr then
    table.insert(svg_attrs, 'aria-label="' .. alt_attr .. '"')
  end
  
  -- Add attributes to the SVG
  local attrs_string = table.concat(svg_attrs, " ")
  if #attrs_string > 0 then
    svg = svg:gsub("<svg", "<svg " .. attrs_string, 1)
  end

  -- Keep the original SVG attributes and fill color
  -- CSS will override fill on hover once SVG is inline

  return svg
end

return {
  RawInline = function(el)
    if el.format ~= "html" then return nil end
    
    -- Match <img> tags for quarto_logo.svg specifically
    local src, class_attr, title_attr, alt_attr, style_attr = el.text:match(
      '<img[^>]*src=["\']([^"\']*quarto_logo%.svg)["\'][^>]*class=["\']([^"\']*)["\'][^>]*title=["\']([^"\']*)["\'][^>]*alt=["\']([^"\']*)["\'][^>]*style=["\']([^"\']*)["\'][^>]*/?>'
    )
    
    if src then
      io.stderr:write("DEBUG: Found Quarto logo to inline: " .. src .. "\n")
      io.stderr:write("DEBUG: Style: " .. (style_attr or "none") .. "\n")
      
      local svg = process_quarto_logo(src, class_attr, style_attr, title_attr, alt_attr)
      if svg then
        io.stderr:write("DEBUG: Successfully inlined Quarto logo\n")
        return pandoc.RawInline("html", svg)
      else
        io.stderr:write("DEBUG: Failed to process Quarto logo\n")
      end
    end
    
    return nil
  end
}
