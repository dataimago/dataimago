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
  for (s in sections) {
    index <- c(index, paste0("## ", s$title), "")
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
  qmd <- c("---", "title: \"News\"", "toc: true", "toc-depth: 2", "---", "", lines, "")
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
                            has_articles, has_vignette_main, logo, font_css) {
  pkg <- desc$Package
  year <- format(Sys.Date(), "%Y")
  people <- .authors(desc)
  owner <- if (!is.null(people)) format(people[1], include = c("given", "family")) else pkg
  left <- c(
    "      - href: index.qmd", "        text: Home",
    if (has_vignette_main) c(paste0("      - href: articles/", pkg, ".qmd"), "        text: Get started"),
    "      - href: reference/index.qmd", "        text: Reference",
    if (has_articles) c("      - href: articles/index.qmd", "        text: Articles"),
    if (has_news) c("      - href: news.qmd", "        text: News"),
    "      - href: citation.qmd", "        text: Citation"
  )
  c(
    "# Generated by dataimago::create_package_site(). Re-running with overwrite_config = FALSE keeps edits.",
    "project:",
    "  type: website",
    "  output-dir: _site",
    "  render:",
    "    - \"*.qmd\"",
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

.guard_script <- function() {
  c(
    "# Guards the package-site _quarto.yml against edits that break the Pages artifact flow.",
    "# Run from the package root before `quarto render ui/www`.",
    "args <- commandArgs(trailingOnly = TRUE)",
    "path <- if (length(args)) args[1] else \"ui/www/_quarto.yml\"",
    "cfg <- yaml::read_yaml(path)",
    "problems <- character(0)",
    "if (!identical(cfg$project$`output-dir`, \"_site\")) problems <- c(problems, \"project.output-dir must be _site\")",
    "if (!any(grepl(\"fonts\", unlist(cfg$project$resources)))) {",
    "  problems <- c(problems, \"project.resources must include assets/fonts/*.woff2\")",
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

.publish_workflow <- function(branch, pkg) {
  c(
    "name: Publish site",
    "",
    "on:",
    "  push:",
    paste0("    branches: [", branch, "]"),
    "    paths:",
    "      - \"ui/www/**\"",
    "      - \"man/**\"",
    "      - \"vignettes/**\"",
    "      - \"NEWS.md\"",
    "      - \"DESCRIPTION\"",
    "      - \".github/workflows/quarto-publish.yml\"",
    "  pull_request:",
    "    paths:",
    "      - \"ui/www/**\"",
    "      - \"man/**\"",
    "      - \"vignettes/**\"",
    "      - \"NEWS.md\"",
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
    "      - uses: r-lib/actions/setup-r@v2",
    "        with:",
    "          use-public-rspm: true",
    "      - uses: r-lib/actions/setup-r-dependencies@v2",
    "        with:",
    "          extra-packages: any::yaml, any::knitr, any::rmarkdown, local::.",
    "          needs: website",
    "      - name: Check _quarto.yml",
    "        run: Rscript ui/www/tools/check-quarto-yml.R",
    "      - name: Render",
    "        run: quarto render ui/www",
    "      - name: Link check (internal)",
    "        uses: lycheeverse/lychee-action@v2",
    "        with:",
    "          args: --offline --no-progress --root-dir ${{ github.workspace }}/ui/www/_site 'ui/www/_site/**/*.html'",
    "          fail: true",
    "      - uses: actions/upload-pages-artifact@v5",
    "        with:",
    "          path: ui/www/_site",
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

.readme_to_index <- function(package_path, desc, logo, site_url, repo_url, has_vignette_main) {
  pkg <- desc$Package
  readme <- file.path(package_path, "README.md")
  body <- if (file.exists(readme)) readLines(readme, warn = FALSE, encoding = "UTF-8") else character(0)
  drop <- grepl("^\\s*\\[!\\[|^\\s*<img|^\\s*<a [^>]*>\\s*<img|<!--.*(badges|logo)|AppVeyor|Gitter|gitter", body)
  body <- body[!drop]
  first_h1 <- which(grepl("^# ", body))[1]
  if (!is.na(first_h1)) body <- body[-first_h1]
  while (length(body) && !nzchar(trimws(body[1]))) body <- body[-1]

  actions <- c(
    if (!is.null(repo_url)) paste0("  <li><a href=\"", repo_url, "\">GitHub</a></li>"),
    paste0("  <li><a href=\"https://CRAN.R-project.org/package=", pkg, "\">CRAN</a></li>"),
    if (has_vignette_main) paste0("  <li><a href=\"articles/", pkg, ".html\">Get started</a></li>"),
    "  <li><a href=\"reference/index.html\">Reference</a></li>"
  )
  c(
    "---",
    paste0("pagetitle: ", .yaml_quote(paste0(pkg, ": ", desc$Title %||% ""))),
    "page-layout: article",
    "toc: false",
    "---",
    "",
    "```{=html}",
    "<section class=\"pkg-hero\" aria-labelledby=\"pkg-name\">",
    paste0("  <img class=\"pkg-hex\" src=\"", logo$hero, "\" alt=\"", pkg, " hex logo\">"),
    "  <div>",
    paste0("    <p id=\"pkg-name\" class=\"pkg-name\" role=\"heading\" aria-level=\"1\">", pkg, "</p>"),
    paste0("    <p class=\"pkg-tagline\">", desc$Title %||% "", "</p>"),
    "    <ul class=\"pill-links\">",
    actions,
    "    </ul>",
    "  </div>",
    "</section>",
    "```",
    "",
    body,
    ""
  )
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
#' `overwrite_config = TRUE`. Reference, article, news and citation pages are always
#' regenerated, so edit their sources (`man/`, `vignettes/`, `NEWS.md`) rather than the
#' pages.
#'
#' @param package_path Path to the package root.
#' @param output_path Quarto project directory, relative to `package_path`.
#' @param site_url,repo_url Canonical site and repository URLs.
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
  desc <- .read_desc(package_path)
  pkg <- desc$Package
  site_dir <- file.path(package_path, output_path)
  dir.create(site_dir, recursive = TRUE, showWarnings = FALSE)

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
  .write_lines(.guard_script(), file.path(site_dir, "tools", "check-quarto-yml.R"))

  yml_path <- file.path(site_dir, "_quarto.yml")
  if (!file.exists(yml_path) || isTRUE(overwrite_config)) {
    .write_lines(.pkg_quarto_yml(
      desc, site_url, repo_url, navbar_pinned, org, org_url,
      has_news = !is.null(news), has_articles = length(other_articles) > 0L || (length(articles) > 0L && !has_main),
      has_vignette_main = has_main, logo = logo_paths, font_css = font_css
    ), yml_path)
  }
  index_path <- file.path(site_dir, "index.qmd")
  if (!file.exists(index_path) || isTRUE(overwrite_config)) {
    .write_lines(.readme_to_index(package_path, desc, logo_paths, site_url, repo_url, has_main), index_path)
  }
  .write_lines(c("_site/", "/.quarto/", "_freeze/"), file.path(site_dir, ".gitignore"))
  if (isTRUE(workflow)) {
    wf <- file.path(package_path, ".github", "workflows", "quarto-publish.yml")
    if (!file.exists(wf) || isTRUE(overwrite_config)) .write_lines(.publish_workflow(branch, pkg), wf)
  }
  invisible(site_dir)
}

# ---- theme and fonts: pinned in design.json, synced from @dataimago/css ----

.pkgsite_design_template <- function() {
  path <- system.file("pkgsite", "design.json", package = "dataimago")
  if (!nzchar(path)) path <- file.path("inst", "pkgsite", "design.json") # load_all() fallback
  path
}

# Writes `<site_dir>/.dataimago/design.json`. An existing file is merged: missing `outputs`
# keys are added; existing keys, their values and the pinned `version` are never changed.
.write_design_json <- function(site_dir, template = .pkgsite_design_template()) {
  want <- jsonlite::read_json(template)
  path <- file.path(site_dir, ".dataimago", "design.json")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  out <- if (file.exists(path)) jsonlite::read_json(path) else want
  if (is.null(out$package)) out$package <- want$package
  if (is.null(out$version)) out$version <- want$version
  if (is.null(out$outputs)) out$outputs <- list()
  for (k in setdiff(names(want$outputs), names(out$outputs))) out$outputs[[k]] <- want$outputs[[k]]
  jsonlite::write_json(out, path, auto_unbox = TRUE, pretty = TRUE)
  invisible(path)
}

.design_json_read_template <- function() jsonlite::read_json(.pkgsite_design_template())

.design_json_read <- function(site_dir) {
  jsonlite::read_json(file.path(site_dir, ".dataimago", "design.json"))
}

# The font stylesheets, in order, derived from the design.json outputs mapping.
.pkgsite_font_css <- function(outputs) {
  dest <- unlist(outputs, use.names = FALSE)
  src <- names(outputs)
  dirs <- dest[grepl("^assets/fonts/.+/$", dest)]
  lang <- dest[grepl("lang\\.css$", src)]
  c(
    if (length(dirs)) paste0(dirs, "fonts.css"),
    if (length(lang)) paste0(sub("/?$", "/", lang), "lang.css")
  )
}

.tool_path <- function(name) unname(Sys.which(name))

.run_tool <- function(command, args, wd) {
  processx::run(command, args, wd = wd, echo = TRUE, error_on_status = FALSE)$status
}

# Runs dataimago-sync in `site_dir`: from the pinned npm package, or from a local
# dataimago-design build when `from` is set (DATAIMAGO_DESIGN_FROM).
.run_dataimago_sync <- function(site_dir, version, from = Sys.getenv("DATAIMAGO_DESIGN_FROM")) {
  if (nzchar(from)) {
    command <- "node"
    args <- c(file.path(from, "packages", "css", "dist", "bin", "dataimago-sync.mjs"), "--from", from)
  } else {
    command <- "npx"
    args <- c("-p", paste0("@dataimago/css@", version), "dataimago-sync")
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
