#' @importFrom whisker whisker.render
#' @importFrom fs path file_exists
#' @importFrom glue glue
NULL

# Format a source package's exported functions as a markdown bullet list for the
# KNOWLEDGE.md {{EXPORTED_FUNCTIONS}} slot. Falls back to a placeholder.
format_exported_functions <- function(source_pkg) {
  placeholder <- "_(none yet -- add functions, then regenerate)_"
  if (is.null(source_pkg)) {
    return(placeholder)
  }
  out <- tryCatch(
    {
      exports <- parse_roxygen_exports(source_pkg, verbose = FALSE)
      if (length(exports) == 0) {
        return(placeholder)
      }
      lines <- vapply(exports, function(x) {
        title <- if (!is.null(x$title) && nzchar(x$title)) x$title else ""
        glue::glue("- `{x$name}()` -- {title}")
      }, character(1))
      paste(lines, collapse = "\n")
    },
    error = function(e) placeholder
  )
  out
}

#' Generate a KNOWLEDGE.md Domain Operating Manual
#'
#' Renders the domain-type KNOWLEDGE template (bundled in `inst/templates/`)
#' into a project's `KNOWLEDGE.md` -- the domain-layer operating manual that
#' pairs with `CLAUDE.md` (the build-layer manual). See the dataimago-design
#' patterns `dual-knowledge-layers` and `seeded-vs-curated-content`.
#'
#' @param project_path Character. Root directory of the project.
#' @param project_name Character. Project name (fills `{{PROJECT_NAME}}`).
#' @param domain_type Character. "framework", "research", or "explorer";
#'   selects the template. Default: "framework".
#' @param domain_name Character. Human-readable domain (fills `{{DOMAIN_NAME}}`).
#'   Default: `project_name`.
#' @param source_pkg Character. Path to the source R package whose exported
#'   functions fill `{{EXPORTED_FUNCTIONS}}`. NULL leaves a placeholder.
#' @param framework_wiki_url Character. Fills `{{FRAMEWORK_WIKI_URL}}`.
#' @param overwrite Logical. Replace an existing `KNOWLEDGE.md`. Default: FALSE.
#' @param verbose Logical. Print progress. Default: TRUE.
#'
#' @return Invisible list with the written file path + domain_type.
#' @keywords internal
generate_knowledge_md <- function(project_path,
                                  project_name,
                                  domain_type = c("framework", "research", "explorer"),
                                  domain_name = project_name,
                                  source_pkg = NULL,
                                  framework_wiki_url = "https://github.com/dataimago/dataimago-design",
                                  overwrite = FALSE,
                                  verbose = TRUE) {
  domain_type <- match.arg(domain_type)
  out_file <- fs::path(project_path, "KNOWLEDGE.md")

  if (fs::file_exists(out_file) && !isTRUE(overwrite)) {
    if (verbose) ui_info("Preserving existing KNOWLEDGE.md")
    return(invisible(list(file = "KNOWLEDGE.md", domain_type = domain_type, skipped = TRUE)))
  }

  template_path <- system.file(
    "templates", paste0("KNOWLEDGE-", domain_type, ".md"),
    package = "dataimago"
  )
  if (!nzchar(template_path) || !fs::file_exists(template_path)) {
    cli::cli_abort("KNOWLEDGE template not found for domain_type {.val {domain_type}}.")
  }

  template <- paste(readLines(template_path, warn = FALSE), collapse = "\n")
  rendered <- whisker::whisker.render(template, list(
    PROJECT_NAME = project_name,
    DOMAIN_NAME = domain_name,
    GENERATED_DATE = as.character(Sys.Date()),
    FRAMEWORK_WIKI_URL = framework_wiki_url,
    EXPORTED_FUNCTIONS = format_exported_functions(source_pkg)
  ))

  writeLines(rendered, out_file)
  if (verbose) ui_done(glue::glue("Generated KNOWLEDGE.md ({domain_type} domain)"))

  invisible(list(file = "KNOWLEDGE.md", domain_type = domain_type, skipped = FALSE))
}
