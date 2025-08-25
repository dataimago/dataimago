--[[
Dataimago AI-Native Extension - Content Item Shortcode
Creates individual content items for hero scrollers

Usage:
{{< content-item title="Item Title" >}}
Content goes here...
{{< /content-item >}}

Parameters:
- title: The title of the content item (required)
- icon: Optional icon/emoji to display
- animate: Animation type for the item
- class: Additional CSS classes
--]]

function Content_item(args, kwargs, content)
  -- Get parameters
  local title = pandoc.utils.stringify(args[1] or kwargs.title or "")
  local icon = pandoc.utils.stringify(kwargs.icon or "")
  local animate = pandoc.utils.stringify(kwargs.animate or "fade-up")
  local extra_class = pandoc.utils.stringify(kwargs.class or "")
  
  -- Build CSS classes
  local css_classes = {"dataimago-content-item", "content-item"}
  if extra_class ~= "" then
    table.insert(css_classes, extra_class)
  end
  
  -- Build attributes
  local attributes = {
    class = table.concat(css_classes, " "),
    ["data-dataimago-animate"] = animate,
    ["role"] = "article",
    tabindex = "0"
  }
  
  -- Add aria-label if title is provided
  if title ~= "" then
    attributes["aria-label"] = "Content item: " .. title
  end
  
  -- Create article element
  local article_start = "<article"
  for key, value in pairs(attributes) do
    article_start = article_start .. ' ' .. key .. '="' .. value .. '"'
  end
  article_start = article_start .. ">"
  
  -- Build title HTML with optional icon
  local title_html = ""
  if title ~= "" then
    local icon_html = ""
    if icon ~= "" then
      icon_html = '<span class="content-icon" aria-hidden="true">' .. icon .. '</span> '
    end
    title_html = '<h3 class="content-title">' .. icon_html .. title .. '</h3>'
  end
  
  local article_end = "</article>"
  
  -- Process content
  local processed_content
  if content and content ~= "" then
    -- Wrap content in paragraph if it's just text
    local content_blocks = pandoc.read(content, "markdown").blocks
    processed_content = content_blocks
  else
    processed_content = {}
  end
  
  -- Return structured HTML
  local result = {pandoc.RawBlock("html", article_start)}
  
  -- Add title if provided
  if title_html ~= "" then
    table.insert(result, pandoc.RawBlock("html", title_html))
  end
  
  -- Add content wrapper
  if #processed_content > 0 then
    table.insert(result, pandoc.RawBlock("html", '<div class="content-text">'))
    for _, block in ipairs(processed_content) do
      table.insert(result, block)
    end
    table.insert(result, pandoc.RawBlock("html", '</div>'))
  end
  
  table.insert(result, pandoc.RawBlock("html", article_end))
  
  return result
end

-- Register the shortcode
return {
  ["content-item"] = Content_item
}