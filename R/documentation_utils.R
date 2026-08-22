#' @importFrom fs dir_exists dir_create file_copy path
#' @importFrom glue glue
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom rlang .data
# Internal UI functions to replace usethis dependency
#' @importFrom crayon blue green yellow
ui_info <- function(x) cat(crayon::blue(paste0("\u2139", " ", x, "\n")))
ui_done <- function(x) cat(crayon::green(paste0("\u2713", " ", x, "\n")))
ui_warn <- function(x) cat(crayon::yellow(paste0("Warning:", " ", x, "\n")))
#' @importFrom whisker whisker.render
#' @importFrom yaml read_yaml write_yaml
#' @importFrom crayon green silver yellow
#' @importFrom tools file_path_sans_ext
#' @importFrom Rd2md as_markdown read_rdfile
NULL

#' Generate Professional Application Documentation
#'
#' Converts R package documentation (.Rd files) and metadata (DESCRIPTION)
#' into Quarto-compatible .qmd files for professional website generation.
#' Applies dataimago framework branding and integrates development patterns.
#'
#' @param package_path Character. Path to the R package root directory.
#'   Must contain DESCRIPTION file and man/ directory with .Rd files.
#'   Default: "." (current directory)
#' @param output_path Character. Path to quarto website directory where
#'   .qmd files will be generated. Directory will be created if it
#'   doesn't exist. Default: "ui/www"
#' @param include_description Logical. Whether to include full DESCRIPTION file
#'   content in the generated API reference. Useful for package metadata display.
#'   Default: TRUE
#' @param include_foundation_links Logical. Whether to add automatic links to
#'   dataimago philosophical foundation documents in the generated documentation.
#'   Default: TRUE
#' @param template Character. Documentation template to use for styling and
#'   structure.  Currently supports "dataimago" template with ethical
#'   AI branding.  Default: "dataimago"
#' @param overwrite_config Logical. Whether to overwrite an existing
#'   `_quarto.yml` in `output_path` with the generated scaffold. The scaffold is
#'   deliberately minimal, so overwriting a maintained site config discards its
#'   navbar, sidebar, themes, extensions, render filters, and font `<link>` tags.
#'   When FALSE (the default) an existing config is left untouched and only the
#'   .qmd files are regenerated; a missing config is always scaffolded.
#'   Default: FALSE
#'
#' @return Character (invisible). File path to the generated api_reference.qmd file.
#'   Side effects: Creates .qmd files in output_path directory, scaffolds
#'   _quarto.yml if absent (or if `overwrite_config = TRUE`), and copies
#'   dataimago assets (logos, etc.) to assets/img/ subdirectory.
#'
#' @details
#' This function implements dataimago's framework approach to documentation generation:
#' \itemize{
#'   \item **Automated Processing**: Parses package DESCRIPTION and converts .Rd files to Quarto markdown
#'   \item **Framework Integration**: Uses Rd2md for technical conversion with dataimago branding
#'   \item **Professional Styling**: Applies consistent visual identity and development patterns
#'   \item **Multi-Platform Output**: Generates documentation suitable for web deployment
#'   \item **AI-Compatibility**: Creates machine-readable annotations for MCP integration
#'   \item **Rapid Generation**: One-command documentation creation for development workflows
#' }
#'
#' The generated documentation structure includes:
#' \itemize{
#'   \item `_quarto.yml` configuration file for website project setup
#'   \item `api_reference.qmd` with YAML frontmatter and package metadata
#'   \item Full DESCRIPTION file content (if requested)
#'   \item Links to dataimago foundation documents
#'   \item Function documentation with ethical context boxes
#'   \item dataimago branding footer on each function
#' }
#'
#' For AI agents and MCP tools, this function provides structured documentation
#' generation that embeds philosophical context into technical reference
#' material,
#' enabling AI systems to understand both the "what" and "why" of each function.
#'
#' @section MCP Tool Integration:
#' This function is designed for Model Context Protocol (MCP) integration:
#' \itemize{
#'   \item **Input Validation**: Checks for required package structure
#'   \item **Structured Output**: Generates consistent .qmd file format
#'   \item **Error Handling**: Provides clear error messages for debugging
#'   \item **Asset Management**: Handles file copying and directory creation
#'   \item **Status Reporting**: Uses colored console output for progress
#'     tracking
#' }
#'
#' @section Philosophical Context:
#' This function embodies dataimago's principle of embedding AI within culture
#' for emancipatory purposes. Rather than treating documentation as mere
#' technical
#' reference, it creates living documents that connect computational tools to
#' their ethical foundations and societal purposes.
#'
#' @examples
#' \dontrun{
#' # Basic usage - generate documentation for current package
#' create_quarto_documentation()
#'
#' # Generate for specific package with custom output location
#' create_quarto_documentation(
#'   package_path = "/path/to/my/package",
#'   output_path = "docs/website"
#' )
#'
#' # Generate minimal documentation without foundation links
#' create_quarto_documentation(
#'   include_foundation_links = FALSE,
#'   include_description = FALSE
#' )
#'
#' # For MCP/AI usage - capture output path
#' doc_path <- create_quarto_documentation()
#' cat("Generated documentation at:", doc_path)
#' }
#'
#' @seealso
#' \code{\link{parse_description_file}} for DESCRIPTION parsing,
#' \code{\link{convert_rd_files_to_qmd}} for .Rd conversion,
#' \code{\link{update_dataimago_assets}} for asset management
#'
#' @keywords documentation generation quarto ethical-ai
#' @concept dataimago ethical-documentation MCP-compatible
#' @export
create_quarto_documentation <- function(package_path = ".",
                                        output_path = "ui/www",
                                        include_description = TRUE,
                                        include_foundation_links = TRUE,
                                        template = "dataimago",
                                        overwrite_config = FALSE) {
  # Validate inputs
  if (!dir.exists(package_path)) {
    stop("Package path does not exist: ", package_path)
  }

  desc_file <- file.path(package_path, "DESCRIPTION")
  if (!file.exists(desc_file)) {
    stop("DESCRIPTION file not found in package_path: ", package_path)
  }

  man_dir <- file.path(package_path, "man")
  if (!dir.exists(man_dir)) {
    warning("man/ directory not found. No .Rd files to process.")
    rd_files <- character(0)
  } else {
    rd_files <- list.files(man_dir, pattern = "\\.Rd$", full.names = TRUE)
  }

  # Create output directory if it doesn't exist
  if (!dir.exists(output_path)) {
    dir.create(output_path, recursive = TRUE)
  }

  # Parse DESCRIPTION file
  desc_content <- parse_description_file(desc_file)

  # Convert .Rd files to qmd format using Rd2md
  rd_content <- convert_rd_files_to_qmd(rd_files)

  # Generate api_reference.qmd
  api_reference_content <- generate_api_reference_qmd(
    desc_content = desc_content,
    rd_content = rd_content,
    include_description = include_description,
    include_foundation_links = include_foundation_links
  )

  # Write api_reference.qmd
  api_file <- file.path(output_path, "api_reference.qmd")
  writeLines(api_reference_content, api_file)

  # Generate and write _quarto.yml
  #
  # `generate_quarto_yml()` emits a minimal scaffold (theme: cosmo, a two-item
  # navbar, no font loading, no dataimago assets). That is the right output for
  # a brand-new site and catastrophically wrong for an established one: writing
  # it over a maintained config silently discards the navbar, sidebar, themes,
  # extensions, render filters, and font <link> tags. Scaffold only when there
  # is nothing to lose; require an explicit opt-in to clobber.
  quarto_yml_file <- file.path(output_path, "_quarto.yml")
  config_exists <- file.exists(quarto_yml_file)

  if (!config_exists || isTRUE(overwrite_config)) {
    quarto_yml_content <- generate_quarto_yml(desc_content, template)
    writeLines(quarto_yml_content, quarto_yml_file)
  } else {
    cat(crayon::silver(
      "\u2139 Preserved existing _quarto.yml (pass overwrite_config = TRUE to regenerate)\n"
    ))
  }

  # Update dataimago assets if template is dataimago
  if (template == "dataimago") {
    update_dataimago_assets(output_path, package_path)
  }

  cat(crayon::green("\u2713 Quarto documentation generated successfully\n"))
  cat(crayon::silver("  API reference: "), api_file, "\n")
  cat(
    crayon::silver("  Quarto config: "), quarto_yml_file,
    if (config_exists && !isTRUE(overwrite_config)) " (preserved)" else " (written)", "\n"
  )

  invisible(api_file)
}

#' Parse DESCRIPTION File
#'
#' @param desc_file Path to DESCRIPTION file
#' @return List containing parsed DESCRIPTION fields
#' @keywords internal
parse_description_file <- function(desc_file) {
  desc_lines <- readLines(desc_file)

  # Parse key fields
  desc_content <- list()

  # Extract basic fields
  desc_content$package <- extract_desc_field(desc_lines, "Package")
  desc_content$version <- extract_desc_field(desc_lines, "Version")
  desc_content$title <- extract_desc_field(desc_lines, "Title")
  desc_content$description <- extract_desc_field(desc_lines, "Description")
  desc_content$authors <- extract_desc_field(desc_lines, "Authors@R")
  desc_content$maintainer <- extract_desc_field(desc_lines, "Maintainer")
  desc_content$license <- extract_desc_field(desc_lines, "License")
  desc_content$url <- extract_desc_field(desc_lines, "URL")
  desc_content$bug_reports <- extract_desc_field(desc_lines, "BugReports")
  desc_content$depends <- extract_desc_field(desc_lines, "Depends")
  desc_content$imports <- extract_desc_field(desc_lines, "Imports")
  desc_content$suggests <- extract_desc_field(desc_lines, "Suggests")

  # Format for display
  desc_content$full_text <- paste(desc_lines, collapse = "\n")

  desc_content
}

#' Extract Field from DESCRIPTION Lines
#'
#' @param desc_lines Character vector of DESCRIPTION file lines
#' @param field_name Name of field to extract
#' @return Character string with field value or NULL if not found
#' @keywords internal
extract_desc_field <- function(desc_lines, field_name) {
  field_pattern <- paste0("^", field_name, ":\\s*")
  field_line_idx <- grep(field_pattern, desc_lines)

  if (length(field_line_idx) == 0) {
    return(NULL)
  }

  # Get the field value and any continuation lines
  field_value <- sub(field_pattern, "", desc_lines[field_line_idx])

  # Check for continuation lines (starting with whitespace)
  if (field_line_idx < length(desc_lines)) {
    continuation_lines <- c()
    for (i in (field_line_idx + 1):length(desc_lines)) {
      if (grepl("^\\s+", desc_lines[i]) && !grepl("^[A-Za-z]+:", desc_lines[i])) {
        continuation_lines <- c(continuation_lines, trimws(desc_lines[i]))
      } else {
        break
      }
    }

    if (length(continuation_lines) > 0) {
      field_value <- paste(c(field_value, continuation_lines), collapse = " ")
    }
  }

  trimws(field_value)
}

#' Convert .Rd Files to QMD Format using Rd2md
#'
#' @param rd_files Character vector of paths to .Rd files
#' @return List containing converted documentation for each function
#' @keywords internal
convert_rd_files_to_qmd <- function(rd_files) {
  if (length(rd_files) == 0) {
    return(list())
  }

  rd_content <- list()

  for (rd_file in rd_files) {
    # Extract function name from filename
    func_name <- tools::file_path_sans_ext(basename(rd_file))

    # Use Rd2md to convert .Rd to markdown with warning suppression
    # for known issues
    md_content <- suppressWarnings({
      Rd2md::as_markdown(Rd2md::read_rdfile(rd_file))
    })

    # Post-process markdown to qmd format with dataimago customizations
    qmd_content <- post_process_md_to_qmd(md_content, func_name)

    rd_content[[func_name]] <- qmd_content
  }

  rd_content
}


#' Post-Process Markdown to QMD Format with dataimago Customizations
#'
#' @param md_content Character vector of markdown content from Rd2md
#' @param func_name Function name for customization
#' @return Character vector with qmd-formatted content
#' @keywords internal
post_process_md_to_qmd <- function(md_content, func_name) {
  # Split content into lines if it's a single string
  if (length(md_content) == 1) {
    md_lines <- unlist(strsplit(md_content, "\n"))
  } else {
    md_lines <- md_content
  }

  qmd_lines <- c()

  for (i in seq_along(md_lines)) {
    line <- md_lines[i]

    # Customize specific sections for dataimago
    if (grepl("^# ", line)) {
      # Convert main title to include backticks around function name
      title_text <- sub("^# ", "", line)
      if (grepl(func_name, title_text, ignore.case = TRUE)) {
        # Format as: # `function_name`: Description
        clean_title <- gsub(func_name, "", title_text, ignore.case = TRUE)
        clean_title <- trimws(clean_title)
        qmd_lines <- c(qmd_lines, paste0("# `", func_name, "`: ", clean_title))
      } else {
        qmd_lines <- c(qmd_lines, line)
      }
    } else if (grepl("^## Description", line)) {
      # Add ethical context after description
      qmd_lines <- c(qmd_lines, line)
      qmd_lines <- c(qmd_lines, "")
      qmd_lines <- c(qmd_lines, "::: {.ethical-note}")
      qmd_lines <- c(
        qmd_lines,
        paste0(
          "This function embodies dataimago's principle of embedding ",
          "AI within culture for emancipatory purposes."
        )
      )
      qmd_lines <- c(qmd_lines, ":::")
      qmd_lines <- c(qmd_lines, "")
    } else if (grepl("^## Examples", line)) {
      # Add dataimago context to examples section
      qmd_lines <- c(qmd_lines, line)
      qmd_lines <- c(qmd_lines, "")
      qmd_lines <- c(
        qmd_lines,
        "_Examples using dataimago's ethical AI framework:_"
      )
      qmd_lines <- c(qmd_lines, "")
    } else {
      # Keep line as-is
      qmd_lines <- c(qmd_lines, line)
    }
  }

  # Add dataimago footer to function documentation
  qmd_lines <- c(qmd_lines, "")
  qmd_lines <- c(qmd_lines, "---")
  qmd_lines <- c(qmd_lines, "")
  qmd_lines <- c(
    qmd_lines,
    "*This function is part of the dataimago ethical AI framework.*"
  )
  qmd_lines <- c(qmd_lines, "")

  qmd_lines
}

#' Generate API Reference QMD Content
#'
#' @param desc_content Parsed DESCRIPTION content
#' @param rd_content Converted .Rd content
#' @param include_description Include DESCRIPTION section
#' @param include_foundation_links Include dataimago foundation links
#' @return Character vector with complete qmd content
#' @keywords internal
generate_api_reference_qmd <- function(desc_content, rd_content,
                                       include_description = TRUE,
                                       include_foundation_links = TRUE) {
  qmd_content <- c()

  # Add YAML frontmatter
  qmd_content <- c(qmd_content, "---")
  qmd_content <- c(
    qmd_content,
    paste0("title: \"", desc_content$package, " API Reference\"")
  )
  qmd_content <- c(qmd_content, "subtitle: \"dataimago Ethical AI Framework\"")
  qmd_content <- c(
    qmd_content,
    paste0("version: \"", desc_content$version, "\"")
  )
  qmd_content <- c(qmd_content, "format:")
  qmd_content <- c(qmd_content, "  html:")
  qmd_content <- c(qmd_content, "    toc: true")
  qmd_content <- c(qmd_content, "    toc-depth: 3")
  qmd_content <- c(qmd_content, "---")
  qmd_content <- c(qmd_content, "")

  # Add DESCRIPTION section if requested
  if (include_description && !is.null(desc_content$full_text)) {
    qmd_content <- c(qmd_content, "# Package Information")
    qmd_content <- c(qmd_content, "")
    qmd_content <- c(qmd_content, format_description_fields(desc_content))
    qmd_content <- c(qmd_content, "")
  }

  # Add foundation links if requested
  if (include_foundation_links) {
    qmd_content <- c(qmd_content, "## dataimago Foundation")
    qmd_content <- c(qmd_content, "")
    qmd_content <- c(
      qmd_content,
      "This package is built on dataimago's ethical AI framework:"
    )
    qmd_content <- c(qmd_content, "")
    qmd_content <- c(qmd_content, "- [Mission & Vision](../foundations/mission.html)")
    qmd_content <- c(qmd_content, "- [Philosophy](../foundations/philosophy.html)")
    qmd_content <- c(
      qmd_content,
      "- [Critical Theory Manifesto](../manifesto/critical_theory_manifesto.html)"
    )
    qmd_content <- c(qmd_content, "")
  }

  # Add function documentation sections
  qmd_content <- c(qmd_content, add_function_docs_sections(rd_content))

  qmd_content
}

#' Update dataimago Assets in Quarto Website
#'
#' @param output_path Path to quarto website directory
#' @param package_path Path to package root
#' @keywords internal
update_dataimago_assets <- function(output_path, package_path) {
  # Create assets directory structure
  assets_dir <- file.path(output_path, "assets")
  img_dir <- file.path(assets_dir, "img")
  css_dir <- file.path(assets_dir, "css")
  js_dir <- file.path(assets_dir, "js")

  if (!dir.exists(img_dir)) {
    dir.create(img_dir, recursive = TRUE)
  }
  if (!dir.exists(css_dir)) {
    dir.create(css_dir, recursive = TRUE)
  }
  if (!dir.exists(js_dir)) {
    dir.create(js_dir, recursive = TRUE)
  }

  # Copy dataimago logos from inst/
  inst_dir <- file.path(
    package_path, "inst", "dataimago",
    "04_dataimago_Content", "Design_Assets", "logos"
  )

  if (dir.exists(inst_dir)) {
    # Only copy essential PNG files (favicon and social media assets)
    essential_pngs <- c(
      "ai_monogram_supreme_favicon.png",
      "ai_monogram_supreme_COLOR.png"
    )

    png_files <- character(0)
    for (png_name in essential_pngs) {
      png_path <- file.path(inst_dir, png_name)
      if (file.exists(png_path)) {
        file.copy(png_path, img_dir, overwrite = TRUE)
        png_files <- c(png_files, png_name)
      }
    }

    if (length(png_files) > 0) {
      cat(
        crayon::silver("  Copied"), length(png_files),
        "essential PNG files to assets/img/\n"
      )
    }
  }

  # Ensure dataimago/ai-native Quarto extension is available
  extensions_dir <- file.path(
    output_path, "_extensions", "dataimago",
    "ai-native"
  )
  if (dir.exists(extensions_dir)) {
    cat(crayon::silver("  Found dataimago/ai-native Quarto extension\n"))

    # Copy extension assets to main assets directory for broader accessibility
    ext_css_dir <- file.path(extensions_dir, "assets", "css")
    ext_js_dir <- file.path(extensions_dir, "assets", "js")

    if (dir.exists(ext_css_dir)) {
      css_files <- list.files(ext_css_dir,
        pattern = "\\.(scss|css)$",
        full.names = TRUE
      )
      for (css_file in css_files) {
        file.copy(css_file, css_dir, overwrite = TRUE)
      }
      cat(
        crayon::silver("  Copied"), length(css_files),
        "extension CSS/SCSS files\n"
      )
    }

    if (dir.exists(ext_js_dir)) {
      js_files <- list.files(ext_js_dir, pattern = "\\.js$", full.names = TRUE)
      for (js_file in js_files) {
        file.copy(js_file, js_dir, overwrite = TRUE)
      }
      cat(crayon::silver("  Copied"), length(js_files), "extension JS files\n")
    }
  } else {
    cat(crayon::yellow("  Warning: dataimago/ai-native extension not found\n"))
  }

  invisible(TRUE)
}

#' Format DESCRIPTION Fields for Quarto Display
#'
#' @param desc_content Parsed DESCRIPTION content list
#' @return Character vector with formatted DESCRIPTION fields
#' @keywords internal
format_description_fields <- function(desc_content) {
  formatted_lines <- c()

  # Define field display order and labels
  field_order <- list(
    list(field = "package", label = "Package"),
    list(field = "version", label = "Version"),
    list(field = "title", label = "Title"),
    list(field = "description", label = "Description"),
    list(field = "authors", label = "Authors"),
    list(field = "maintainer", label = "Maintainer"),
    list(field = "license", label = "License"),
    list(field = "url", label = "URL"),
    list(field = "bug_reports", label = "Bug Reports"),
    list(field = "depends", label = "Depends"),
    list(field = "imports", label = "Imports"),
    list(field = "suggests", label = "Suggests")
  )

  # Format each field that exists
  for (field_info in field_order) {
    field_value <- desc_content[[field_info$field]]

    if (!is.null(field_value) && field_value != "") {
      # Format as bold label followed by content
      formatted_lines <- c(
        formatted_lines,
        paste0("**", field_info$label, "**: ", field_value)
      )
      formatted_lines <- c(formatted_lines, "")
    }
  }

  formatted_lines
}

#' Add Function Documentation Sections with Exported/Non-exported Structure
#'
#' @param rd_content List of converted .Rd content
#' @return Character vector with structured function documentation
#' @keywords internal
add_function_docs_sections <- function(rd_content) {
  if (length(rd_content) == 0) {
    return(character(0))
  }

  section_lines <- c()

  # Separate exported and non-exported functions
  # For now, we'll use a simple heuristic: functions with @keywords internal
  # are non-exported
  exported_functions <- c()
  internal_functions <- c()

  for (func_name in names(rd_content)) {
    # Check if function content contains "keyword.*internal" pattern
    func_content <- paste(rd_content[[func_name]], collapse = "\n")

    if (grepl("keyword.*internal", func_content, ignore.case = TRUE)) {
      internal_functions <- c(internal_functions, func_name)
    } else {
      exported_functions <- c(exported_functions, func_name)
    }
  }

  # Add exported functions section
  if (length(exported_functions) > 0) {
    section_lines <- c(section_lines, "# Exported Functions")
    section_lines <- c(section_lines, "")
    section_lines <- c(
      section_lines,
      "The following functions are exported and available for use:"
    )
    section_lines <- c(section_lines, "")

    for (func_name in exported_functions) {
      section_lines <- c(section_lines, rd_content[[func_name]])
    }
  }

  # Add internal functions section
  if (length(internal_functions) > 0) {
    section_lines <- c(section_lines, "# Internal Functions")
    section_lines <- c(section_lines, "")
    section_lines <- c(
      section_lines,
      "The following functions are internal to the package:"
    )
    section_lines <- c(section_lines, "")

    for (func_name in internal_functions) {
      section_lines <- c(section_lines, rd_content[[func_name]])
    }
  }

  section_lines
}

#' Generate _quarto.yml Configuration File
#'
#' @param desc_content Parsed DESCRIPTION content
#' @param template Template type (currently supports "dataimago")
#' @return Character vector with _quarto.yml content
#' @keywords internal
generate_quarto_yml <- function(desc_content, template = "dataimago") {
  yml_content <- c()

  # Basic project configuration
  yml_content <- c(yml_content, "project:")
  yml_content <- c(yml_content, "  type: website")
  yml_content <- c(
    yml_content,
    paste0("  title: \"", desc_content$package, ": ", desc_content$title, "\"")
  )
  yml_content <- c(yml_content, "")

  # Execution settings
  yml_content <- c(yml_content, "execute:")
  yml_content <- c(yml_content, "  freeze: auto")
  yml_content <- c(yml_content, "")

  # Website configuration
  yml_content <- c(yml_content, "website:")
  if (!is.null(desc_content$url)) {
    yml_content <- c(
      yml_content,
      paste0("  site-url: \"", desc_content$url, "\"")
    )
  }
  yml_content <- c(
    yml_content,
    paste0("  title: \"", desc_content$package, ": ", desc_content$title, "\"")
  )
  if (!is.null(desc_content$description)) {
    yml_content <- c(
      yml_content,
      paste0("  description: \"", desc_content$description, "\"")
    )
  }
  yml_content <- c(yml_content, "  page-navigation: true")
  yml_content <- c(yml_content, "")

  # Navbar configuration
  yml_content <- c(yml_content, "  navbar:")
  yml_content <- c(
    yml_content,
    paste0("    title: \"", desc_content$package, "\"")
  )
  yml_content <- c(yml_content, "    left:")
  yml_content <- c(yml_content, "      - href: index.qmd")
  yml_content <- c(yml_content, "        text: Home")
  yml_content <- c(yml_content, "      - href: api_reference.qmd")
  yml_content <- c(yml_content, "        text: API Reference")
  yml_content <- c(yml_content, "")

  # Sidebar configuration
  yml_content <- c(yml_content, "  sidebar:")
  yml_content <- c(yml_content, "    style: \"docked\"")
  yml_content <- c(yml_content, "    search: true")
  yml_content <- c(yml_content, "    contents:")
  yml_content <- c(yml_content, "      - section: \"Getting Started\"")
  yml_content <- c(yml_content, "        contents:")
  yml_content <- c(yml_content, "          - index.qmd")
  yml_content <- c(yml_content, "          - api_reference.qmd")
  yml_content <- c(yml_content, "")

  # Format configuration
  yml_content <- c(yml_content, "format:")
  yml_content <- c(yml_content, "  html:")
  yml_content <- c(yml_content, "    theme: cosmo")
  yml_content <- c(yml_content, "    toc: true")
  yml_content <- c(yml_content, "    toc-depth: 3")
  yml_content <- c(yml_content, "    code-copy: true")
  yml_content <- c(yml_content, "    code-overflow: wrap")

  # Add dataimago-specific configuration if using dataimago template
  if (template == "dataimago") {
    yml_content <- c(yml_content, "")
    yml_content <- c(yml_content, "# dataimago extensions")
    yml_content <- c(yml_content, "extensions:")
    yml_content <- c(yml_content, "  - dataimago/ai-native")
  }

  yml_content
}
