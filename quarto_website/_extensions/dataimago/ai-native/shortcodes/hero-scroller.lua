--[[
Dataimago AI-Native Extension - Hero Scroller Shortcode
Creates smooth-scrolling hero content areas (carousel replacement)

Usage:
{{< hero-scroller >}}
{{< content-item title="Item 1" >}}Content...{{< /content-item >}}
{{< content-item title="Item 2" >}}More content...{{< /content-item >}}
{{< /hero-scroller >}}

Parameters:
- height: Custom height (default: 60vh)
- class: Additional CSS classes
- id: Custom container ID
- indicator: Show scroll progress indicator (default: true)
--]]

function Hero_scroller(args, kwargs, content)
  -- Get parameters
  local custom_height = pandoc.utils.stringify(kwargs.height or "60vh")
  local extra_class = pandoc.utils.stringify(kwargs.class or "")
  local container_id = pandoc.utils.stringify(kwargs.id or "")
  local show_indicator = pandoc.utils.stringify(kwargs.indicator or "true") == "true"
  
  -- Generate unique ID if not provided
  if container_id == "" then
    container_id = "dataimago-hero-scroller-" .. tostring(math.random(1000, 9999))
  end
  
  -- Build CSS classes
  local css_classes = {"dataimago-hero-scroller", "hero-content-scroller"}
  if extra_class ~= "" then
    table.insert(css_classes, extra_class)
  end
  
  -- Build container attributes
  local container_attributes = {
    id = container_id,
    class = table.concat(css_classes, " "),
    ["data-lenis-scroller"] = "true",
    ["aria-label"] = "Scrollable content area",
    ["role"] = "region"
  }
  
  -- Add custom height as inline style if specified
  local inline_style = ""
  if custom_height ~= "60vh" then
    inline_style = ' style="height: ' .. custom_height .. ';"'
  end
  
  -- Create container HTML
  local container_start = "<div"
  for key, value in pairs(container_attributes) do
    container_start = container_start .. ' ' .. key .. '="' .. value .. '"'
  end
  container_start = container_start .. inline_style .. ">"
  
  -- Create content wrapper
  local content_wrapper_start = '<div class="dataimago-scroller-content scroller-content">'
  local content_wrapper_end = '</div>'
  
  -- Add scroll indicator if enabled
  local indicator_html = ""
  if show_indicator then
    indicator_html = '<div class="dataimago-scroll-indicator hero-scroll-indicator">' ..
                    '<div class="dataimago-scroll-progress scroll-progress"></div>' ..
                    '</div>'
  end
  
  local container_end = indicator_html .. "</div>"
  
  -- Process content
  local processed_content = pandoc.read(content, "markdown").blocks
  
  -- Return as structured HTML
  return {
    pandoc.RawBlock("html", container_start),
    pandoc.RawBlock("html", content_wrapper_start),
    processed_content,
    pandoc.RawBlock("html", content_wrapper_end),
    pandoc.RawBlock("html", container_end)
  }
end

-- Register the shortcode
return {
  ["hero-scroller"] = Hero_scroller
}