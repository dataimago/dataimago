--[[
Dataimago AI-Native Extension - Feature Box Shortcode
Creates styled feature showcase boxes

Usage:
{{< feature-box title="Feature Title" icon="🚀" >}}
- Feature description
- Multiple bullet points
- Highlight key capabilities
{{< /feature-box >}}

Parameters:
- title: The title of the feature box (required)
- icon: Optional icon/emoji to display with title
- animate: Animation type (default: "fade-up")
- class: Additional CSS classes
- color: Optional accent color for the box
--]]

function Feature_box(args, kwargs, content)
  -- Get parameters
  local title = pandoc.utils.stringify(args[1] or kwargs.title or "")
  local icon = pandoc.utils.stringify(kwargs.icon or "")
  local animate = pandoc.utils.stringify(kwargs.animate or "fade-up")
  local extra_class = pandoc.utils.stringify(kwargs.class or "")
  local accent_color = pandoc.utils.stringify(kwargs.color or "")
  
  -- Build CSS classes
  local css_classes = {"dataimago-feature-box", "card"}
  if extra_class ~= "" then
    table.insert(css_classes, extra_class)
  end
  
  -- Build attributes
  local attributes = {
    class = table.concat(css_classes, " "),
    ["data-dataimago-animate"] = animate,
    ["role"] = "article"
  }
  
  -- Add tabindex for keyboard navigation
  attributes["tabindex"] = "0"
  
  -- Add aria-label if title is provided
  if title ~= "" then
    attributes["aria-label"] = "Feature: " .. title
  end
  
  -- Add custom color as CSS variable if provided
  local inline_style = ""
  if accent_color ~= "" then
    inline_style = ' style="--feature-accent-color: ' .. accent_color .. ';"'
  end
  
  -- Create div element
  local div_start = "<div"
  for key, value in pairs(attributes) do
    div_start = div_start .. ' ' .. key .. '="' .. value .. '"'
  end
  div_start = div_start .. inline_style .. ">"
  
  -- Build header HTML with title and optional icon
  local header_html = ""
  if title ~= "" then
    local icon_html = ""
    if icon ~= "" then
      icon_html = '<span class="feature-icon" aria-hidden="true">' .. icon .. '</span>'
    end
    
    header_html = '<div class="feature-header">' ..
                  icon_html ..
                  '<h3 class="feature-title">' .. title .. '</h3>' ..
                  '</div>'
  end
  
  local div_end = "</div>"
  
  -- Process content
  local processed_content
  if content and content ~= "" then
    local content_blocks = pandoc.read(content, "markdown").blocks
    processed_content = content_blocks
  else
    processed_content = {}
  end
  
  -- Return structured HTML
  local result = {pandoc.RawBlock("html", div_start)}
  
  -- Add header if provided
  if header_html ~= "" then
    table.insert(result, pandoc.RawBlock("html", header_html))
  end
  
  -- Add content wrapper
  if #processed_content > 0 then
    table.insert(result, pandoc.RawBlock("html", '<div class="feature-content">'))
    for _, block in ipairs(processed_content) do
      table.insert(result, block)
    end
    table.insert(result, pandoc.RawBlock("html", '</div>'))
  end
  
  table.insert(result, pandoc.RawBlock("html", div_end))
  
  return result
end

-- Register the shortcode
return {
  ["feature-box"] = Feature_box
}