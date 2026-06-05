#' @importFrom fs dir_create dir_exists file_exists path
#' @importFrom glue glue
#' @importFrom whisker whisker.render
NULL

#' Generate a Claude Code Skill for an R Package
#'
#' Renders a real Claude Code Agent Skill at `.claude/skills/<slug>/SKILL.md`
#' (plus `workflows.md` + `examples.md` supporting files) that teaches an AI
#' agent when, why, and how to use a dataimago-backed R package. Because it
#' lives under `.claude/skills/` with `name` + `description` frontmatter, Claude
#' Code auto-discovers it when the generated repo is opened and auto-invokes it
#' when the `description` matches the task. The skill is the instructional
#' layer; MCP remains the callable tool layer.
#'
#' @param project_path Character. Root directory of the generated project.
#' @param project_name Character. Project/application name (slug fallback).
#' @param domain_type Character. "framework", "research", or "explorer";
#'   selects the primary skill template.
#' @param domain_name Character. Human-readable domain name.
#' @param source_pkg Character. Path to source R package. NULL leaves function
#'   sections as placeholders.
#' @param overwrite Logical. Replace existing curated skill files. Default:
#'   FALSE.
#' @param verbose Logical. Print progress. Default: TRUE.
#'
#' @return Invisible list with files created and skipped.
#' @export
generate_ai_skill <- function(
  project_path,
  project_name,
  domain_type = c("framework", "research", "explorer"),
  domain_name = project_name,
  source_pkg = NULL,
  overwrite = FALSE,
  verbose = TRUE
) {
  domain_type <- match.arg(domain_type)

  pkg_meta <- read_skill_pkg_metadata(source_pkg)
  base_name <- if (!is.null(source_pkg) && !identical(pkg_meta$name, "R package")) {
    pkg_meta$name
  } else {
    project_name
  }
  skill_slug <- skill_slug_for(base_name)

  skill_dir <- fs::path(project_path, ".claude", "skills", skill_slug)
  if (!fs::dir_exists(skill_dir)) {
    fs::dir_create(skill_dir, recurse = TRUE)
  }
  rel <- function(file) paste(c(".claude", "skills", skill_slug, file), collapse = "/")

  fn_names <- skill_function_names(source_pkg)
  exported_functions <- format_skill_functions(source_pkg)
  wiki_cautions <- format_skill_wiki_cautions(project_path)

  render_data <- list(
    PROJECT_NAME = project_name,
    DOMAIN_NAME = domain_name,
    DOMAIN_TYPE = domain_type,
    PACKAGE_NAME = pkg_meta$name,
    PACKAGE_TITLE = pkg_meta$title,
    PACKAGE_DESCRIPTION = pkg_meta$description,
    SKILL_NAME = skill_slug,
    SKILL_DESCRIPTION = build_skill_description(pkg_meta, fn_names, domain_name),
    GENERATED_DATE = as.character(Sys.Date()),
    GENERATOR_VERSION = dataimago_generator_version(),
    EXPORTED_FUNCTIONS = exported_functions,
    WIKI_CAUTIONS = wiki_cautions
  )

  template_path <- system.file(
    "templates",
    paste0("AI-SKILL-", domain_type, ".md"),
    package = "dataimago"
  )
  if (!nzchar(template_path) || !fs::file_exists(template_path)) {
    cli::cli_abort(
      "AI skill template not found for domain_type {.val {domain_type}}."
    )
  }

  results <- list(files_created = character(0), files_skipped = character(0))
  skill_content <- whisker::whisker.render(
    paste(readLines(template_path, warn = FALSE), collapse = "\n"),
    render_data
  )
  results <- write_skill_bundle_file(
    fs::path(skill_dir, "SKILL.md"),
    skill_content,
    rel("SKILL.md"),
    results,
    overwrite = overwrite
  )

  results <- write_skill_bundle_file(
    fs::path(skill_dir, "workflows.md"),
    render_skill_workflows(render_data),
    rel("workflows.md"),
    results,
    overwrite = overwrite
  )

  results <- write_skill_bundle_file(
    fs::path(skill_dir, "examples.md"),
    render_skill_examples(render_data),
    rel("examples.md"),
    results,
    overwrite = overwrite
  )

  # An R package must not ship `.claude/` in its tarball (R CMD check flags the
  # non-standard top-level dir). Make the skill turnkey by adding the exclusion.
  ensure_claude_buildignore(project_path)

  if (verbose) {
    ui_done(glue::glue(
      "Generated Claude skill .claude/skills/{skill_slug}/ with {length(results$files_created)} files"
    ))
  }

  invisible(results)
}

# Claude skill `name`: lowercase letters, digits, hyphens; <= 64 chars.
skill_slug_for <- function(name) {
  slug <- tolower(name)
  slug <- gsub("[^a-z0-9]+", "-", slug)
  slug <- gsub("^-+|-+$", "", slug)
  if (!nzchar(slug)) {
    slug <- "skill"
  }
  substr(slug, 1, 64)
}

# Build the skill `description` (what drives auto-invocation): a single,
# YAML-safe line within the 1024-char limit, leading with what the package is
# and the key exported functions, ending with a "use when" trigger phrase.
build_skill_description <- function(pkg_meta, fn_names, domain_name) {
  fns <- if (length(fn_names) > 0) {
    glue::glue("Key functions: {paste(fn_names, collapse = ', ')}.")
  } else {
    NULL
  }
  parts <- c(
    pkg_meta$title,
    pkg_meta$description,
    fns,
    glue::glue(
      "Use when an agent needs to understand or use the {pkg_meta$name} R package ",
      "for {domain_name}, or to interpret its outputs."
    )
  )
  text <- paste(parts[nzchar(parts)], collapse = " ")
  text <- trimws(gsub("\\s+", " ", text))
  if (nchar(text) > 1024) {
    text <- paste0(substr(text, 1, 1021), "...")
  }
  yaml_escape_dquoted(text)
}

# Escape a string for use inside a double-quoted YAML scalar.
yaml_escape_dquoted <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x
}

# Ensure `^\.claude$` is excluded from the R package tarball, when the project
# is an R package (has a DESCRIPTION). No-op otherwise (e.g. NextJS app repos).
ensure_claude_buildignore <- function(project_path) {
  if (!fs::file_exists(fs::path(project_path, "DESCRIPTION"))) {
    return(invisible(FALSE))
  }
  bi_path <- fs::path(project_path, ".Rbuildignore")
  entry <- "^\\.claude$"
  existing <- if (fs::file_exists(bi_path)) {
    readLines(bi_path, warn = FALSE)
  } else {
    character(0)
  }
  if (entry %in% existing) {
    return(invisible(FALSE))
  }
  writeLines(c(existing, entry), bi_path)
  invisible(TRUE)
}

read_skill_pkg_metadata <- function(source_pkg) {
  fallback <- list(
    name = "R package",
    title = "Generated R package",
    description = "No package DESCRIPTION was available."
  )
  if (is.null(source_pkg)) {
    return(fallback)
  }

  desc_path <- fs::path(source_pkg, "DESCRIPTION")
  if (!fs::file_exists(desc_path)) {
    return(fallback)
  }

  desc <- read.dcf(desc_path)
  field <- function(name, default = "") {
    if (name %in% colnames(desc)) desc[1, name] else default
  }

  list(
    name = field("Package", fallback$name),
    title = field("Title", fallback$title),
    description = field("Description", fallback$description)
  )
}

# Bare "name()" labels for the top exported functions, used to seed the skill
# description's trigger phrases.
skill_function_names <- function(source_pkg, limit = 8L) {
  if (is.null(source_pkg)) {
    return(character(0))
  }
  exports <- tryCatch(
    parse_roxygen_exports(source_pkg, verbose = FALSE),
    error = function(e) list()
  )
  if (length(exports) == 0) {
    return(character(0))
  }
  names_vec <- vapply(
    exports,
    function(fn) paste0(fn$name, "()"),
    character(1)
  )
  utils::head(names_vec, limit)
}

format_skill_functions <- function(source_pkg) {
  if (is.null(source_pkg)) {
    return(
      "- _(No exported functions were available when this skill was generated.)_"
    )
  }

  exports <- tryCatch(
    parse_roxygen_exports(source_pkg, verbose = FALSE),
    error = function(e) list()
  )
  if (length(exports) == 0) {
    return(
      "- _(No exported functions were available when this skill was generated.)_"
    )
  }

  paste(
    vapply(
      exports,
      function(fn) {
        params <- names(fn$params)
        params_text <- if (length(params) == 0) {
          "no parameters"
        } else {
          paste(params, collapse = ", ")
        }
        title <- if (!is.null(fn$title) && nzchar(fn$title)) {
          fn$title
        } else {
          fn$name
        }
        glue::glue("- `{fn$name}()` -- {title}. Parameters: {params_text}.")
      },
      character(1)
    ),
    collapse = "\n"
  )
}

format_skill_wiki_cautions <- function(project_path) {
  candidates <- c(
    fs::path(
      project_path,
      "wiki",
      "analyses",
      "dataimago-dogfood-lessons-2026-06-04.md"
    ),
    fs::path(project_path, "wiki", "overview.md"),
    fs::path(project_path, "KNOWLEDGE.md")
  )
  existing <- candidates[vapply(candidates, fs::file_exists, logical(1))]
  if (length(existing) == 0) {
    return(
      "- Treat private data, prototype outputs, and generated artifacts according to the project's local policy."
    )
  }

  bullets <- vapply(
    existing[seq_len(min(2L, length(existing)))],
    function(path) {
      glue::glue(
        "- Consult `{fs::path_file(path)}` for project-specific caveats before interpreting outputs."
      )
    },
    character(1)
  )
  paste(bullets, collapse = "\n")
}

write_skill_bundle_file <- function(
  path,
  content,
  relative_path,
  results,
  overwrite = FALSE
) {
  if (seeded_file_is_protected(path) && !isTRUE(overwrite)) {
    results$files_skipped <- c(results$files_skipped, relative_path)
    return(results)
  }

  writeLines(content, path)
  results$files_created <- c(results$files_created, relative_path)
  results
}

render_skill_workflows <- function(data) {
  c(
    "---",
    glue::glue("title: \"{data$PROJECT_NAME} AI Workflows\""),
    seeded_meta_lines(),
    "---",
    "",
    glue::glue("# {data$PROJECT_NAME} AI Workflows"),
    "",
    "## Default Workflow",
    "",
    "1. Read `SKILL.md` to confirm whether the requested task fits this package.",
    "2. Review the package functions and required parameters.",
    "3. Check project caveats before using private data or prototype outputs.",
    "4. Prefer exported package functions or generated MCP tools over internal helpers.",
    "5. Explain outputs using the package's domain vocabulary and limitations.",
    "",
    "## Safety Workflow",
    "",
    "- Treat every operation as read-only unless the tool metadata says otherwise.",
    "- Ask for confirmation before using private or client-specific data.",
    "- Do not interpret prototype outputs as production estimates."
  )
}

render_skill_examples <- function(data) {
  c(
    "---",
    glue::glue("title: \"{data$PROJECT_NAME} AI Examples\""),
    seeded_meta_lines(),
    "---",
    "",
    glue::glue("# {data$PROJECT_NAME} AI Examples"),
    "",
    "## Example: Discover Available Analyses",
    "",
    "Use the exported-function list in `SKILL.md` or the generated MCP schema to identify approved public functions.",
    "",
    "## Example: Run A Safe Analysis",
    "",
    "1. Confirm the requested task matches an exported function.",
    "2. Validate required parameters against the generated schema.",
    "3. Run the function or MCP tool.",
    "4. Report both the result and any documented caveats.",
    "",
    "## Exported Functions",
    "",
    data$EXPORTED_FUNCTIONS
  )
}
