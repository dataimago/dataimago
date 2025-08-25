--[[
Dataimago AI-Native Extension - Slide Container Shortcode
Creates slide-based content sections with proper semantic markup and styling

Usage:
{{< slide-container type="hero" >}}
Content goes here...
{{< /slide-container >}}

Parameters:
- type: "hero", "features", "technical", or custom type
- id: Optional custom ID for the slide
- class: Additional CSS classes
- title: Optional slide title for screen readers
--]]

function Slide_container(args, kwargs, content)
  -- Get parameters
  local slide_type = pandoc.utils.stringify(args[1] or kwargs.type or "default")
  local slide_id = pandoc.utils.stringify(kwargs.id or "")
  local extra_class = pandoc.utils.stringify(kwargs.class or "")
  local slide_title = pandoc.utils.stringify(kwargs.title or "")
  
  -- Generate unique ID if not provided
  if slide_id == "" then
    slide_id = "dataimago-slide-" .. slide_type .. "-" .. tostring(math.random(1000, 9999))
  end
  
  -- Build CSS classes
  local css_classes = {"dataimago-slide", "lenis-slide", "dataimago-slide-" .. slide_type}
  if extra_class ~= "" then
    table.insert(css_classes, extra_class)
  end
  
  -- Build attributes
  local attributes = {
    id = slide_id,
    class = table.concat(css_classes, " "),
    ["data-slide-type"] = slide_type,
    ["role"] = "region",
    ["aria-label"] = slide_title ~= "" and slide_title or ("Slide: " .. slide_type)
  }
  
  -- Add slide title as data attribute for screen readers
  if slide_title ~= "" then
    attributes["data-slide-title"] = slide_title
  end
  
  -- Create the section element
  local section_start = "<section"
  for key, value in pairs(attributes) do
    section_start = section_start .. ' ' .. key .. '="' .. value .. '"'
  end
  section_start = section_start .. ">"
  
  local section_end = "</section>"
  
  -- Process content
  local processed_content = pandoc.read(content, "markdown").blocks
  
  -- Return as raw HTML block to preserve structure
  return {
    pandoc.RawBlock("html", section_start),
    processed_content,
    pandoc.RawBlock("html", section_end)
  }
end

-- Register the shortcode
return {
  ["slide-container"] = Slide_container
}