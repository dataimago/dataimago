#' Reference pages, news page and site scaffold for an R package
#'
#' Helpers that turn a package's `man/*.Rd`, `NEWS.md`, README and vignettes into the
#' pages of a Quarto website. [create_package_reference()] writes one page per Rd topic
#' plus a reference index, [create_package_news()] writes `news.qmd` from `NEWS.md`, and
#' [create_package_site()] scaffolds a whole site (configuration, theme extension,
#' self-hosted fonts, articles, citation page and a GitHub Pages workflow).
#'
#' @name package_site
#' @keywords internal
NULL

# ---- small utilities --------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x

.write_lines <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(x), path, useBytes = TRUE)
  invisible(path)
}

.yaml_quote <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("\"", "\\\"", x, fixed = TRUE)
  paste0("\"", x, "\"")
}

.find_pandoc <- function() {
  p <- Sys.which("pandoc")
  if (nzchar(p)) {
    return(c(unname(p)))
  }
  q <- Sys.which("quarto")
  if (nzchar(q)) {
    return(c(unname(q), "pandoc"))
  }
  stop("pandoc is required to convert Rd topics (install pandoc or Quarto).", call. = FALSE)
}

.html_to_markdown <- function(html) {
  cmd <- .find_pandoc()
  args <- c(cmd[-1], "-f", "html", "-t", "markdown-smart", "--wrap=none")
  out <- system2(cmd[1], args, input = html, stdout = TRUE, stderr = FALSE)
  out
}

# ---- Rd topic metadata ------------------------------------------------------

.rd_tag_text <- function(rd, tag) {
  idx <- which(vapply(rd, function(x) identical(attr(x, "Rd_tag"), tag), logical(1)))
  vapply(idx, function(i) {
    trimws(paste(unlist(rd[[i]]), collapse = ""))
  }, character(1))
}

.rd_topic_meta <- function(rd_file) {
  rd <- suppressWarnings(tools::parse_Rd(rd_file, permissive = TRUE))
  name <- .rd_tag_text(rd, "\\name")[1]
  aliases <- unique(c(name, .rd_tag_text(rd, "\\alias")))
  title <- gsub("\\s+", " ", .rd_tag_text(rd, "\\title")[1] %||% name)
  usage <- paste(.rd_tag_text(rd, "\\usage"), collapse = "\n")
  doc_type <- .rd_tag_text(rd, "\\docType")[1] %||% ""
  keywords <- .rd_tag_text(rd, "\\keyword")
  is_fun <- grepl(paste0("(^|[^A-Za-z0-9_.])", gsub("([.])", "\\\\\\1", name), "\\s*\\("), usage)
  list(
    file = rd_file, rd = rd, name = name, aliases = aliases, title = title,
    doc_type = doc_type, keywords = keywords, is_function = is_fun,
    internal = "internal" %in% keywords,
    is_data = identical(doc_type, "data") || "datasets" %in% keywords,
    is_package = identical(doc_type, "package") || grepl("-package$", name)
  )
}

.topic_slug <- function(name) gsub("[^A-Za-z0-9_.-]", "_", name)

.base_packages <- c(
  "base", "stats", "utils", "methods", "graphics", "grDevices", "tools", "datasets", "grid",
  "parallel", "compiler", "splines", "stats4", "tcltk"
)

.rewrite_rd_links <- function(html, package) {
  pat <- "href=\"(?:\\.\\./)+([A-Za-z0-9.]+)/help/([^\"#]+)\\.html(#[^\"]*)?\""
  m <- gregexpr(pat, html, perl = TRUE)
  regmatches(html, m) <- lapply(regmatches(html, m), function(hits) {
    vapply(hits, function(h) {
      parts <- regmatches(h, regexec(pat, h, perl = TRUE))[[1]]
      pkg <- parts[2]
      topic <- utils::URLdecode(parts[3])
      anchor <- if (length(parts) >= 4) parts[4] else ""
      if (identical(pkg, package)) {
        sprintf("href=\"%s.html%s\"", .topic_slug(topic), anchor)
      } else if (pkg %in% .base_packages) {
        sprintf("href=\"https://rdrr.io/r/%s/%s.html\"", pkg, topic)
      } else {
        sprintf("href=\"https://rdrr.io/pkg/%s/man/%s.html\"", pkg, topic)
      }
    }, character(1))
  })
  html
}

# Rd2HTML emits an "Arguments" (and "Value") table of name/description rows. Definition
# lists convert to Pandoc markdown cleanly, tables with block content do not.
.rd_tables_to_dl <- function(html) {
  pat <- "(?s)<table[^>]*role\\s*=\\s*\"presentation\"[^>]*>(.*?)</table>"
  m <- gregexpr(pat, html, perl = TRUE)
  regmatches(html, m) <- lapply(regmatches(html, m), function(tabs) {
    vapply(tabs, function(tab) {
      inner <- sub(pat, "\\1", tab, perl = TRUE)
      row_pat <- "(?s)<tr[^>]*>\\s*<td[^>]*>(.*?)</td>\\s*<td[^>]*>(.*?)</td>\\s*</tr>"
      inner <- gsub(row_pat, "<dt>\\1</dt><dd>\\2</dd>", inner, perl = TRUE)
      paste0("<dl>", inner, "</dl>")
    }, character(1))
  })
  html
}

.rd_topic_markdown <- function(meta, package, figures_prefix = "../assets/figures/") {
  out <- tempfile(fileext = ".html")
  on.exit(unlink(out), add = TRUE)
  rd <- meta$rd
  # Top-level newline text renders as empty "NA" headings in fragment mode, and the name,
  # title and index entries are carried by the page front matter instead.
  meta_tags <- c("TEXT", "COMMENT", "\\name", "\\alias", "\\title", "\\docType", "\\keyword", "\\concept", "\\encoding", "\\Rdversion")
  keep <- !vapply(rd, function(x) attr(x, "Rd_tag") %in% meta_tags, logical(1))
  rd <- structure(rd[keep], class = "Rd")
  suppressWarnings(tools::Rd2HTML(
    rd,
    out = out, fragment = TRUE, Links = .topic_links_cache$links, Links2 = character(),
    stages = c("build", "install", "render"), package = "", dynamic = FALSE
  ))
  html <- paste(readLines(out, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  # Title and Name blocks repeat the page title.
  html <- sub("(?s)<h3>Title</h3>\\s*<p>.*?</p>\\s*", "", html, perl = TRUE)
  html <- sub("<h3>Name</h3>\\s*[^<]*", "", html, perl = TRUE)
  html <- gsub("<h3>NA</h3>\\s*", "", html, perl = TRUE)
  # \figure{} (the hex logo on the package page) is written as ../help/figures/<file>.
  html <- gsub("(\\.\\./)?help/figures/", figures_prefix, html, perl = TRUE)
  html <- .rewrite_rd_links(html, package)
  html <- .rd_tables_to_dl(html)
  html <- gsub("<h3>", "<h2>", html, fixed = TRUE)
  html <- gsub("</h3>", "</h2>", html, fixed = TRUE)
  md <- .html_to_markdown(html)
  # Keep example blocks from being treated as executable chunks.
  md <- gsub("^``` *\\{\\.R\\}", "``` r", md)
  md
}

.topic_links_cache <- new.env(parent = emptyenv())

# ---- reference --------------------------------------------------------------

.read_reference_config <- function(reference_config) {
  if (is.null(reference_config)) {
    return(NULL)
  }
  if (is.character(reference_config) && length(reference_config) == 1L) {
    if (!file.exists(reference_config)) {
      return(NULL)
    }
    reference_config <- yaml::read_yaml(reference_config)
  }
  reference_config
}

.default_sections <- function(topics) {
  public <- Filter(function(t) !t$internal, topics)
  pick <- function(f) names(Filter(f, public))
  list(
    list(title = "Package", contents = pick(function(t) t$is_package)),
    list(title = "Data sets", contents = pick(function(t) t$is_data && !t$is_package)),
    list(title = "Functions", contents = pick(function(t) !t$is_data && !t$is_package))
  )
}

.resolve_sections <- function(topics, config) {
  alias_map <- list()
  for (nm in names(topics)) {
    for (a in topics[[nm]]$aliases) alias_map[[a]] <- nm
  }
  sections <- config %||% .default_sections(topics)
  used <- character(0)
  resolved <- lapply(sections, function(s) {
    keys <- unlist(s$contents)
    keys <- vapply(keys, function(k) alias_map[[k]] %||% NA_character_, character(1))
    keys <- unique(keys[!is.na(keys)])
    used <<- c(used, keys)
    list(title = s$title, desc = s$desc %||% NULL, contents = keys)
  })
  leftover <- setdiff(names(Filter(function(t) !t$internal, topics)), used)
  if (length(leftover) > 0L && !is.null(config)) {
    resolved[[length(resolved) + 1L]] <- list(title = "Other", desc = NULL, contents = leftover)
  }
  Filter(function(s) length(s$contents) > 0L, resolved)
}

#' Write one reference page per Rd topic and a reference index
#'
#' Converts every `man/*.Rd` file of a package into `reference/<topic>.qmd` and writes
#' `reference/index.qmd`. Topics marked `\\keyword{internal}` get a page (so links to them
#' resolve) but are left out of the index.
#'
#' The index is grouped by `reference_config`, a list or the path to a YAML file of
#' sections, each with a `title`, an optional `desc` and `contents` (topic names or
#' aliases). Without a configuration the sections are Package, Data sets and Functions.
#' Topics a configuration does not mention are collected under "Other".
#'
#' @param package_path Path to the package root.
#' @param output_path Quarto project directory the pages are written into.
#' @param reference_dir Sub-directory of `output_path` for the pages.
#' @param reference_config Optional list or path to a YAML file of index sections.
#' @return Character vector of the files written (invisibly).
#' @examples
#' \dontrun{
#' create_package_reference(".", "ui/www")
#' }
#' @export
create_package_reference <- function(package_path = ".", output_path = "ui/www",
                                     reference_dir = "reference", reference_config = NULL) {
  desc_file <- file.path(package_path, "DESCRIPTION")
  if (!file.exists(desc_file)) stop("DESCRIPTION not found in package_path: ", package_path, call. = FALSE)
  package <- read.dcf(desc_file, fields = "Package")[1, 1]
  rd_files <- sort(list.files(file.path(package_path, "man"), pattern = "\\.Rd$", full.names = TRUE))
  if (length(rd_files) == 0L) stop("No .Rd files in ", file.path(package_path, "man"), call. = FALSE)

  topics <- lapply(rd_files, .rd_topic_meta)
  names(topics) <- vapply(topics, function(t) t$name, character(1))
  if (anyDuplicated(names(topics))) stop("Duplicate Rd \\name entries.", call. = FALSE)

  links <- character(0)
  for (t in topics) {
    for (a in t$aliases) links[a] <- paste0(.topic_slug(t$name), ".html")
  }
  .topic_links_cache$links <- links
  on.exit(rm(list = ls(.topic_links_cache), envir = .topic_links_cache), add = TRUE)

  ref_path <- file.path(output_path, reference_dir)
  dir.create(ref_path, recursive = TRUE, showWarnings = FALSE)
  written <- character(0)

  # Figures that Rd files include with \figure{} travel with the site.
  fig_dir <- file.path(package_path, "man", "figures")
  if (dir.exists(fig_dir)) {
    dest <- file.path(output_path, "assets", "figures")
    dir.create(dest, recursive = TRUE, showWarnings = FALSE)
    file.copy(list.files(fig_dir, full.names = TRUE), dest, overwrite = TRUE)
  }
  up <- paste(rep("..", length(strsplit(reference_dir, "/", fixed = TRUE)[[1]])), collapse = "/")
  figures_prefix <- paste0(up, "/assets/figures/")

  for (t in topics) {
    body <- .rd_topic_markdown(t, package, figures_prefix)
    label <- if (t$is_function) paste0(t$name, "()") else t$name
    qmd <- c(
      "---",
      paste0("title: ", .yaml_quote(label)),
      paste0("subtitle: ", .yaml_quote(t$title)),
      "toc: true",
      "---",
      "",
      body,
      ""
    )
    written <- c(written, .write_lines(qmd, file.path(ref_path, paste0(.topic_slug(t$name), ".qmd"))))
  }

  sections <- .resolve_sections(topics, .read_reference_config(reference_config))
  index <- c(
    "---",
    "title: \"Reference\"",
    "toc: false",
    "---",
    ""
  )
  data_done <- FALSE
  for (s in sections) {
    has_data_topic <- !data_done && any(vapply(s$contents, function(nm) isTRUE(topics[[nm]]$is_data), logical(1)))
    if (has_data_topic) data_done <- TRUE
    index <- c(index, paste0("## ", s$title, if (has_data_topic) " {#ref-data}" else ""), "")
    if (!is.null(s$desc)) index <- c(index, s$desc, "")
    index <- c(index, "::: {.reference-index}", "")
    for (nm in s$contents) {
      t <- topics[[nm]]
      label <- if (t$is_function) paste0(t$name, "()") else t$name
      index <- c(index, paste0("[`", label, "`](", .topic_slug(t$name), ".html)"), paste0(":   ", t$title), "")
    }
    index <- c(index, ":::", "")
  }
  written <- c(written, .write_lines(index, file.path(ref_path, "index.qmd")))
  invisible(written)
}

# ---- news -------------------------------------------------------------------

#' Write `news.qmd` from a package's `NEWS.md`
#'
#' Headings in `NEWS.md` move down one level so the page title stays the only level-one
#' heading. Plain-text `NEWS` files are not converted.
#'
#' @param package_path Path to the package root.
#' @param output_path Quarto project directory the page is written into.
#' @param file File name of the page.
#' @return The path written, or `NULL` when the package has no `NEWS.md` (invisibly).
#' @export
create_package_news <- function(package_path = ".", output_path = "ui/www", file = "news.qmd") {
  candidates <- file.path(package_path, c("NEWS.md", file.path("inst", "NEWS.md")))
  news <- candidates[file.exists(candidates)][1]
  if (is.na(news)) {
    return(invisible(NULL))
  }
  lines <- readLines(news, warn = FALSE, encoding = "UTF-8")
  in_fence <- FALSE
  for (i in seq_along(lines)) {
    if (grepl("^```", lines[i])) in_fence <- !in_fence
    if (!in_fence && grepl("^#+ ", lines[i])) lines[i] <- paste0("#", lines[i])
  }
  qmd <- c(
    "---", "title: \"News\"", "toc: true", "toc-depth: 2",
    "aliases: [news/index.html]", "---", "", lines, ""
  )
  invisible(.write_lines(qmd, file.path(output_path, file)))
}

# ---- vignettes -> articles --------------------------------------------------

.split_front_matter <- function(lines) {
  if (length(lines) > 1L && identical(trimws(lines[1]), "---")) {
    end <- which(trimws(lines[-1]) %in% c("---", "..."))[1]
    if (!is.na(end)) {
      return(list(yaml = lines[2:end], body = lines[-seq_len(end + 1L)]))
    }
  }
  list(yaml = character(0), body = lines)
}

# Quarto only understands ISO-like dates. R vignettes often carry prose dates such as
# "September 26th, 2017"; turn those into ISO dates, and drop what cannot be parsed so the
# page does not show "Invalid Date".
.normalize_date <- function(x) {
  x <- trimws(paste(as.character(x), collapse = " "))
  if (!nzchar(x)) {
    return(NA_character_)
  }
  x <- gsub("([0-9])(st|nd|rd|th)\\b", "\\1", x)
  old <- Sys.getlocale("LC_TIME")
  on.exit(Sys.setlocale("LC_TIME", old), add = TRUE)
  Sys.setlocale("LC_TIME", "C")
  for (fmt in c("%Y-%m-%d", "%B %d, %Y", "%b %d, %Y", "%B %d %Y", "%d %B %Y", "%b %d %Y")) {
    d <- as.Date(x, format = fmt)
    if (!is.na(d)) {
      return(format(d, "%Y-%m-%d"))
    }
  }
  NA_character_
}

.vignette_to_article <- function(path) {
  parts <- .split_front_matter(readLines(path, warn = FALSE, encoding = "UTF-8"))
  meta <- tryCatch(yaml::yaml.load(paste(parts$yaml, collapse = "\n")), error = function(e) list())
  title <- meta$title %||% tools::file_path_sans_ext(basename(path))
  title <- gsub("\\s+", " ", paste(title, collapse = " "))
  front <- c("---", paste0("title: ", .yaml_quote(title)))
  if (!is.null(meta$author)) front <- c(front, paste0("author: ", .yaml_quote(paste(unlist(meta$author), collapse = ", "))))
  if (!is.null(meta$date) && !grepl("Sys.Date|`r", paste(meta$date, collapse = ""))) {
    date <- .normalize_date(meta$date)
    if (!is.na(date)) front <- c(front, paste0("date: ", .yaml_quote(date)))
  }
  front <- c(front, "toc: true", "---", "")
  c(front, parts$body)
}

.copy_vignettes <- function(package_path, output_path) {
  vdir <- file.path(package_path, "vignettes")
  files <- list.files(vdir, pattern = "\\.(Rmd|qmd)$", recursive = TRUE, full.names = TRUE)
  written <- character(0)
  for (f in files) {
    rel <- sub(paste0("^", gsub("([.])", "\\\\\\1", normalizePath(vdir)), "/?"), "", normalizePath(f))
    target <- file.path(output_path, "articles", sub("\\.Rmd$", ".qmd", rel))
    written <- c(written, .write_lines(.vignette_to_article(f), target))
  }
  # Figures and data files referenced by the vignettes travel with them.
  other <- list.files(vdir, recursive = TRUE, full.names = TRUE)
  other <- other[!grepl("\\.(Rmd|qmd|R|html|pdf)$", other)]
  for (f in other) {
    rel <- sub(paste0("^", gsub("([.])", "\\\\\\1", normalizePath(vdir)), "/?"), "", normalizePath(f))
    dir.create(dirname(file.path(output_path, "articles", rel)), recursive = TRUE, showWarnings = FALSE)
    file.copy(f, file.path(output_path, "articles", rel), overwrite = TRUE)
  }
  written
}

# ---- site scaffold ----------------------------------------------------------

.read_desc <- function(package_path) {
  d <- read.dcf(file.path(package_path, "DESCRIPTION"))[1, ]
  as.list(d)
}

.authors <- function(desc) {
  if (!is.null(desc[["Authors@R"]])) {
    p <- tryCatch(eval(parse(text = desc[["Authors@R"]])), error = function(e) NULL)
    if (!is.null(p)) {
      return(p)
    }
  }
  if (!is.null(desc$Author)) {
    return(utils::as.person(desc$Author))
  }
  NULL
}

.citation_page <- function(package_path, desc) {
  meta <- desc
  meta$Date <- meta$Date %||% format(Sys.Date())
  cff <- file.path(package_path, "inst", "CITATION")
  cit <- tryCatch(
    if (file.exists(cff)) utils::readCitationFile(cff, meta = meta) else utils::citation(auto = meta),
    error = function(e) NULL
  )
  people <- .authors(desc)
  out <- c("---", "title: \"Citation and authors\"", "toc: false", "---", "")
  if (!is.null(cit)) {
    txt <- paste(format(cit, style = "text"), collapse = "\n\n")
    bib <- paste(format(cit, style = "Bibtex"), collapse = "\n\n")
    cite_lines <- c(
      "## Citation", "", "To cite this package in publications, please use:", "", txt, "",
      "A BibTeX entry:", "", "```bibtex", bib, "```", ""
    )
    out <- c(out, cite_lines)
  }
  if (!is.null(people)) {
    out <- c(out, "## Authors", "")
    for (p in people) {
      roles <- paste(p$role %||% "", collapse = ", ")
      nm <- format(p, include = c("given", "family"))
      out <- c(out, paste0("- ", nm, if (nzchar(roles)) paste0(" (", roles, ")") else ""))
    }
    out <- c(out, "")
  }
  out
}

.pkg_quarto_yml <- function(desc, site_url, repo_url, navbar_pinned, org, org_url, has_news,
                            has_articles, has_vignette_main, logo, font_css, has_data = FALSE,
                            has_papers = FALSE, has_talks = FALSE) {
  pkg <- desc$Package
  year <- format(Sys.Date(), "%Y")
  people <- .authors(desc)
  owner <- if (!is.null(people)) format(people[1], include = c("given", "family")) else pkg
  menu_item <- function(href, text) c(paste0("          - href: ", href), paste0("            text: ", .yaml_quote(text)))
  left <- c(
    "      - href: overview/index.qmd", "        text: Overview",
    "      - text: Documentation",
    "        menu:",
    if (has_vignette_main) menu_item(paste0("articles/", pkg, ".qmd"), "Get started"),
    if (has_articles) menu_item("articles/index.qmd", "Articles"),
    if (has_papers) menu_item("papers.qmd", "Papers"),
    if (has_talks) menu_item("talks.qmd", "Talks"),
    if (has_data) menu_item("reference/index.qmd#ref-data", "Data"),
    menu_item("citation.qmd", "Cite"),
    "      - href: reference/index.qmd", "        text: API",
    if (has_news) c("      - href: news.qmd", "        text: \"What's new\"")
  )
  c(
    "# Generated by dataimago::create_package_site(). Re-running with overwrite_config = FALSE keeps edits.",
    "project:",
    "  type: website",
    "  output-dir: _site",
    "  render:",
    "    - \"*.qmd\"",
    "    - \"overview/*.qmd\"",
    "    - \"documentation/*.qmd\"",
    "    - \"reference/*.qmd\"",
    "    - \"articles/**/*.qmd\"",
    "  resources:",
    "    - assets/fonts/**",
    "",
    "execute:",
    "  freeze: auto",
    "",
    "website:",
    paste0("  title: ", .yaml_quote(pkg)),
    paste0("  description: ", .yaml_quote(desc$Title %||% pkg)),
    if (!is.null(site_url)) paste0("  site-url: ", .yaml_quote(site_url)),
    if (!is.null(repo_url)) paste0("  repo-url: ", .yaml_quote(repo_url)),
    paste0("  favicon: ", logo$favicon),
    "  open-graph: true",
    "  page-navigation: false",
    "  search:",
    "    location: navbar",
    "    type: overlay",
    "  navbar:",
    paste0("    title: ", .yaml_quote(pkg)),
    paste0("    logo: ", logo$navbar),
    paste0("    logo-alt: ", .yaml_quote(paste(pkg, "hex logo"))),
    paste0("    pinned: ", if (isTRUE(navbar_pinned)) "true" else "false"),
    "    left:",
    left,
    if (!is.null(repo_url)) {
      c(
        "    right:",
        "      - icon: github",
        paste0("        href: ", repo_url),
        paste0("        aria-label: ", .yaml_quote(paste(pkg, "on GitHub")))
      )
    },
    "  page-footer:",
    paste0("    left: ", .yaml_quote(paste0("\u00a9 ", year, " ", owner, if (!is.null(org)) paste0(" \u00b7 ", org) else ""))),
    if (!is.null(org_url)) {
      c(
        "    right:",
        paste0("      - text: ", .yaml_quote(org)),
        paste0("        href: ", org_url),
        "      - text: \"Design system\"",
        "        href: https://dataimago.ai"
      )
    },
    "",
    "format:",
    "  pkgsite-html:",
    "    css:",
    paste0("      - ", font_css),
    "    toc: true",
    "    toc-depth: 3",
    "    page-layout: article",
    "    lang: en"
  )
}

.guard_script <- function(output_path = "ui/www") {
  c(
    "# Guards the package-site _quarto.yml against edits that break the Pages artifact flow.",
    paste0("# Run from the package root before `quarto render ", output_path, "`."),
    "args <- commandArgs(trailingOnly = TRUE)",
    paste0("path <- if (length(args)) args[1] else \"", output_path, "/_quarto.yml\""),
    "cfg <- yaml::read_yaml(path)",
    "problems <- character(0)",
    "if (!identical(cfg$project$`output-dir`, \"_site\")) problems <- c(problems, \"project.output-dir must be _site\")",
    "if (!any(grepl(\"^assets/fonts/\", unlist(cfg$project$resources)))) {",
    "  problems <- c(problems, \"project.resources must include assets/fonts/**\")",
    "}",
    "if (is.null(cfg$format$`pkgsite-html`)) problems <- c(problems, \"format must be pkgsite-html\")",
    "if (!is.null(cfg$website$navbar$title) && is.null(cfg$website$`site-url`)) problems <- c(problems, \"website.site-url is missing\")",
    "if (length(problems)) {",
    "  message(paste0(\"- \", problems, collapse = \"\\n\"))",
    "  quit(status = 1)",
    "}",
    "message(\"_quarto.yml ok\")"
  )
}

.publish_workflow <- function(branch, output_path = "ui/www") {
  op <- sub("/+$", "", output_path)
  c(
    "name: Publish site",
    "",
    "on:",
    "  push:",
    paste0("    branches: [", branch, "]"),
    "    paths:",
    paste0("      - \"", op, "/**\""),
    "      - \"man/**\"",
    "      - \"vignettes/**\"",
    "      - \"NEWS.md\"",
    "      - \"DESCRIPTION\"",
    "      - \".github/workflows/quarto-publish.yml\"",
    "  pull_request:",
    "    paths:",
    paste0("      - \"", op, "/**\""),
    "      - \"man/**\"",
    "      - \"vignettes/**\"",
    "      - \"NEWS.md\"",
    "      - \".github/workflows/quarto-publish.yml\"",
    "  workflow_dispatch:",
    "",
    "permissions:",
    "  contents: read",
    "",
    "concurrency:",
    "  group: pages",
    "  cancel-in-progress: false",
    "",
    "jobs:",
    "  build:",
    "    runs-on: ubuntu-latest",
    "    steps:",
    "      - uses: actions/checkout@v7",
    "      - uses: quarto-dev/quarto-actions/setup@v2",
    "        with:",
    "          version: 1.8.24",
    "      - uses: r-lib/actions/setup-r@v2",
    "        with:",
    "          use-public-rspm: true",
    "      - uses: r-lib/actions/setup-r-dependencies@v2",
    "        with:",
    "          extra-packages: any::yaml, any::knitr, any::rmarkdown, local::.",
    "          needs: website",
    "      - uses: actions/setup-node@v5",
    "        with:",
    "          node-version: 22",
    "          package-manager-cache: false",
    "      - name: Check design sync",
    paste0("        working-directory: ", op),
    "        run: |",
    "          V=$(node -p \"require('./.dataimago/design.json').version\") || { echo '::error::missing or unreadable .dataimago/design.json' >&2; exit 1; }",
    "          [ -n \"$V\" ] || { echo '::error::design.json has no version' >&2; exit 1; }",
    "          npx --yes -p \"@dataimago/css@${V}\" dataimago-sync --check",
    "      - name: Check _quarto.yml",
    paste0("        run: Rscript ", op, "/tools/check-quarto-yml.R"),
    "      - name: Render",
    paste0("        run: quarto render ", op),
    "      - name: Link check (internal)",
    "        uses: lycheeverse/lychee-action@v2",
    "        with:",
    paste0("          args: --offline --no-progress --root-dir ${{ github.workspace }}/", op, "/_site '", op, "/_site/**/*.html'"),
    "          fail: true",
    "      - uses: actions/upload-pages-artifact@v5",
    "        with:",
    paste0("          path: ", op, "/_site"),
    "",
    "  deploy:",
    paste0("    if: github.event_name != 'pull_request' && github.ref == 'refs/heads/", branch, "'"),
    "    needs: build",
    "    runs-on: ubuntu-latest",
    "    permissions:",
    "      pages: write",
    "      id-token: write",
    "    environment:",
    "      name: github-pages",
    "      url: ${{ steps.deployment.outputs.page_url }}",
    "    steps:",
    "      - id: deployment",
    "        uses: actions/deploy-pages@v5"
  )
}

# ---- landing data: _landing.yml (always regenerated) and index.qmd (author-owned) ----

# Number of documented, non-internal data sets (the same count the API card reports).
.count_data_topics <- function(package_path) {
  rd_files <- list.files(file.path(package_path, "man"), pattern = "\\.Rd$", full.names = TRUE)
  topics <- Filter(function(t) !t$internal && !t$is_package, lapply(rd_files, .rd_topic_meta))
  sum(vapply(topics, function(t) isTRUE(t$is_data), logical(1)))
}

# Card descriptions are factual lines built from the package, for the cards in `keys` only.
# Each has a fallback so a card never goes blank.
.card_descs <- function(package_path, desc, repo_url, keys = c("overview", "documentation", "api", "news", "source")) {
  pkg <- desc$Package
  out <- list()
  if ("overview" %in% keys) out$overview <- paste0("Why ", pkg, " exists and how it works")

  if ("api" %in% keys) {
    rd_files <- list.files(file.path(package_path, "man"), pattern = "\\.Rd$", full.names = TRUE)
    topics <- Filter(function(t) !t$internal && !t$is_package, lapply(rd_files, .rd_topic_meta))
    n_fun <- sum(vapply(topics, function(t) isTRUE(t$is_function) && !isTRUE(t$is_data), logical(1)))
    n_data <- .count_data_topics(package_path)
    out$api <- if (n_fun + n_data > 0L) {
      paste0(n_fun, if (n_fun == 1L) " function, " else " functions, ", n_data, if (n_data == 1L) " data set" else " data sets")
    } else {
      "Function and data reference"
    }
  }

  if ("documentation" %in% keys) {
    vigs <- list.files(file.path(package_path, "vignettes"), pattern = "\\.(Rmd|qmd)$", recursive = TRUE, full.names = TRUE)
    docs <- "Guides and articles"
    if (length(vigs)) {
      docs <- paste0(length(vigs), if (length(vigs) == 1L) " article" else " articles")
      main <- vigs[basename(vigs) %in% paste0(pkg, c(".Rmd", ".qmd"))][1]
      if (!is.na(main)) {
        fm <- .split_front_matter(readLines(main, warn = FALSE, encoding = "UTF-8"))$yaml
        ttl <- tryCatch(yaml::yaml.load(paste(fm, collapse = "\n"))$title, error = function(e) NULL)
        if (is.character(ttl) && length(ttl) == 1L && nzchar(ttl)) docs <- paste0(docs, "; start with ", ttl)
      }
    }
    out$documentation <- docs
  }

  if ("news" %in% keys) {
    news <- "Release notes"
    nf <- .news_file(package_path)
    if (!is.na(nf)) {
      h <- grep("^#+ ", readLines(nf, warn = FALSE, encoding = "UTF-8"), value = TRUE)
      h <- trimws(sub("^#+\\s*", "", h))
      h <- h[grepl("[0-9]+\\.[0-9]+", h)][1]
      if (!is.na(h) && nzchar(h)) news <- h
    }
    out$news <- news
  }

  if ("source" %in% keys) out$source <- sub("/+$", "", sub("^[a-z]+://", "", repo_url))
  out
}

.news_file <- function(package_path) {
  f <- file.path(package_path, c("NEWS.md", file.path("inst", "NEWS.md")))
  f[file.exists(f)][1]
}

# URLs in a DESCRIPTION URL field are separated by commas and/or whitespace.
.has_cran_url <- function(url) {
  if (is.null(url) || is.na(url)) return(FALSE)
  urls <- trimws(strsplit(url, "[,[:space:]]+")[[1]])
  any(grepl("^https?://(www\\.)?cran\\.r-project\\.org(/|$)", urls, ignore.case = TRUE))
}

# http(s) values are linked as they are, an email becomes mailto:, anything else is omitted.
.issues_href <- function(x) {
  if (is.null(x) || is.na(x)) return(NULL)
  x <- trimws(x)
  if (grepl("^https?://[^[:space:]]+$", x, ignore.case = TRUE)) return(x)
  if (grepl("^[^@[:space:]<>]+@[^@[:space:]<>]+\\.[^@[:space:]<>]+$", x)) return(paste0("mailto:", x))
  NULL
}

# `hero` is the seam for the hero inputs (ui/hero, Task B3): NULL gives the fallback.
# A card with no target is dropped rather than linked to a missing page.
.landing_data <- function(package_path, desc, hero = NULL, repo_url = NULL) {
  pkg <- desc$Package
  if (is.null(hero)) hero <- list(kind = "fallback", alt = paste0("Animated illustration for ", pkg))
  has_repo <- !is.null(repo_url) && !is.na(repo_url) && nzchar(trimws(repo_url))
  links <- list()
  if (has_repo) links[[length(links) + 1L]] <- list(text = "GitHub", href = repo_url)
  if (.has_cran_url(desc$URL)) {
    links[[length(links) + 1L]] <- list(text = "CRAN", href = paste0("https://cran.r-project.org/package=", pkg))
  }
  issues <- .issues_href(desc$BugReports)
  if (!is.null(issues)) links[[length(links) + 1L]] <- list(text = "Issues", href = issues)

  news_href <- if (!is.na(.news_file(package_path))) "news.qmd" else if (has_repo) paste0(sub("/+$", "", repo_url), "/releases") else NULL
  cards <- list(
    list(key = "overview", title = "Overview", href = "overview/index.qmd"),
    list(key = "documentation", title = "Documentation", href = "documentation/index.qmd"),
    list(key = "api", title = "API", href = "reference/index.qmd"),
    if (!is.null(news_href)) list(key = "news", title = "What's new", href = news_href),
    if (has_repo) list(key = "source", title = "Source", href = repo_url)
  )
  cards <- Filter(Negate(is.null), cards)
  d <- .card_descs(package_path, desc, repo_url, keys = vapply(cards, `[[`, "", "key"))
  cards <- lapply(cards, function(cd) c(cd, list(desc = d[[cd$key]])))
  list(pkgsite = list(
    name = pkg, title = desc$Title %||% "", version = desc$Version %||% "",
    hero = hero, links = links, cards = cards
  ))
}

.landing_yaml_lines <- function(data) {
  strsplit(sub("\n$", "", yaml::as.yaml(data, indent.mapping.sequence = TRUE)), "\n", fixed = TRUE)[[1]]
}

.write_landing_yml <- function(site_dir, data) {
  invisible(.write_lines(.landing_yaml_lines(data), file.path(site_dir, "_landing.yml")))
}

# README body for the overview div: badges, logos and the first H1 are dropped; a raw-HTML
# container the drop leaves empty is removed; a leading raw-HTML block is fenced as raw HTML
# so an unbalanced tag cannot swallow the closing `:::`.
.readme_overview_body <- function(package_path) {
  readme <- file.path(package_path, "README.md")
  body <- if (file.exists(readme)) readLines(readme, warn = FALSE, encoding = "UTF-8") else character(0)
  in_fence <- .in_code_fence(body)

  # badge-style lines only: image links, badge/logo images, and nothing else on the line
  badge_url <- "shields\\.io|badges?[./]|badge\\.svg|travis-ci|codecov|appveyor|gitter|repostatus|cranlogs|r-pkg\\.org|lifecycle|zenodo"
  logo_file <- "([^)\"'[:space:]]*/)?logo(@[0-9]+x|[-_][0-9]+(x[0-9]+)?)?\\.(png|svg|jpe?g|gif)(\\?[^)\"'[:space:]]*)?"
  tokens <- c(
    "\\[!\\[[^]]*\\]\\([^)]*\\)\\]\\([^)]*\\)",
    "<a\\b[^>]*>\\s*<img\\b[^>]*>\\s*</a>",
    paste0("!\\[[^]]*\\]\\([^)]*(", badge_url, ")[^)]*\\)"),
    paste0("<img\\b[^>]*(", badge_url, ")[^>]*>"),
    # a logo is matched by basename only, never by a substring of the path
    paste0("!\\[[^]]*\\]\\(", logo_file, "\\)"),
    paste0("<img\\b[^>]*src=[\"']", logo_file, "[\"'][^>]*>")
  )
  is_badge_line <- function(x) {
    rest <- x
    for (tk in tokens) rest <- gsub(tk, "", rest, ignore.case = TRUE)
    nzchar(trimws(x)) && !nzchar(trimws(rest)) && !identical(rest, x)
  }
  drop <- !in_fence & (vapply(body, is_badge_line, logical(1), USE.NAMES = FALSE) | grepl("<!--.*(badges|logo)", body))
  body <- body[!drop]
  in_fence <- in_fence[!drop]
  first_h1 <- which(!in_fence & grepl("^# ", body))[1]
  if (!is.na(first_h1)) {
    body <- body[-first_h1]
    in_fence <- in_fence[-first_h1]
  }

  # figures in man/figures travel to assets/figures
  body[!in_fence] <- gsub("(\\]\\(|src=[\"'])(\\./)?man/figures/", "\\1assets/figures/", body[!in_fence])

  if (length(body)) {
    txt <- paste(body, collapse = "\n")
    repeat {
      new <- gsub("<(p|div|center|a|span)\\b[^>]*>\\s*</\\1>", "", txt, ignore.case = TRUE)
      if (identical(new, txt)) break
      txt <- new
    }
    body <- strsplit(txt, "\n", fixed = TRUE)[[1]]
  }
  while (length(body) && !nzchar(trimws(body[1]))) body <- body[-1]
  if (length(body) && grepl("^\\s*<(p|div|center|table|details|section|picture|a|h[1-6]|img)(\\s|>)", body[1], ignore.case = TRUE)) {
    end <- which(!nzchar(trimws(body)))[1]
    end <- if (is.na(end)) length(body) else end - 1L
    body <- c("```{=html}", body[seq_len(end)], "```", body[-seq_len(end)])
  }
  # a fence in the README must not be able to run into the closing `:::`
  open_marker <- .fence_open_at_end(body)
  if (!is.null(open_marker)) body <- c(body, strrep(open_marker, 3L))
  body
}

# TRUE for each line inside (or opening/closing) a ``` or ~~~ fenced block.
.in_code_fence <- function(x) {
  out <- logical(length(x))
  marker <- NULL
  for (i in seq_along(x)) {
    m <- regmatches(x[i], regexpr("^\\s{0,3}(`{3,}|~{3,})", x[i]))
    f <- if (length(m)) substr(trimws(m), 1L, 1L) else NA_character_
    if (is.null(marker)) {
      if (!is.na(f)) {
        marker <- f
        out[i] <- TRUE
      }
    } else {
      out[i] <- TRUE
      if (!is.na(f) && identical(f, marker)) marker <- NULL
    }
  }
  out
}

.fence_open_at_end <- function(x) {
  marker <- NULL
  for (l in x) {
    m <- regmatches(l, regexpr("^\\s{0,3}(`{3,}|~{3,})", l))
    f <- if (length(m)) substr(trimws(m), 1L, 1L) else NA_character_
    if (is.null(marker)) {
      if (!is.na(f)) marker <- f
    } else if (!is.na(f) && identical(f, marker)) marker <- NULL
  }
  marker
}

.write_index_qmd <- function(site_dir, package_path, desc, overwrite = FALSE) {
  path <- file.path(site_dir, "index.qmd")
  if (file.exists(path) && !isTRUE(overwrite)) {
    return(invisible(path))
  }
  .write_lines(c(
    "---",
    paste0("pagetitle: ", .yaml_quote(desc$Package)),
    "page-layout: custom",
    "metadata-files: [_landing.yml]",
    "---",
    "",
    "::: {.di-landing}",
    "::: {.di-landing-overview}",
    .readme_overview_body(package_path),
    "",
    ":::",
    ":::",
    ""
  ), path)
}

# ---- navigation pages: papers, talks, documentation index, overview placeholder ----

.generated_marker <- "<!-- generated by dataimago::create_package_site() -->"

# HTML-significant characters first, then the markdown escapes: the text renders as text.
.md_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("([\\`*_]|\\[|\\])", "\\\\\\1", x)
}

.url_escape <- function(x) {
  x <- gsub("[[:space:]]", "%20", x)
  for (ch in c("(", ")", "<", ">", "\"", "\\")) x <- gsub(ch, sprintf("%%%02X", utf8ToInt(ch)), x, fixed = TRUE)
  x
}

.nav_abort <- function(rel, i, f, why) stop(rel, " entry ", i, ": field `", f, "` ", why, call. = FALSE)

.is_http_url <- function(x) grepl("^https?://[^[:space:]]+$", x)
.is_thumb <- function(x) {
  .is_http_url(x) ||
    grepl("^data:image/(png|jpeg|jpg|gif|webp)[;,]", x) ||
    (!grepl("^[A-Za-z][A-Za-z0-9+.-]*:", x) && !startsWith(x, "/") && !grepl("(^|[/\\\\])\\.\\.([/\\\\]|$)", x))
}

.parse_iso_date <- function(x) {
  if (!grepl("^[0-9]{4}-[0-9]{2}(-[0-9]{2})?$", x)) return(NA)
  full <- if (nchar(x) == 7L) paste0(x, "-01") else x
  d <- as.Date(full, format = "%Y-%m-%d")
  if (is.na(d) || format(d, "%Y-%m-%d") != full) NA else as.numeric(d)
}

# Reads ui/<file>; NULL when absent or empty. Aborts naming the file, entry and field.
.read_ui_list <- function(package_path, file, required) {
  path <- file.path(package_path, "ui", file)
  if (!file.exists(path)) return(NULL)
  rel <- file.path("ui", file)
  x <- tryCatch(yaml::yaml.load_file(path), error = function(e) {
    stop(rel, " could not be parsed: ", conditionMessage(e), call. = FALSE)
  })
  if (is.null(x) || length(x) == 0L) return(NULL)
  if (!is.list(x) || !is.null(names(x))) stop(rel, " must be a list of entries.", call. = FALSE)
  for (i in seq_along(x)) {
    e <- x[[i]]
    if (!is.list(e)) stop(rel, " entry ", i, " must be a mapping with ", paste(required, collapse = ", "), ".", call. = FALSE)
    for (f in required) {
      v <- e[[f]]
      if (is.null(v) || length(v) == 0L || (length(v) == 1L && (is.na(v[[1]]) || !nzchar(trimws(as.character(v[[1]])))))) {
        .nav_abort(rel, i, f, "is required.")
      }
    }
    for (f in c("title", "authors", "venue", "url", "doi", "abstract", "thumb")) {
      v <- unlist(e[[f]])
      if (!is.null(e[[f]]) && !is.character(v)) .nav_abort(rel, i, f, "must be text.")
    }
    if (!is.null(e$url) && !.is_http_url(e$url)) .nav_abort(rel, i, "url", "must start with http:// or https://.")
    if (!is.null(e$thumb) && !.is_thumb(e$thumb)) {
      .nav_abort(rel, i, "thumb", "must be an http(s) URL, a relative path without `..`, or a png/jpeg/gif/webp data: URI.")
    }
    if (!is.null(e$date) && (!is.character(e$date) || is.na(.parse_iso_date(e$date)))) {
      .nav_abort(rel, i, "date", "must be an ISO date, YYYY-MM-DD or YYYY-MM (quote it in the yml).")
    }
    if (!is.null(e$year)) {
      y <- e$year
      ok <- (is.numeric(y) && length(y) == 1L && !is.na(y) && y == round(y) && y >= 1000 && y <= 9999) ||
        (is.character(y) && length(y) == 1L && grepl("^[0-9]{4}$", y))
      if (!ok) .nav_abort(rel, i, "year", "must be a 4-digit year.")
    }
  }
  x
}

# Single-line fields: every whitespace run, newlines included, becomes one space.
.field <- function(e, f) {
  v <- e[[f]]
  if (is.null(v) || length(v) == 0L) return(NULL)
  v <- trimws(gsub("[[:space:]]+", " ", paste(unlist(v), collapse = ", ")))
  if (is.na(v) || !nzchar(v)) NULL else v
}

# Abstract: a blockquote; a line cannot open a heading, list, quote or Quarto div.
.abstract_block <- function(e) {
  v <- e$abstract
  if (is.null(v)) return(NULL)
  lines <- trimws(strsplit(paste(unlist(v), collapse = "\n"), "\r?\n")[[1]])
  if (!any(nzchar(lines))) return(NULL)
  lines <- .md_escape(lines)
  lines <- sub("^(#|-|\\+|:|=|~)", "\\\\\\1", lines)
  lines <- sub("^([0-9]+)([.)])", "\\1\\\\\\2", lines)
  c(ifelse(nzchar(lines), paste0("> ", lines), ">"), "")
}

.order_desc <- function(keys) order(-ifelse(is.na(keys), -Inf, keys), seq_along(keys))

# Deletes a stale generated page; refuses to overwrite an author's own.
.has_marker <- function(path) file.exists(path) && .generated_marker %in% readLines(path, warn = FALSE, encoding = "UTF-8")

.write_nav_page <- function(entries, site_dir, file, build) {
  path <- file.path(site_dir, file)
  if (is.null(entries)) {
    if (.has_marker(path)) unlink(path)
    return(invisible(NULL))
  }
  if (file.exists(path) && !.has_marker(path)) {
    stop(
      "The existing ", file, " is not generated, so your own ", file, " is kept. ",
      "Remove ui/", sub("\\.qmd$", ".yml", file), " or delete the page.", call. = FALSE
    )
  }
  invisible(.write_lines(build(entries), path))
}

.papers_page <- function(package_path, site_dir) {
  papers <- .read_ui_list(package_path, "papers.yml", c("title", "url"))
  .write_nav_page(papers, site_dir, "papers.qmd", function(papers) {
    yrs <- vapply(papers, function(p) if (is.null(p$year)) NA_real_ else as.numeric(p$year), 0)
    papers <- papers[.order_desc(yrs)]
    out <- c("---", "title: \"Papers\"", "page-layout: article", "toc: false", "---", "", .generated_marker, "")
    for (p in papers) {
      meta <- c(
        if (!is.null(.field(p, "authors"))) .md_escape(.field(p, "authors")),
        if (!is.null(.field(p, "year"))) paste0("(", .md_escape(.field(p, "year")), ")"),
        if (!is.null(.field(p, "venue"))) paste0("*", .md_escape(.field(p, "venue")), "*")
      )
      doi <- .field(p, "doi")
      out <- c(
        out, paste0("## [", .md_escape(.field(p, "title")), "](", .url_escape(.field(p, "url")), ")"), "",
        if (length(meta)) c(paste(meta, collapse = " "), ""),
        if (!is.null(doi)) c(paste0("[doi:", .md_escape(doi), "](https://doi.org/", .url_escape(doi), ")"), ""),
        .abstract_block(p)
      )
    }
    out
  })
}

.talks_page <- function(package_path, site_dir) {
  talks <- .read_ui_list(package_path, "talks.yml", c("title", "url", "date"))
  .write_nav_page(talks, site_dir, "talks.qmd", function(talks) {
    talks <- talks[.order_desc(vapply(talks, function(t) .parse_iso_date(t$date), 0))]
    out <- c("---", "title: \"Talks\"", "page-layout: article", "toc: false", "---", "", .generated_marker, "")
    for (t in talks) {
      ttl <- .md_escape(.field(t, "title"))
      meta <- c(.md_escape(.field(t, "date")), if (!is.null(.field(t, "venue"))) paste0("*", .md_escape(.field(t, "venue")), "*"))
      out <- c(
        out, paste0("## [", ttl, "](", .url_escape(.field(t, "url")), ")"), "",
        if (!is.null(.field(t, "thumb"))) c(paste0("![Thumbnail of the talk ", ttl, "](", .url_escape(.field(t, "thumb")), ")"), ""),
        paste(meta, collapse = " \u00b7 "), ""
      )
    }
    out
  })
}

# Always regenerated: lists only the sections that exist.
.documentation_index <- function(site_dir, pkg, has_main, has_articles, has_papers, has_talks, has_data) {
  item <- function(text, href, desc) c(paste0("[", text, "](", href, ")"), paste0(":   ", desc), "")
  out <- c("---", "title: \"Documentation\"", "page-layout: article", "toc: false", "---", "")
  out <- c(
    out, "::: {.reference-index}", "",
    if (has_main) item("Get started", paste0("../articles/", pkg, ".qmd"), paste0("A first tour of ", pkg)),
    if (has_articles) item("Articles", "../articles/index.qmd", "Guides and longer worked examples"),
    if (has_papers) item("Papers", "../papers.qmd", "Publications about the package and its methods"),
    if (has_talks) item("Talks", "../talks.qmd", "Presentations and recordings"),
    if (has_data) item("Data", "../reference/index.qmd#ref-data", "The data sets the package ships"),
    item("Cite", "../citation.qmd", paste0("How to cite ", pkg)),
    ":::", ""
  )
  invisible(.write_lines(out, file.path(site_dir, "documentation", "index.qmd")))
}

# Written only when missing: composed overview pages replace it later.
.overview_placeholder <- function(site_dir, pkg) {
  path <- file.path(site_dir, "overview", "index.qmd")
  if (file.exists(path)) return(invisible(path))
  invisible(.write_lines(c(
    "---", "title: \"Overview\"", "page-layout: article", "toc: false", "---", "",
    paste0(
      "The overview of ", pkg, " \u2014 why it exists, the ideas behind it and how it works \u2014 is being written."
    ), "",
    "In the meantime, see the [Documentation](../documentation/index.qmd) or the [API](../reference/index.qmd).", ""
  ), path))
}

# ---- hero slot: ui/hero/hero.svg | hero.js + poster | fallback ----

.hero_dir <- function(package_path) file.path(package_path, "ui", "hero")

# Remove /* ... */ comments and replace CSS strings (honouring escapes) with "",
# so neither can hide a declaration or fake a block opener.
.strip_css_noise <- function(x) {
  re <- "/\\*.*?\\*/|\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'"
  m <- gregexpr(re, x, perl = TRUE)
  tok <- regmatches(x, m)[[1]]
  if (length(tok)) regmatches(x, m) <- list(ifelse(startsWith(tok, "/*"), " ", "\"\""))
  x
}

.np_prelude <- function(prelude) {
  p <- tolower(trimws(gsub("\\s+", " ", prelude)))
  p <- gsub("\\s*:\\s*", ": ", p)
  grepl("^@media \\(prefers-reduced-motion: no-preference\\)( and \\([^()]*\\))*$", p)
}

# Scan CSS by brace depth. Returns the declarations as list(prop, value, in_np),
# where in_np is TRUE when an enclosing block is exactly a no-preference media query.
.css_declarations <- function(css) {
  chars <- strsplit(.strip_css_noise(css), "")[[1]]
  stack <- character(0)
  buf <- character(0)
  out <- list()
  flush_decl <- function() {
    seg <- trimws(paste(buf, collapse = ""))
    buf <<- character(0)
    r <- regmatches(seg, regexec("^([A-Za-z-]+)\\s*:(.*)$", seg))[[1]]
    if (length(r) == 3L) out[[length(out) + 1L]] <<- list(prop = tolower(r[2]), value = trimws(r[3]), in_np = any(stack == "np") && !any(stack == "media"))
  }
  for (ch in chars) {
    if (ch == "{") {
      prelude <- paste(buf, collapse = "")
      buf <- character(0)
      kind <- if (.np_prelude(prelude)) "np" else if (grepl("^\\s*@(media|supports|container|layer)", prelude, ignore.case = TRUE)) "media" else "other"
      stack <- c(stack, kind)
    } else if (ch == "}") {
      flush_decl()
      if (length(stack)) stack <- stack[-length(stack)]
    } else if (ch == ";") {
      flush_decl()
    } else {
      buf <- c(buf, ch)
    }
  }
  out
}

.css_ms <- function(value) {
  tok <- regmatches(value, gregexpr("(?<![A-Za-z0-9.])[0-9]*\\.?[0-9]+m?s(?![A-Za-z])", value, perl = TRUE))[[1]]
  vapply(tok, function(t) if (endsWith(t, "ms")) as.numeric(sub("ms$", "", t)) else 1000 * as.numeric(sub("s$", "", t)), 0)
}

.hero_fail <- function(f, problem, hint) {
  cli::cli_abort(c("{f}: {problem}", "i" = "{hint}"), call = NULL)
}

# Markup rules shared by hero.svg and poster.svg. The SVG is inlined into the
# page, so it is untrusted markup as well as a motion surface.
.check_svg_markup <- function(txt, f) {
  fail <- function(problem, hint) .hero_fail(f, problem, hint)
  tag <- function(names) paste0("<([A-Za-z_][A-Za-z0-9_.-]*:)?(", names, ")(?![A-Za-z0-9_:.-])")
  hit <- function(names) {
    r <- regmatches(txt, regexpr(tag(names), txt, perl = TRUE, ignore.case = TRUE))
    if (length(r)) r else NULL
  }
  txt <- gsub("(?s)<!--.*?-->", "", txt, perl = TRUE)
  if (grepl("<\\?xml", txt, ignore.case = TRUE)) {
    fail("contains an <?xml declaration.", "Remove it; the build stamps SVGs with an HTML comment on line 1.")
  }
  if (!is.null(h <- hit("script"))) {
    fail(cli::format_inline("contains a {.code {h}} element."), "Hero SVGs carry no scripts; use hero.js for scripted heroes.")
  }
  if (!is.null(h <- hit("animateTransform|animateMotion|animate|set"))) {
    fail(cli::format_inline("uses the SMIL element {.code {h}}."),
         "SMIL cannot be paused or lint-checked; animate with CSS inside @media (prefers-reduced-motion: no-preference).")
  }
  if (!is.null(h <- hit("foreignObject|iframe|object|embed"))) {
    fail(cli::format_inline("contains {.code {h}}, which embeds foreign content."), "Remove it; hero SVGs are plain vector markup.")
  }
  if (grepl("@import", txt, ignore.case = TRUE)) {
    fail("contains an @import.", "Hero SVGs may not load external stylesheets.")
  }
  root <- regmatches(txt, regexpr("<svg\\b[^>]*>", txt, perl = TRUE))
  if (!length(root) || !grepl("viewBox\\s*=", root)) {
    fail("the root <svg> has no viewBox.", "Add a viewBox so the hero scales.")
  }
  styles <- regmatches(txt, gregexpr("(?is)<style\\b[^>]*>.*?</style>", txt, perl = TRUE))[[1]]
  n_open <- lengths(regmatches(txt, gregexpr("<style\\b", txt, ignore.case = TRUE, perl = TRUE)))
  if (n_open != length(styles)) fail("has an unclosed <style> element.", "Close every <style> with </style>.")
  markup <- gsub("(?is)<style\\b[^>]*>.*?</style>", "", txt, perl = TRUE)
  ev <- regmatches(markup, regexpr("(?i)\\bon[a-z]+\\s*=", markup, perl = TRUE))
  if (length(ev)) {
    fail(cli::format_inline("has the event attribute {.code {trimws(ev)}}."), "Hero SVGs carry no event handlers.")
  }
  if (grepl("javascript:", gsub("[[:space:][:cntrl:]]", "", markup), ignore.case = TRUE)) {
    fail("contains a javascript: URL.", "Remove it.")
  }
  hrefs <- regmatches(markup, gregexpr("(?i)\\b(?:xlink:)?href\\s*=\\s*(\"[^\"]*\"|'[^']*'|[^\\s>]*)", markup, perl = TRUE))[[1]]
  for (h in hrefs) {
    val <- sub("^(?i)(?:xlink:)?href\\s*=\\s*", "", h, perl = TRUE)
    val <- trimws(gsub("^[\"']|[\"']$", "", val))
    if (!(startsWith(val, "#") || grepl("^data:image/(png|jpeg|jpg|gif|webp)[;,]", val, ignore.case = TRUE))) {
      shown <- substr(val, 1, 60)
      fail(cli::format_inline("has an href to {.url {shown}}."), "Only same-document fragments (#id) and raster data:image/ (png, jpeg, gif, webp) URIs are allowed.")
    }
  }
  styles
}

.check_hero_svg <- function(path, variant = c("hero", "poster")) {
  variant <- match.arg(variant)
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  f <- basename(path)
  fail <- function(problem, hint) .hero_fail(f, problem, hint)
  styles <- .check_svg_markup(txt, f)
  txt <- gsub("(?s)<!--.*?-->", "", txt, perl = TRUE)
  css <- paste(sub("(?is)</style>$", "", sub("(?is)^<style\\b[^>]*>", "", styles, perl = TRUE), perl = TRUE), collapse = "\n")
  markup <- gsub("(?is)<style\\b[^>]*>.*?</style>", "", txt, perl = TRUE)
  inline <- "(?i)style\\s*=\\s*(\"[^\"]*|'[^']*|)(?<![A-Za-z-])(-[a-z]+-)?(animation|transition)"
  if (variant == "poster") {
    if (grepl(inline, markup, perl = TRUE)) {
      fail("an inline style declares animation or transition.", "A poster is a still frame.")
    }
    d <- Filter(function(d) grepl("^(-[a-z]+-)?(animation|transition)", d$prop), .css_declarations(css))
    if (length(d)) {
      prop <- d[[1]]$prop
      fail(cli::format_inline("declares {.code {prop}}."), "A poster is a still frame: no animation or transition declarations at all.")
    }
    return(invisible(path))
  }
  if (grepl(inline, markup, perl = TRUE)) {
    fail("an inline style attribute declares animation or transition, which is outside the prefers-reduced-motion: no-preference media query.",
         "Move it into the <style> block, inside @media (prefers-reduced-motion: no-preference).")
  }

  decls <- .css_declarations(css)
  is_anim <- function(d) grepl("^(-[a-z]+-)?animation(-name)?$", d$prop)
  is_state <- function(d) grepl("^(-[a-z]+-)?animation-play-state$", d$prop)
  is_trans <- function(d) grepl("^(-[a-z]+-)?transition(-duration|-delay)?$", d$prop)
  state <- Filter(is_state, decls)
  if (length(state)) {
    prop <- state[[1]]$prop
    fail(cli::format_inline("declares {.code {prop}}."), "The page's pause control owns animation-play-state; heroes must not set it.")
  }
  anim <- Filter(is_anim, decls)
  outside <- Filter(function(d) !d$in_np, anim)
  np <- "@media (prefers-reduced-motion: no-preference)"
  if (length(outside)) {
    prop <- outside[[1]]$prop
    fail(cli::format_inline("declares {.code {prop}} outside {.code {np}}."),
         "All hero animation must live inside that media query so reduced-motion readers get a still frame.")
  }
  long <- Filter(function(d) !d$in_np && is_trans(d) && any(.css_ms(d$value) > 300), decls)
  if (length(long)) {
    prop <- long[[1]]$prop
    fail(cli::format_inline("declares {.code {prop}} longer than 300ms outside {.code {np}}."),
         "Keep transitions at 300ms or less, or move them inside the media query.")
  }

  if (length(anim)) {
    counts <- Filter(function(d) d$prop == "animation-iteration-count", decls)
    values <- vapply(counts, function(d) tolower(d$value), "")
    shorthand <- vapply(Filter(function(d) d$prop == "animation", anim), function(d) tolower(d$value), "")
    inf <- any(values == "infinite") || any(grepl("(^|\\s)infinite(\\s|$)", shorthand))
    declared <- length(counts) > 0L || any(grepl("(^|\\s)[0-9]+(\\.[0-9]+)?(\\s|$)", shorthand))
    if (inf) {
      cli::cli_warn("{.file {f}}: {.code animation-iteration-count: infinite}; heroes should run a finite number of cycles (3) and rest.")
    } else if (!declared) {
      cli::cli_warn("{.file {f}}: no {.code animation-iteration-count}; heroes should run a finite number of cycles (3) and rest.")
    }
  }
  invisible(path)
}

.hero_alt <- function(dir, pkg) {
  alt <- paste0("Animated illustration for ", pkg)
  yml <- file.path(dir, "hero.yml")
  if (file.exists(yml)) {
    got <- yaml::read_yaml(yml)$alt
    if (is.character(got) && length(got) == 1L && nzchar(trimws(got))) alt <- trimws(got)
  }
  alt
}

# Returns list(kind, src, poster, alt); src/poster are source paths under ui/hero
# (NULL when absent). Aborts on a rule-breaking SVG or a JS hero without a poster.
.find_hero <- function(package_path) {
  dir <- .hero_dir(package_path)
  pkg <- .read_desc(package_path)$Package
  alt <- .hero_alt(dir, pkg)
  poster <- file.path(dir, c("poster.svg", "poster.png"))
  poster <- poster[file.exists(poster)][1]
  if (is.na(poster)) poster <- NULL
  svg <- file.path(dir, "hero.svg")
  js <- file.path(dir, "hero.js")
  if (!is.null(poster) && endsWith(poster, ".svg") && (file.exists(svg) || file.exists(js))) {
    .check_hero_svg(poster, variant = "poster")
  }
  if (file.exists(svg)) {
    .check_hero_svg(svg)
    return(list(kind = "svg", src = svg, poster = poster, alt = alt))
  }
  if (file.exists(js)) {
    if (is.null(poster)) {
      cli::cli_abort(c(
        "{.file ui/hero/hero.js} needs a poster.",
        "i" = "Add {.file ui/hero/poster.svg} or {.file ui/hero/poster.png}; it is shown under reduced motion and while the module loads."
      ), call = NULL)
    }
    return(list(kind = "js", src = js, poster = poster, alt = alt))
  }
  list(kind = "fallback", alt = alt)
}

# Copy the hero into <site>/assets/hero and return the site-relative record
# that _landing.yml carries.
.install_hero <- function(hero, site_dir) {
  dest <- file.path(site_dir, "assets", "hero")
  unlink(dest, recursive = TRUE)
  if (identical(hero$kind, "fallback")) return(list(kind = "fallback", alt = hero$alt))
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  name <- paste0("hero.", tools::file_ext(hero$src))
  file.copy(hero$src, file.path(dest, name), overwrite = TRUE)
  rec <- list(kind = hero$kind, src = paste0("assets/hero/", name))
  if (!is.null(hero$poster)) {
    pname <- paste0("poster.", tools::file_ext(hero$poster))
    file.copy(hero$poster, file.path(dest, pname), overwrite = TRUE)
    rec$poster <- paste0("assets/hero/", pname)
  }
  rec$alt <- hero$alt
  rec
}

#' Scaffold a complete Quarto website for an R package
#'
#' Writes a site into `output_path` (default `ui/www`) from the package's DESCRIPTION,
#' `man/`, README, `NEWS.md` and vignettes: `_quarto.yml`, the `pkgsite` theme extension
#' (dataimago tokens, light and dark) and the self-hosted fonts, both synced from
#' `@dataimago/css` through `.dataimago/design.json`, `index.qmd`, per-topic reference pages,
#' articles, `news.qmd`, `citation.qmd`, a `_quarto.yml` guard script and a GitHub Pages workflow.
#'
#' Existing `_quarto.yml`, `index.qmd` and workflow files are kept unless
#' `overwrite_config = TRUE`. `_landing.yml`, reference, article, news and citation pages are always
#' regenerated, so edit their sources (`man/`, `vignettes/`, `NEWS.md`) rather than the
#' pages.
#'
#' @param package_path Path to the package root.
#' @param output_path Quarto project directory, relative to `package_path`.
#' @param site_url,repo_url Canonical site and repository URLs. When `NULL`, the first
#'   `https://<user>.github.io/...` and the first `https://github.com/<owner>/<repo>` URL in
#'   the DESCRIPTION `URL` field are used.
#' @param org,org_url Organisation credited in the footer.
#' @param navbar_pinned Keep the navbar fixed. `FALSE` (default) uses Quarto's
#'   hide-on-scroll-down, show-on-scroll-up behaviour.
#' @param logo Path (relative to `package_path`) to the hex logo SVG or PNG. When `NULL`,
#'   `man/figures/logo.svg` then `man/figures/logo.png` are used if present.
#' @param reference_config Passed to [create_package_reference()].
#' @param branch Default branch the Pages workflow deploys from.
#' @param workflow Write `.github/workflows/quarto-publish.yml`.
#' @param overwrite_config Replace existing `_quarto.yml`, `index.qmd` and workflow.
#' @param sync Run `dataimago-sync` (via `npx`, or from `DATAIMAGO_DESIGN_FROM`) to place the
#'   theme extension and fonts from `@dataimago/css`. `FALSE` writes `.dataimago/design.json`
#'   only, for offline use.
#' @return The site directory (invisibly).
#' @examples
#' \dontrun{
#' create_package_site(".",
#'   site_url = "https://centerforassessment.github.io/toOrdinal/",
#'   repo_url = "https://github.com/CenterForAssessment/toOrdinal",
#'   org = "Center for Assessment", org_url = "https://www.nciea.org"
#' )
#' }
#' @export
create_package_site <- function(package_path = ".", output_path = "ui/www", site_url = NULL,
                                repo_url = NULL, org = NULL, org_url = NULL,
                                navbar_pinned = FALSE, logo = NULL, reference_config = NULL,
                                branch = "main", workflow = TRUE, overwrite_config = FALSE,
                                sync = TRUE) {
  bad <- unique(strsplit(gsub("[A-Za-z0-9._/-]", "", output_path), "")[[1]])
  if (length(bad)) {
    cli::cli_abort(c(
      "{.arg output_path} may only contain letters, digits, {.code . _ / -}.",
      x = "Found: {.val {bad}}"
    ))
  }
  segs <- strsplit(sub("^\\./", "", output_path), "/", fixed = TRUE)[[1]]
  if (!nzchar(output_path) || startsWith(output_path, "/") || !length(segs) ||
    any(!nzchar(segs)) || any(segs %in% c(".", ".."))) {
    cli::cli_abort(c(
      "{.arg output_path} must be a relative sub-directory of the package.",
      x = "Got {.val {output_path}}: no leading {.code /}, {.code .}, {.code ..} or empty segments."
    ))
  }
  desc <- .read_desc(package_path)
  pkg <- desc$Package
  site_dir <- file.path(package_path, output_path)
  dir.create(site_dir, recursive = TRUE, showWarnings = FALSE)
  urls <- .desc_urls(desc)
  if (is.null(site_url)) site_url <- urls$site_url
  if (is.null(repo_url)) repo_url <- urls$repo_url
  seg <- strsplit(sub("^\\./", "", output_path), "/")[[1]][1]
  .ensure_rbuildignore(package_path, c(paste0("^", gsub("([.])", "\\\\\\1", seg), "$"), "^\\.github$"))

  # theme extension and fonts: pinned in design.json, synced from @dataimago/css
  .sync_pkgsite_theme(site_dir, sync = sync)
  font_css <- .pkgsite_font_css(.design_json_read(site_dir)$outputs)

  # logo
  logo_src <- logo
  if (is.null(logo_src)) {
    cand <- file.path("man", "figures", c("logo.svg", "logo.png"))
    logo_src <- cand[file.exists(file.path(package_path, cand))][1]
    if (is.na(logo_src)) logo_src <- NULL
  }
  if (!is.null(logo_src)) {
    dir.create(file.path(site_dir, "assets", "brand"), recursive = TRUE, showWarnings = FALSE)
    ext <- tools::file_ext(logo_src)
    dest <- file.path(site_dir, "assets", "brand", paste0("logo.", ext))
    file.copy(file.path(package_path, logo_src), dest, overwrite = TRUE)
    fav <- file.path(dirname(file.path(package_path, logo_src)), "favicon.png")
    fav_rel <- if (file.exists(fav)) {
      file.copy(fav, file.path(site_dir, "assets", "brand", "favicon.png"), overwrite = TRUE)
      "assets/brand/favicon.png"
    } else {
      paste0("assets/brand/logo.", ext)
    }
    logo_paths <- list(navbar = paste0("assets/brand/logo.", ext), hero = paste0("assets/brand/logo.", ext), favicon = fav_rel)
  } else {
    logo_paths <- list(navbar = "assets/brand/logo.svg", hero = "assets/brand/logo.svg", favicon = "assets/brand/logo.svg")
    warning("No hex logo found; the site references assets/brand/logo.svg.", call. = FALSE)
  }

  # content
  create_package_reference(package_path, site_dir, reference_config = reference_config)
  news <- create_package_news(package_path, site_dir)
  articles <- .copy_vignettes(package_path, site_dir)
  has_main <- file.exists(file.path(site_dir, "articles", paste0(pkg, ".qmd")))
  other_articles <- setdiff(basename(articles), paste0(pkg, ".qmd"))
  if (length(articles) > 0L) {
    .write_lines(c(
      "---", "title: \"Articles\"", "listing:", "  contents:", "    - \"*.qmd\"", "    - \"releases/*.qmd\"",
      "  exclude:", "    filename: index.qmd", "  type: table", "  sort: \"title desc\"",
      "  fields: [title, subtitle]", "page-layout: article", "toc: false", "---", ""
    ), file.path(site_dir, "articles", "index.qmd"))
  }
  .write_lines(.citation_page(package_path, desc), file.path(site_dir, "citation.qmd"))
  .write_lines(.guard_script(output_path), file.path(site_dir, "tools", "check-quarto-yml.R"))

  has_articles <- length(other_articles) > 0L || (length(articles) > 0L && !has_main)
  ref_index <- file.path(site_dir, "reference", "index.qmd")
  has_data <- .count_data_topics(package_path) > 0L && file.exists(ref_index) &&
    any(grepl("{#ref-data}", readLines(ref_index, warn = FALSE, encoding = "UTF-8"), fixed = TRUE))
  has_papers <- !is.null(.papers_page(package_path, site_dir))
  has_talks <- !is.null(.talks_page(package_path, site_dir))
  .documentation_index(site_dir, pkg, has_main, has_articles, has_papers, has_talks, has_data)
  .overview_placeholder(site_dir, pkg)

  yml_path <- file.path(site_dir, "_quarto.yml")
  if (!file.exists(yml_path) || isTRUE(overwrite_config)) {
    .write_lines(.pkg_quarto_yml(
      desc, site_url, repo_url, navbar_pinned, org, org_url,
      has_news = !is.null(news), has_articles = has_articles,
      has_vignette_main = has_main, logo = logo_paths, font_css = font_css,
      has_data = has_data, has_papers = has_papers, has_talks = has_talks
    ), yml_path)
  }
  hero <- .install_hero(.find_hero(package_path), site_dir)
  .write_landing_yml(site_dir, .landing_data(package_path, desc, hero = hero, repo_url = repo_url))
  .write_index_qmd(site_dir, package_path, desc, overwrite = overwrite_config)
  .write_lines(c("_site/", "/.quarto/", "_freeze/"), file.path(site_dir, ".gitignore"))
  if (isTRUE(workflow)) {
    wf <- file.path(package_path, ".github", "workflows", "quarto-publish.yml")
    if (!file.exists(wf) || isTRUE(overwrite_config)) .write_lines(.publish_workflow(branch, output_path), wf)
  }
  invisible(site_dir)
}

# First github.io and github.com repo URLs in a comma/whitespace separated URL string.
.split_urls <- function(text) {
  u <- strsplit(trimws(paste(text, collapse = " ")), "[,[:space:]]+")[[1]]
  u <- sub("[#?].*$", "", u[nzchar(u)])
  site <- u[grepl("^https://[^/]+\\.github\\.io(/|$)", u)][1]
  repo <- u[grepl("^https://github\\.com/[^/]+/[^/]+", u) &
    !grepl("^https://github\\.com/(orgs|sponsors|settings)/", u)][1]
  if (!is.na(repo)) repo <- sub("\\.git$", "", sub("/+$", "", sub("^(https://github\\.com/[^/]+/[^/]+).*$", "\\1", repo)))
  list(site_url = if (is.na(site)) NULL else site, repo_url = if (is.na(repo)) NULL else repo)
}

# First github.io and github.com repo URLs in DESCRIPTION `URL`.
.desc_urls <- function(desc) .split_urls(desc$URL %||% "")

# Appends the patterns not already present (exact, trimmed) to <pkg>/.Rbuildignore, keeping
# the file's line ending and trailing-newline state.
.ensure_rbuildignore <- function(package_path, patterns) {
  path <- file.path(package_path, ".Rbuildignore")
  txt <- if (file.exists(path)) rawToChar(readBin(path, "raw", file.size(path))) else ""
  have <- trimws(strsplit(txt, "\r?\n")[[1]])
  add <- setdiff(patterns, have)
  if (!length(add)) return(invisible(path))
  eol <- if (grepl("\r\n", txt, fixed = TRUE)) "\r\n" else "\n"
  if (nzchar(txt) && !grepl("\n$", txt)) {
    out <- paste0(txt, eol, paste(add, collapse = eol))
  } else {
    out <- paste0(txt, paste0(add, eol, collapse = ""))
  }
  writeBin(charToRaw(out), path)
  invisible(path)
}

# ---- theme and fonts: pinned in design.json, synced from @dataimago/css ----

.pkgsite_design_template <- function() {
  path <- system.file("pkgsite", "design.json", package = "dataimago")
  if (!nzchar(path)) path <- file.path("inst", "pkgsite", "design.json") # load_all() fallback
  path
}

# Writes `<site_dir>/.dataimago/design.json`. An existing file is merged: missing `outputs`
# keys are added; existing keys, their values and the pinned `version` are never changed.
# The merge is a text-level insertion, so an author's nulls, empty objects, layout, line
# endings and trailing newline survive; a file that already has every key is not written.
.write_design_json <- function(site_dir, template = .pkgsite_design_template()) {
  path <- file.path(site_dir, ".dataimago", "design.json")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(path)) {
    file.copy(template, path)
    return(invisible(path))
  }
  want <- jsonlite::read_json(template)
  have <- jsonlite::read_json(path)
  orig <- rawToChar(readBin(path, "raw", file.size(path)))
  Encoding(orig) <- "UTF-8"
  txt <- orig
  if (!identical(.json_scan(txt)$outputs_kind %in% c("object", "absent"), TRUE)) {
    cli::cli_abort("{.file {path}}: design.json {.field outputs} must be an object.")
  }
  eol <- if (grepl("\r\n", txt, fixed = TRUE)) "\r\n" else "\n"
  indent <- .json_indent(txt)
  entry <- function(k, v, ind) {
    paste0(ind, jsonlite::toJSON(k, auto_unbox = TRUE), ": ", jsonlite::toJSON(v, auto_unbox = TRUE))
  }
  missing_out <- setdiff(names(want$outputs), names(have$outputs))
  if (length(missing_out)) {
    loc <- .json_scan(txt)
    if (identical(loc$outputs_kind, "object")) {
      ind <- .json_outputs_indent(txt, loc, indent)
      ents <- vapply(missing_out, function(k) entry(k, want$outputs[[k]], ind$entry), "")
      txt <- .json_insert(txt, loc$outputs_end, ents, eol, ind$close)
    } else {
      ents <- vapply(missing_out, function(k) entry(k, want$outputs[[k]], paste0(indent, indent)), "")
      member <- paste0(indent, '"outputs": {', eol, paste(ents, collapse = paste0(",", eol)), eol, indent, "}")
      txt <- .json_insert(txt, loc$end, member, eol, "")
    }
  }
  for (k in c("version", "package")) {
    if (is.null(have[[k]])) txt <- .json_insert(txt, .json_scan(txt)$end, entry(k, want[[k]], indent), eol, "")
  }
  if (!identical(txt, orig)) writeBin(charToRaw(enc2utf8(txt)), path)
  invisible(path)
}

# Scans a JSON document: character index of the `}` closing the top-level object (`end`), and,
# for the top-level key "outputs", whether it is "absent", an "object" (with `outputs_end`, the
# index of its closing `}`) or some "other" value (null, array, string...).
.json_scan <- function(txt, key = "outputs") {
  ch <- strsplit(txt, "")[[1]]
  depth <- 0L
  in_str <- FALSE
  skip <- FALSE
  sstart <- 0L
  last_str <- ""
  expecting <- FALSE
  res <- list(end = NA_integer_, outputs_kind = "absent", outputs_start = NA_integer_, outputs_end = NA_integer_)
  for (i in seq_along(ch)) {
    c <- ch[i]
    if (in_str) {
      if (skip) {
        skip <- FALSE # the character after a backslash is escaped, whatever it is
      } else if (c == "\\") {
        skip <- TRUE
      } else if (c == "\"") {
        in_str <- FALSE
        last_str <- if (i - 1L >= sstart + 1L) paste(ch[(sstart + 1L):(i - 1L)], collapse = "") else ""
      }
      next
    }
    if (expecting && !grepl("\\s", c)) {
      expecting <- FALSE
      res$outputs_kind <- if (c == "{") "object" else "other"
      res$outputs_start <- i
    }
    if (c == "\"") {
      in_str <- TRUE
      sstart <- i
    } else if (c == ":" && depth == 1L) {
      expecting <- identical(last_str, key) && res$outputs_kind == "absent"
    } else if (c %in% c("{", "[")) {
      depth <- depth + 1L
    } else if (c %in% c("}", "]")) {
      if (depth == 1L) {
        res$end <- i
        break
      }
      if (res$outputs_kind == "object" && is.na(res$outputs_end) && depth == 2L && i > res$outputs_start) res$outputs_end <- i
      depth <- depth - 1L
    }
  }
  if (is.na(res$end)) cli::cli_abort("design.json is not a JSON object.")
  res
}

# The file's own indent unit: the leading whitespace of its first indented key line.
.json_indent <- function(txt) {
  m <- regmatches(txt, regexpr("(?<=\n)[ \t]+(?=\")", txt, perl = TRUE))
  if (length(m)) m else "  "
}

# Indent of existing `outputs` entries (else top-level indent doubled) and of its closing brace.
.json_outputs_indent <- function(txt, loc, indent) {
  ch <- strsplit(txt, "")[[1]]
  inner <- paste(ch[seq(loc$outputs_start + 1L, loc$outputs_end - 1L)], collapse = "")
  m <- regmatches(inner, regexpr("(?<=\n)[ \t]+(?=\")", inner, perl = TRUE))
  list(entry = if (length(m)) m else paste0(indent, indent), close = indent)
}

# Inserts `entries` as the last members of the object closing at character `end`, keeping the
# whitespace that precedes the closing brace (or adding a line break and `close_indent`).
.json_insert <- function(txt, end, entries, eol, close_indent) {
  ch <- strsplit(txt, "")[[1]]
  before <- paste(ch[seq_len(end - 1L)], collapse = "")
  after <- paste(ch[end:length(ch)], collapse = "")
  trimmed <- sub("\\s+$", "", before)
  ws <- substring(before, nchar(trimmed) + 1L)
  if (!grepl("\n", ws, fixed = TRUE)) ws <- paste0(eol, close_indent)
  sep <- if (grepl("[{]$", trimmed)) eol else paste0(",", eol)
  paste0(trimmed, sep, paste(entries, collapse = paste0(",", eol)), ws, after)
}

.design_json_read_template <- function() jsonlite::read_json(.pkgsite_design_template())

.design_json_read <- function(site_dir) {
  jsonlite::read_json(file.path(site_dir, ".dataimago", "design.json"))
}

# The font stylesheets, in mapping order, from the mapped destinations: `<dest>fonts.css` for
# each `fonts/<set>/` directory, and `<dest>lang.css` for `fonts/lang.css`.
.pkgsite_font_css <- function(outputs) {
  src <- names(outputs)
  dest <- unlist(outputs, use.names = FALSE)
  out <- character(0)
  for (i in seq_along(src)) {
    if (grepl("^fonts/.+/$", src[i])) out <- c(out, paste0(dest[i], "fonts.css"))
    if (grepl("^fonts/lang\\.css$", src[i])) out <- c(out, paste0(sub("/?$", "/", dest[i]), "lang.css"))
  }
  # directories first (mapping order), lang.css last
  c(out[!grepl("lang\\.css$", out)], out[grepl("lang\\.css$", out)])
}

.tool_path <- function(name) unname(Sys.which(name))

.run_tool <- function(command, args, wd) {
  processx::run(command, args, wd = wd, echo = TRUE, error_on_status = FALSE)$status
}

# Runs dataimago-sync in `site_dir`: from the pinned npm package, or from a local
# dataimago-design build when `from` is set (DATAIMAGO_DESIGN_FROM).
.run_dataimago_sync <- function(site_dir, version, from = Sys.getenv("DATAIMAGO_DESIGN_FROM")) {
  if (nzchar(from)) {
    from <- normalizePath(from, mustWork = TRUE) # the process runs in site_dir
    command <- "node"
    args <- c(file.path(from, "packages", "css", "dist", "bin", "dataimago-sync.mjs"), "--from", from)
  } else {
    command <- "npx"
    args <- c("--yes", "-p", paste0("@dataimago/css@", version), "dataimago-sync")
  }
  shown <- paste(c(command, args), collapse = " ")
  if (!nzchar(.tool_path(command))) {
    cli::cli_abort(c(
      "{.code {command}} was not found on the PATH, so the theme and fonts cannot be synced.",
      "i" = "Install Node.js, then run this in {.path {site_dir}}:",
      " " = "{.code {shown}}"
    ))
  }
  status <- .run_tool(command, args, wd = site_dir)
  if (!identical(as.integer(status), 0L)) {
    cli::cli_abort(c("{.code {shown}} exited with status {status}.", "i" = "Run it in {.path {site_dir}} to see why."))
  }
  invisible(status)
}

# design.json + sync, for callers that need the theme and fonts on disk.
.sync_pkgsite_theme <- function(site_dir, sync = TRUE) {
  .write_design_json(site_dir)
  if (isTRUE(sync)) .run_dataimago_sync(site_dir, .design_json_read(site_dir)$version)
  invisible(site_dir)
}
