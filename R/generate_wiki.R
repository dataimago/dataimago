#' @importFrom fs dir_exists dir_create path file_exists
#' @importFrom glue glue
#' @importFrom crayon green silver yellow red bold blue
#' @importFrom utils packageVersion
NULL

# Domain-type-aware wiki subdirectories (see dataimago-design ADR
# domain-type-generator-spec.md). raw/ is the same across all types.
wiki_subdirs_for <- function(domain_type) {
  switch(domain_type,
    framework = c("principles", "patterns", "decisions", "connections", "personas", "analyses"),
    research  = c("sources", "theories", "methods", "findings", "arguments", "personas", "analyses"),
    explorer  = c("dimensions", "attributes", "datasets", "sources", "personas", "analyses"),
    stop(sprintf("Unknown domain_type '%s'", domain_type))
  )
}

# Generator version stamped into seeded pages (seeded-vs-curated convention).
dataimago_generator_version <- function() {
  tryCatch(as.character(utils::packageVersion("dataimago")), error = function(e) "dev")
}

# The seeded-vs-curated frontmatter lines: a freshly generated page is
# `curated: false` (safe to regenerate) until a human edits it and flips it.
seeded_meta_lines <- function() {
  c(
    "curated: false",
    "generator: dataimago-rpkg",
    glue::glue("generator_version: {dataimago_generator_version()}")
  )
}

seeded_file_is_protected <- function(path) {
  if (!fs::file_exists(path)) {
    return(FALSE)
  }

  lines <- readLines(path, warn = FALSE)
  if (length(lines) == 0 || !identical(lines[1], "---")) {
    return(TRUE)
  }

  end <- which(lines[-1] == "---")[1]
  if (is.na(end)) {
    return(TRUE)
  }

  frontmatter <- lines[seq.int(2, end)]
  # Allow leading whitespace so a nested `metadata:\n  curated: false` (used by
  # the .claude/skills SKILL.md frontmatter) is still detected, not just a
  # top-level `curated: false`.
  if (any(grepl("^\\s*curated:\\s*false\\s*$", frontmatter))) {
    return(FALSE)
  }

  TRUE
}

write_seeded_file <- function(path, content, relative_path, results, overwrite = FALSE) {
  if (seeded_file_is_protected(path) && !isTRUE(overwrite)) {
    return(results)
  }

  writeLines(content, path)
  results$files_created <- c(results$files_created, relative_path)
  results
}

append_wiki_log_entry <- function(path, entry) {
  existing <- readLines(path, warn = FALSE)
  writeLines(c(existing, "", "---", "", entry), path)
}

#' Bootstrap a Wiki in a Generated Project
#'
#' Initializes a wiki/ directory in the generated project, seeded with
#' the project's domain knowledge extracted from the source R package.
#' Follows the same CLAUDE.md-driven wiki pattern used by dataimago-design.
#'
#' This is part of Phase D (Recursive Loop): generated projects inherit
#' the knowledge-compounding capability that makes dataimago itself effective.
#'
#' @param project_path Character. Root directory of the generated project
#' @param project_name Character. Name of the project
#' @param source_pkg Character. Path to the source R package (NULL for minimal wiki)
#' @param domain_type Character. Wiki domain type controlling the subdirectory
#'   structure: "framework" (principles/patterns/decisions/connections/...),
#'   "research" (sources/theories/methods/findings/...), or "explorer"
#'   (dimensions/attributes/datasets/...). Default: "framework".
#' @param overwrite Logical. Replace existing curated wiki pages. Default: FALSE.
#' @param verbose Logical. Print progress. Default: TRUE
#'
#' @return List with files created and wiki structure
#'
#' @keywords internal
bootstrap_wiki <- function(project_path,
                           project_name,
                           source_pkg = NULL,
                           domain_type = c("framework", "research", "explorer"),
                           overwrite = FALSE,
                           verbose = TRUE) {
  domain_type <- match.arg(domain_type)
  if (verbose) ui_info(glue::glue("Bootstrapping {domain_type} project wiki..."))

  wiki_dir <- fs::path(project_path, "wiki")
  results <- list(
    files_created = character(0),
    success = FALSE
  )

  tryCatch(
    {
      # Create wiki directory structure (domain-type-aware)
      subdirs <- wiki_subdirs_for(domain_type)
      dirs <- c(wiki_dir, fs::path(wiki_dir, subdirs))

      for (d in dirs) {
        if (!fs::dir_exists(d)) {
          fs::dir_create(d, recurse = TRUE)
        }
      }
      # .gitkeep so empty domain subdirs are tracked
      for (sd in subdirs) {
        gk <- fs::path(wiki_dir, sd, ".gitkeep")
        if (!fs::file_exists(gk)) writeLines(character(0), gk)
      }

      # Create raw/ directory structure (Karpathy 3-layer pattern)
      raw_dirs <- c(
        fs::path(project_path, "raw"),
        fs::path(project_path, "raw", "papers"),
        fs::path(project_path, "raw", "conversations"),
        fs::path(project_path, "raw", "data"),
        fs::path(project_path, "raw", "references")
      )
      for (d in raw_dirs) {
        if (!fs::dir_exists(d)) fs::dir_create(d, recurse = TRUE)
      }
      for (d in raw_dirs[-1]) {
        gitkeep <- fs::path(d, ".gitkeep")
        if (!fs::file_exists(gitkeep)) writeLines(character(0), gitkeep)
      }

      # Create index.md
      index_content <- create_wiki_index(project_name, source_pkg)
      results <- write_seeded_file(
        fs::path(wiki_dir, "index.md"), index_content, "wiki/index.md", results,
        overwrite = overwrite
      )

      # Create glossary.md
      glossary_content <- create_wiki_glossary(project_name, source_pkg)
      results <- write_seeded_file(
        fs::path(wiki_dir, "glossary.md"), glossary_content, "wiki/glossary.md", results,
        overwrite = overwrite
      )

      # Create log.md
      log_entry <- c(
        glue::glue("## [{Sys.Date()}] bootstrap | Wiki initialized by dataimago"),
        "",
        glue::glue("Project '{project_name}' wiki created by dataimago::ai()."),
        if (!is.null(source_pkg)) {
          glue::glue("Seeded with domain context from source R package.")
        } else {
          "Minimal wiki created without source package context."
        },
        ""
      )
      log_content <- c(
        "---",
        "title: Activity Log",
        "type: log",
        glue::glue("created: {Sys.Date()}"),
        glue::glue("updated: {Sys.Date()}"),
        seeded_meta_lines(),
        "---",
        "",
        "# Wiki Activity Log",
        "",
        "Chronological record of all wiki activity. Newest entries at top.",
        "",
        "---",
        "",
        log_entry
      )
      log_path <- fs::path(wiki_dir, "log.md")
      if (fs::file_exists(log_path) && !isTRUE(overwrite)) {
        append_wiki_log_entry(log_path, log_entry)
      } else {
        writeLines(log_content, log_path)
        results$files_created <- c(results$files_created, "wiki/log.md")
      }

      # Create overview.md
      overview_content <- create_wiki_overview(project_name, source_pkg)
      results <- write_seeded_file(
        fs::path(wiki_dir, "overview.md"), overview_content, "wiki/overview.md", results,
        overwrite = overwrite
      )

      # If source package provided, create source summary + ADR. These land in
      # wiki/sources and wiki/decisions; ensure those dirs exist (they are not
      # in every domain type's canonical subdir list).
      if (!is.null(source_pkg)) {
        pkg_source <- create_pkg_source_page(source_pkg, verbose)
        if (!is.null(pkg_source)) {
          fs::dir_create(fs::path(wiki_dir, "sources"), recurse = TRUE)
          results <- write_seeded_file(
            fs::path(wiki_dir, "sources", pkg_source$filename),
            pkg_source$content,
            fs::path("wiki", "sources", pkg_source$filename),
            results,
            overwrite = overwrite
          )
        }

        # Create architecture decision record
        fs::dir_create(fs::path(wiki_dir, "decisions"), recurse = TRUE)
        adr_content <- create_initial_adr(project_name, source_pkg)
        results <- write_seeded_file(
          fs::path(wiki_dir, "decisions", "001-dataimago-generation.md"),
          adr_content,
          "wiki/decisions/001-dataimago-generation.md",
          results,
          overwrite = overwrite
        )
      }

      results$success <- TRUE
      if (verbose) {
        ui_done(glue::glue("Wiki bootstrapped with {length(results$files_created)} files"))
      }
    },
    error = function(e) {
      if (verbose) ui_warn(glue::glue("Wiki bootstrap encountered issues: {e$message}"))
    }
  )

  invisible(results)
}


# ====================================================================
# Wiki page generators
# ====================================================================

create_wiki_index <- function(project_name, source_pkg) {
  pages <- c(
    "- [Overview](overview.md) \u2014 High-level project synthesis",
    "- [Glossary](glossary.md) \u2014 Canonical terminology and definitions",
    "- [Activity Log](log.md) \u2014 Chronological record of wiki changes"
  )

  if (!is.null(source_pkg)) {
    desc_path <- fs::path(source_pkg, "DESCRIPTION")
    if (fs::file_exists(desc_path)) {
      desc_lines <- readLines(desc_path)
      pkg_line <- grep("^Package:", desc_lines, value = TRUE)
      if (length(pkg_line) > 0) {
        pkg_name <- trimws(sub("^Package:\\s*", "", pkg_line[1]))
        pages <- c(
          pages,
          glue::glue("- [Source: {pkg_name}](sources/{pkg_name}-package.md) \u2014 Source R package documentation")
        )
      }
    }
    pages <- c(
      pages,
      "- [ADR-001: dataimago Generation](decisions/001-dataimago-generation.md) \u2014 Architecture decision record"
    )
  }

  c(
    "---",
    glue::glue("title: \"{project_name} Wiki Index\""),
    "type: index",
    glue::glue("created: {Sys.Date()}"),
    glue::glue("updated: {Sys.Date()}"),
    seeded_meta_lines(),
    "---",
    "",
    glue::glue("# {project_name} Knowledge Base"),
    "",
    glue::glue("Master catalog of all wiki pages for {project_name}."),
    "",
    "## Pages",
    "",
    pages,
    "",
    "---",
    "",
    "*This wiki was bootstrapped by dataimago. Add pages as your project evolves.*"
  )
}

create_wiki_glossary <- function(project_name, source_pkg) {
  terms <- c(
    "| **AI-Native** | An application designed from the ground up to serve human users, AI agents, and data services simultaneously |",
    "| **Dual-Mode API** | API client that switches between live R server (development) and static JSON (production) |",
    "| **Ethical Tokens** | Three-tier design hierarchy (Primitive \u2192 Semantic \u2192 Ethical) embedding values in CSS |",
    "| **MCP** | Model Context Protocol \u2014 standard for AI agents to call tools and access resources |",
    "| **Meta-Tool** | A tool that produces tools \u2014 dataimago generates AI-native apps that themselves use AI |",
    "| **R as Source of Truth** | Architectural pattern where R functions are the canonical analysis layer |",
    "| **Static Export** | Pre-computed JSON files enabling serverless deployment without R runtime |"
  )

  c(
    "---",
    glue::glue("title: \"{project_name} Glossary\""),
    "type: glossary",
    glue::glue("created: {Sys.Date()}"),
    glue::glue("updated: {Sys.Date()}"),
    seeded_meta_lines(),
    "---",
    "",
    "# Glossary",
    "",
    "Canonical terminology for this project. Inherited from dataimago with project-specific additions.",
    "",
    "| Term | Definition |",
    "|------|-----------|",
    terms,
    "",
    "---",
    "",
    "*Add project-specific terms as your domain knowledge develops.*"
  )
}

create_wiki_overview <- function(project_name, source_pkg) {
  c(
    "---",
    glue::glue("title: \"{project_name} Overview\""),
    "type: overview",
    glue::glue("created: {Sys.Date()}"),
    glue::glue("updated: {Sys.Date()}"),
    seeded_meta_lines(),
    "---",
    "",
    glue::glue("# {project_name}"),
    "",
    "This is an AI-native application generated by the dataimago meta-tool framework.",
    if (!is.null(source_pkg)) {
      "It transforms R analysis functions into an interactive web experience with REST APIs, MCP tools, and data visualizations."
    } else {
      "It provides scaffolding for building an AI-native web application."
    },
    "",
    "## Architecture",
    "",
    "The application follows the dataimago three-layer model:",
    "- **Design System** (dataimago-design): Ethical tokens, CSS, enforcement tools",
    "- **R Orchestration** (dataimago-rpkg): Analysis functions, API generation, build pipeline",
    "- **Web Application** (this project): Interactive frontend, MCP tools, data visualization",
    "",
    "## Related Resources",
    "",
    "- [[glossary]] \u2014 Terminology and definitions",
    "- [[log]] \u2014 Activity history",
    "",
    "*Update this overview as the project evolves.*"
  )
}

create_pkg_source_page <- function(source_pkg, verbose) {
  desc_path <- fs::path(source_pkg, "DESCRIPTION")
  if (!fs::file_exists(desc_path)) {
    return(NULL)
  }

  desc_lines <- readLines(desc_path)
  pkg_name <- trimws(sub("^Package:\\s*", "", grep("^Package:", desc_lines, value = TRUE)[1]))
  title <- trimws(sub("^Title:\\s*", "", grep("^Title:", desc_lines, value = TRUE)[1]))
  desc <- trimws(sub("^Description:\\s*", "", grep("^Description:", desc_lines, value = TRUE)[1]))
  version <- trimws(sub("^Version:\\s*", "", grep("^Version:", desc_lines, value = TRUE)[1]))

  # Get exports
  export_section <- ""
  tryCatch(
    {
      exports <- parse_roxygen_exports(source_pkg, verbose = FALSE)
      if (length(exports) > 0) {
        fn_lines <- vapply(exports, function(x) {
          fn_title <- if (!is.null(x$title)) x$title else ""
          glue::glue("- `{x$name}()` \u2014 {fn_title}")
        }, character(1))
        export_section <- paste0(
          "\n## Exported Functions\n\n",
          paste(fn_lines, collapse = "\n"),
          "\n"
        )
      }
    },
    error = function(e) {
      if (verbose) ui_warn(glue::glue("Could not parse exports for wiki: {e$message}"))
    }
  )

  content <- c(
    "---",
    glue::glue("title: \"Source: {pkg_name} R Package\""),
    "type: source",
    glue::glue("created: {Sys.Date()}"),
    glue::glue("updated: {Sys.Date()}"),
    seeded_meta_lines(),
    "tags:",
    "  - r-package",
    "  - source-of-truth",
    "---",
    "",
    glue::glue("{title} (v{version})"),
    "",
    glue::glue("## Description"),
    "",
    if (!is.na(desc)) desc else "No description available.",
    export_section,
    "",
    "## Related Pages",
    "",
    "- [[overview]]",
    "- [[001-dataimago-generation]]"
  )

  list(
    filename = paste0(pkg_name, "-package.md"),
    content = content
  )
}

create_initial_adr <- function(project_name, source_pkg) {
  c(
    "---",
    "title: \"ADR-001: Project Generation with dataimago\"",
    "type: decision",
    glue::glue("created: {Sys.Date()}"),
    glue::glue("updated: {Sys.Date()}"),
    seeded_meta_lines(),
    "tags:",
    "  - architecture",
    "  - generation",
    "---",
    "",
    "Architecture decision record for the initial project generation.",
    "",
    "## Context",
    "",
    glue::glue("This project ({project_name}) was generated by `dataimago::ai()` using"),
    "the meta-tool pipeline: R functions \u2192 REST API \u2192 MCP Tools \u2192 TypeScript \u2192 Web UI.",
    "",
    "## Decision",
    "",
    "Use dataimago's full meta-tool pipeline to derive all API, MCP, and type",
    "definitions from the source R package's exported functions and roxygen documentation.",
    "",
    "## Rationale",
    "",
    "- **Single source of truth**: R package is the canonical analysis layer",
    "- **Automatic derivation**: Reduces maintenance burden and inconsistency",
    "- **Dual-mode deployment**: Static JSON enables serverless; live API enables development",
    "- **Ethical inheritance**: Design system constraints propagate automatically",
    "",
    "## Consequences",
    "",
    "- Changes to R function signatures require regenerating API/MCP/types",
    "- Custom TypeScript types in shared-utils will be overwritten on regeneration",
    "- Static export needs re-running when R function behavior changes",
    "",
    "## Related Pages",
    "",
    "- [[overview]]"
  )
}
