#' Generate Quarto Documentation from R Package
#'
#' Converts R package documentation (.Rd files) and metadata (DESCRIPTION)
#' into Quarto-compatible .qmd files for website generation. Integrates 
#' dataimago branding and philosophical foundations.
#'
#' @param package_path Character. Path to the R package root directory. 
#'   Must contain DESCRIPTION file and man/ directory with .Rd files.
#'   Default: "." (current directory)
#' @param output_path Character. Path to quarto website directory where .qmd files 
#'   will be generated. Directory will be created if it doesn't exist.
#'   Default: "quarto_website"
#' @param include_description Logical. Whether to include full DESCRIPTION file 
#'   content in the generated API reference. Useful for package metadata display.
#'   Default: TRUE
#' @param include_foundation_links Logical. Whether to add automatic links to 
#'   dataimago philosophical foundation documents in the generated documentation.
#'   Default: TRUE
#' @param template Character. Documentation template to use for styling and structure.
#'   Currently supports "dataimago" template with ethical AI branding.
#'   Default: "dataimago"
#'
#' @return Character (invisible). File path to the generated api_reference.qmd file.
#'   Side effects: Creates .qmd files in output_path directory and copies 
#'   dataimago assets (logos, etc.) to assets/img/ subdirectory.
#'
#' @details
#' This function implements dataimago's philosophy of "code-as-philosophy" by:
#' \itemize{
#'   \item **Hermeneutic Integration**: Parses the package DESCRIPTION for metadata
#'   \item **Technical Conversion**: Uses Rd2md to convert .Rd files to Quarto markdown
#'   \item **Ethical Annotation**: Adds philosophical context to every function via 
#'     \code{post_process_md_to_qmd()}
#'   \item **Foundation Linking**: Cross-references technical docs with philosophical content
#'   \item **Visual Identity**: Copies dataimago logos and applies custom CSS styling
#'   \item **AI Compatibility**: Generates machine-readable annotations for MCP integration
#' }
#'
#' The generated documentation structure includes:
#' \itemize{
#'   \item YAML frontmatter with package metadata
#'   \item Full DESCRIPTION file content (if requested)
#'   \item Links to dataimago foundation documents
#'   \item Function documentation with ethical context boxes
#'   \item dataimago branding footer on each function
#' }
#'
#' For AI agents and MCP tools, this function provides structured documentation 
#' generation that embeds philosophical context into technical reference material,
#' enabling AI systems to understand both the "what" and "why" of each function.
#'
#' @section MCP Tool Integration:
#' This function is designed for Model Context Protocol (MCP) integration:
#' \itemize{
#'   \item **Input Validation**: Checks for required package structure
#'   \item **Structured Output**: Generates consistent .qmd file format
#'   \item **Error Handling**: Provides clear error messages for debugging
#'   \item **Asset Management**: Handles file copying and directory creation
#'   \item **Status Reporting**: Uses colored console output for progress tracking
#' }
#'
#' @section Philosophical Context:
#' This function embodies dataimago's principle of embedding AI within culture for 
#' emancipatory purposes. Rather than treating documentation as mere technical 
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
                                       output_path = "quarto_website",
                                       include_description = TRUE,
                                       include_foundation_links = TRUE,
                                       template = "dataimago") {
  
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
  
  # Update dataimago assets if template is dataimago
  if (template == "dataimago") {
    update_dataimago_assets(output_path, package_path)
  }
  
  cat(crayon::green("\u2713 Quarto documentation generated successfully\n"))
  cat(crayon::silver("  API reference: "), api_file, "\n")
  
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
  
  return(desc_content)
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
  
  return(trimws(field_value))
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
    
    # Use Rd2md to convert .Rd to markdown (using new as_markdown function)
    md_content <- Rd2md::as_markdown(Rd2md::read_rdfile(rd_file))
    
    # Post-process markdown to qmd format with dataimago customizations
    qmd_content <- post_process_md_to_qmd(md_content, func_name)
    
    rd_content[[func_name]] <- qmd_content
  }
  
  return(rd_content)
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
      qmd_lines <- c(qmd_lines, paste0("This function embodies dataimago's principle of embedding AI within culture for emancipatory purposes."))
      qmd_lines <- c(qmd_lines, ":::")
      qmd_lines <- c(qmd_lines, "")
    } else if (grepl("^## Examples", line)) {
      # Add dataimago context to examples section
      qmd_lines <- c(qmd_lines, line)
      qmd_lines <- c(qmd_lines, "")
      qmd_lines <- c(qmd_lines, "_Examples using dataimago's ethical AI framework:_")
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
  qmd_lines <- c(qmd_lines, "*This function is part of the dataimago ethical AI framework.*")
  qmd_lines <- c(qmd_lines, "")
  
  return(qmd_lines)
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
  qmd_content <- c(qmd_content, paste0("title: \"", desc_content$package, " API Reference\""))
  qmd_content <- c(qmd_content, "subtitle: \"dataimago Ethical AI Framework\"")
  qmd_content <- c(qmd_content, paste0("version: \"", desc_content$version, "\""))
  qmd_content <- c(qmd_content, "format:")
  qmd_content <- c(qmd_content, "  html:")
  qmd_content <- c(qmd_content, "    toc: true")
  qmd_content <- c(qmd_content, "    toc-depth: 3")
  qmd_content <- c(qmd_content, "---")
  qmd_content <- c(qmd_content, "")
  
  # Add DESCRIPTION section if requested
  if (include_description && !is.null(desc_content$full_text)) {
    qmd_content <- c(qmd_content, "# DESCRIPTION")
    qmd_content <- c(qmd_content, "")
    qmd_content <- c(qmd_content, "```")
    qmd_content <- c(qmd_content, desc_content$full_text)
    qmd_content <- c(qmd_content, "```")
    qmd_content <- c(qmd_content, "")
  }
  
  # Add foundation links if requested
  if (include_foundation_links) {
    qmd_content <- c(qmd_content, "## dataimago Foundation")
    qmd_content <- c(qmd_content, "")
    qmd_content <- c(qmd_content, "This package is built on dataimago's ethical AI framework:")
    qmd_content <- c(qmd_content, "")
    qmd_content <- c(qmd_content, "- [Mission & Vision](../foundations/mission.html)")
    qmd_content <- c(qmd_content, "- [Philosophy](../foundations/philosophy.html)")
    qmd_content <- c(qmd_content, "- [Critical Theory Manifesto](../manifesto/critical_theory_manifesto.html)")
    qmd_content <- c(qmd_content, "")
  }
  
  # Add function documentation
  for (func_name in names(rd_content)) {
    qmd_content <- c(qmd_content, rd_content[[func_name]])
  }
  
  return(qmd_content)
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
  
  if (!dir.exists(img_dir)) {
    dir.create(img_dir, recursive = TRUE)
  }
  
  # Copy dataimago logos from inst/
  inst_dir <- file.path(package_path, "inst", "dataimago", "04_dataimago_Content", "Design_Assets", "logos")
  
  if (dir.exists(inst_dir)) {
    png_files <- list.files(inst_dir, pattern = "\\.png$", full.names = TRUE)
    
    for (png_file in png_files) {
      file.copy(png_file, img_dir, overwrite = TRUE)
    }
    
    cat(crayon::silver("  Copied"), length(png_files), "logo files to assets/img/\n")
  }
  
  invisible(TRUE)
}