-- SVG Inline Filter for dataimago Design System
-- Inline only SVGs with class "inline-svg".
-- If class "monochrome" is present, coerce fills to currentColor.
-- Also prefixes IDs to avoid collisions across repeated icons.

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
  
  -- If path starts with '/', try it as-is first
  local f = io.open(normalized_path, "rb")
  if f then
    local s = f:read("*a")
    f:close()
    return s
  end
  
  -- If that fails and path starts with '/', try removing the leading slash
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

local function process_svg_img(src, class_attr, aria_label)
  if not src:match("%.svg$") then return nil end
  if not class_attr or not class_attr:match("inline%-svg") then return nil end

  local svg = readfile(src)
  if not svg then return nil end

  -- strip XML declaration if present
  svg = svg:gsub("<%?xml.-%?>", "")

  -- add classes from the image to the root <svg>
  svg = svg:gsub("<svg", '<svg class="' .. class_attr .. '"', 1)

  -- optional: ensure a11y
  if aria_label and aria_label ~= "" then
    svg = svg:gsub("<svg", '<svg role="img" aria-label="' .. aria_label .. '"', 1)
  else
    svg = svg:gsub("<svg", '<svg aria-hidden="true"', 1)
  end

  -- avoid ID collisions: prefix ids and url(#id) refs
  local prefix = unique_prefix()
  svg = svg:gsub('id="([%w_%-%.:]+)"', 'id="' .. prefix .. '%1"')
  svg = svg:gsub('url%(%#([%w_%-%.:]+)%)', 'url(#' .. prefix .. '%1)')
  svg = svg:gsub('href="#([%w_%-%.:]+)"', 'href="#' .. prefix .. '%1"')
  svg = svg:gsub('xlink:href="#([%w_%-%.:]+)"', 'xlink:href="#' .. prefix .. '%1"')

  -- sanitize: strip <script> and inline event handlers (basic)
  svg = svg:gsub("<script.-</script>", "")
  svg = svg:gsub("%son%w+%s*=%s*\".-\"", "")

  -- monochrome: replace hard-coded fills with currentColor (best-effort)
  if class_attr:match("monochrome") then
    -- remove style-based fill
    svg = svg:gsub('style="([^"]-)"', function(s)
      s = s:gsub("fill:%s*[^;\"']+;?", "")
      s = s:gsub("^%s*;%s*", ""):gsub("%s*;%s*$", "")
      return (#s > 0) and ('style="'..s..'"') or ""
    end)
    -- replace presentation fill attributes
    svg = svg:gsub('fill="[^"]+"', 'fill="currentColor"')
    -- if root <svg> has its own fill, neutralize it
    svg = svg:gsub("<svg([^>]-)fill=\"[^\"]+\"", "<svg%1")
  end

  return svg
end

return {
  Image = function(el)
    if not el.src:match("%.svg$") then return nil end
    if not has_class(el, "inline-svg") then return nil end

    local classes = table.concat(el.classes, " ")
    local aria = el.attributes["aria-label"]
    local svg = process_svg_img(el.src, classes, aria)
    
    if svg then
      return pandoc.RawInline("html", svg)
    end
    return nil
  end,
  
  RawInline = function(el)
    if el.format ~= "html" then return nil end
    
    -- Match <img> tags with inline-svg class (more flexible pattern)
    local src, class_attr, aria_label = el.text:match('<img[^>]*src=["\']([^"\']*%.svg)["\'][^>]*class=["\']([^"\']*inline%-svg[^"\']*)["\'][^>]*aria%-label=["\']([^"\']*)["\'][^>]*/?>')
    if not src then
      src, class_attr = el.text:match('<img[^>]*src=["\']([^"\']*%.svg)["\'][^>]*class=["\']([^"\']*inline%-svg[^"\']*)["\'][^>]*/?>')
    end
    
    if src and class_attr then
      local svg = process_svg_img(src, class_attr, aria_label)
      if svg then
        return pandoc.RawInline("html", svg)
      end
    end
    
    return nil
  end,
  
  RawBlock = function(el)
    if el.format ~= "html" then return nil end
    
    -- Handle navbar logo (Quarto generates this with navbar-logo class)
    local modified = el.text:gsub('<img([^>]-)src=["\']([^"\']*ai_monogram%.svg)["\']([^>]-)class=["\']([^"\']*navbar%-logo[^"\']*)["\']([^>]*)/?>', function(pre, src, mid, class_attr, post)
      -- Add inline-svg and monochrome classes to navbar logo
      local new_classes = class_attr .. " inline-svg monochrome"
      local svg = process_svg_img(src, new_classes, nil)
      if svg then
        return svg
      else
        return '<img' .. pre .. 'src="' .. src .. '"' .. mid .. 'class="' .. new_classes .. '"' .. post .. '/>'
      end
    end)
    
    if modified ~= el.text then
      return pandoc.RawBlock("html", modified)
    end
    
    return nil
  end
}
