-- SVG Inline Filter for dataimago Design System
-- Inline SVGs with class "inline-svg" for CSS control
-- Preserves all original attributes and styling

local counter = 0
local function unique_prefix()
  counter = counter + 1
  return "svg" .. counter .. "-"
end

local function has_class(el, name)
  -- Handle both Pandoc classes (table) and HTML class attribute (string)
  if el.classes then
    for _, c in ipairs(el.classes) do if c == name then return true end end
  end
  if el.attributes and el.attributes.class then
    return el.attributes.class:match("%f[%w]" .. name .. "%f[%W]")
  end
  return false
end

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

local function process_svg_img(src, class_attr, aria_label, style_attr, title_attr, alt_attr)
  if not src:match("%.svg$") then return nil end
  if not class_attr or not class_attr:match("inline%-svg") then return nil end

  local svg = readfile(src)
  if not svg then return nil end

  -- Strip XML declaration if present
  svg = svg:gsub("<%?xml.-%?>", "")

  -- Build attributes to add to the SVG
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
  
  if aria_label then
    table.insert(svg_attrs, 'aria-label="' .. aria_label .. '"')
  elseif alt_attr then
    table.insert(svg_attrs, 'aria-label="' .. alt_attr .. '"')
  end
  
  -- Add attributes to the SVG
  local attrs_string = table.concat(svg_attrs, " ")
  if #attrs_string > 0 then
    svg = svg:gsub("<svg", "<svg " .. attrs_string, 1)
  end

  -- Avoid ID collisions: prefix ids and url(#id) refs
  local prefix = unique_prefix()
  svg = svg:gsub('id="([%w_%-%.:]+)"', 'id="' .. prefix .. '%1"')
  svg = svg:gsub('url%(%#([%w_%-%.:]+)%)', 'url(#' .. prefix .. '%1)')
  svg = svg:gsub('href="#([%w_%-%.:]+)"', 'href="#' .. prefix .. '%1"')
  svg = svg:gsub('xlink:href="#([%w_%-%.:]+)"', 'xlink:href="#' .. prefix .. '%1"')

  -- Sanitize: strip <script> and inline event handlers
  svg = svg:gsub("<script.-</script>", "")
  svg = svg:gsub("%son%w+%s*=%s*\".-\"", "")

  -- Convert to currentColor if monochrome class is present
  if class_attr:match("monochrome") then
    svg = svg:gsub('fill="[^"]+"', 'fill="currentColor"')
    -- Remove style-based fill
    svg = svg:gsub('style="([^"]-)"', function(s)
      s = s:gsub("fill:%s*[^;\"']+;?", "")
      s = s:gsub("^%s*;%s*", ""):gsub("%s*;%s*$", "")
      return (#s > 0) and ('style="'..s..'"') or ""
    end)
  end

  return svg
end

return {
  Image = function(el)
    if not el.src:match("%.svg$") then return nil end
    if not has_class(el, "inline-svg") then return nil end

    local classes = table.concat(el.classes, " ")
    local aria = el.attributes["aria-label"]
    local svg = process_svg_img(el.src, classes, aria, nil, nil, el.attributes.alt)
    
    if svg then
      return pandoc.RawInline("html", svg)
    end
    return nil
  end,
  
  RawInline = function(el)
    if el.format ~= "html" then return nil end
    
    -- Check if this is an SVG img tag with inline-svg class
    if not el.text:match("%.svg") or not el.text:match("inline%-svg") then
      return nil
    end
    
    -- Extract attributes using individual patterns (more flexible)
    local src = el.text:match('src=["\']([^"\']*%.svg)["\']')
    local class_attr = el.text:match('class=["\']([^"\']*)["\']')
    local style_attr = el.text:match('style=["\']([^"\']*)["\']')
    local title_attr = el.text:match('title=["\']([^"\']*)["\']')
    local alt_attr = el.text:match('alt=["\']([^"\']*)["\']')
    local aria_label = el.text:match('aria%-label=["\']([^"\']*)["\']')
    
    if src and class_attr and class_attr:match("inline%-svg") then
      local svg = process_svg_img(src, class_attr, aria_label, style_attr, title_attr, alt_attr)
      if svg then
        return pandoc.RawInline("html", svg)
      end
    end
    
    return nil
  end
}