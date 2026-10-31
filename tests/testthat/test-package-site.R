make_site_fixture <- function(dir = withr::local_tempdir(.local_envir = parent.frame())) {
  pkg <- file.path(dir, "sitepkg")
  dir.create(file.path(pkg, "man"), recursive = TRUE)
  dir.create(file.path(pkg, "vignettes", "releases"), recursive = TRUE)
  dir.create(file.path(pkg, "man", "figures"), recursive = TRUE)
  writeLines(c(
    "Package: sitepkg", "Version: 1.2-3.0", "Date: 2026-10-01",
    "Title: A Fixture for Site Tests",
    "Description: Synthetic package used by the test suite.",
    "Authors@R: person(\"Ada\", \"Lovelace\", email = \"ada@example.org\", role = c(\"aut\", \"cre\"))",
    "License: MIT + file LICENSE", "Encoding: UTF-8"
  ), file.path(pkg, "DESCRIPTION"))
  writeLines(c(
    "\\name{shout}", "\\alias{shout}", "\\title{Shout a word}",
    "\\usage{shout(x, times = 1L)}",
    "\\arguments{",
    "  \\item{x}{A character vector.}",
    "  \\item{times}{How often, see \\code{\\link{whisper}} and \\code{\\link[stats]{sd}}.}",
    "}",
    "\\value{A character vector.}",
    "\\examples{shout(\"a\")}"
  ), file.path(pkg, "man", "shout.Rd"))
  writeLines(c(
    "\\name{whisper}", "\\alias{whisper}", "\\alias{murmur}", "\\title{Whisper a word}",
    "\\usage{whisper(x)}", "\\arguments{\\item{x}{A word.}}", "\\value{A word.}"
  ), file.path(pkg, "man", "whisper.Rd"))
  writeLines(c(
    "\\name{words}", "\\docType{data}", "\\alias{words}", "\\title{Example words}",
    "\\format{A character vector.}", "\\description{Words.}", "\\keyword{datasets}"
  ), file.path(pkg, "man", "words.Rd"))
  writeLines(c(
    "\\name{hidden}", "\\alias{hidden}", "\\title{Internal helper}",
    "\\usage{hidden()}", "\\description{Internal.}", "\\keyword{internal}"
  ), file.path(pkg, "man", "hidden.Rd"))
  writeLines(c(
    "\\name{sitepkg-package}", "\\docType{package}", "\\alias{sitepkg-package}",
    "\\title{sitepkg: A fixture}", "\\description{The fixture.}"
  ), file.path(pkg, "man", "sitepkg-package.Rd"))
  news <- c("# sitepkg 1.2-3.0", "", "## New", "", "* Louder.", "", "# sitepkg 1.0-0.0", "", "* First.")
  writeLines(news, file.path(pkg, "NEWS.md"))
  vig <- c(
    "---", "title: \"Getting started\"", "output: rmarkdown::html_vignette",
    "vignette: >", "  %\\VignetteIndexEntry{Getting started}", "---", "", "Hello.", ""
  )
  writeLines(vig, file.path(pkg, "vignettes", "sitepkg.Rmd"))
  writeLines(c("---", "title: \"Release 1.2\"", "---", "", "Notes."), file.path(pkg, "vignettes", "releases", "r12.Rmd"))
  svg <- "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 10 10\"><path d=\"M0 0h10v10z\"/></svg>"
  writeLines(svg, file.path(pkg, "man", "figures", "logo.svg"))
  readme <- c(
    "# sitepkg", "", "[![CRAN](x.svg)](y)", "", "Shout and whisper words.", "",
    "## Install", "", "`install.packages(\"sitepkg\")`"
  )
  writeLines(readme, file.path(pkg, "README.md"))
  pkg
}

skip_without_pandoc <- function() {
  testthat::skip_if_not(nzchar(Sys.which("pandoc")) || nzchar(Sys.which("quarto")), "pandoc not available")
}

test_that("create_package_reference writes one page per topic and an index", {
  skip_without_pandoc()
  pkg <- make_site_fixture()
  out <- file.path(dirname(pkg), "www")
  files <- create_package_reference(pkg, out)

  expect_true(all(file.exists(file.path(out, "reference", c("shout.qmd", "whisper.qmd", "words.qmd", "hidden.qmd", "index.qmd")))))
  expect_length(files, 6L)

  page <- readLines(file.path(out, "reference", "shout.qmd"))
  expect_match(page[2], "shout()", fixed = TRUE)
  expect_true(any(grepl("whisper.html", page, fixed = TRUE)))
  expect_true(any(grepl("https://rdrr.io/r/stats/sd.html", page, fixed = TRUE)))
  expect_false(any(grepl("\\\\item|<table|<h2>", page)))
  expect_true(any(grepl("^## ", page)))
  expect_false(any(grepl("^## NA$", page)))
  expect_true("## Usage" %in% page)
  # the data topic carries no stray docType text
  words <- readLines(file.path(out, "reference", "words.qmd"))
  expect_false("data" %in% words)

  index <- paste(readLines(file.path(out, "reference", "index.qmd")), collapse = "\n")
  expect_match(index, "[`shout()`](shout.html)", fixed = TRUE)
  expect_match(index, "## Data sets", fixed = TRUE)
  expect_match(index, "## Package", fixed = TRUE)
  expect_false(grepl("hidden", index))
})

test_that("alias links resolve to the owning topic page", {
  skip_without_pandoc()
  pkg <- make_site_fixture()
  writeLines(c(
    "\\name{shout}", "\\alias{shout}", "\\title{Shout}", "\\usage{shout(x)}",
    "\\description{See \\code{\\link{murmur}}.}"
  ), file.path(pkg, "man", "shout.Rd"))
  out <- file.path(dirname(pkg), "www")
  create_package_reference(pkg, out)
  page <- readLines(file.path(out, "reference", "shout.qmd"))
  expect_true(any(grepl("whisper.html", page, fixed = TRUE)))
})

test_that("reference_config orders sections and collects unlisted topics under Other", {
  skip_without_pandoc()
  pkg <- make_site_fixture()
  out <- file.path(dirname(pkg), "www")
  cfg <- list(list(title = "Loud", desc = "Raise your voice.", contents = "shout"))
  create_package_reference(pkg, out, reference_config = cfg)
  index <- readLines(file.path(out, "reference", "index.qmd"))
  expect_equal(index[grep("^## ", index)], c("## Loud", "## Other"))
  expect_true("Raise your voice." %in% index)
})

test_that("create_package_news demotes headings and keeps the page title", {
  pkg <- make_site_fixture()
  out <- file.path(dirname(pkg), "www")
  path <- create_package_news(pkg, out)
  news <- readLines(path)
  expect_true("title: \"News\"" %in% news)
  expect_true("## sitepkg 1.2-3.0" %in% news)
  expect_true("### New" %in% news)
  expect_null(create_package_news(file.path(dirname(pkg)), out))
})

test_that("create_package_site scaffolds config, theme, fonts, articles and workflow", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  site <- create_package_site(pkg,
    site_url = "https://example.org/sitepkg/", repo_url = "https://github.com/example/sitepkg",
    org = "Example Org", org_url = "https://example.org", branch = "master"
  )
  cfg <- yaml::read_yaml(file.path(site, "_quarto.yml"))
  expect_equal(cfg$project$`output-dir`, "_site")
  expect_false(cfg$website$navbar$pinned)
  expect_equal(cfg$website$navbar$logo, "assets/brand/logo.svg")
  expect_true("pkgsite-html" %in% names(cfg$format))
  hrefs <- vapply(cfg$website$navbar$left, function(x) x$href, character(1))
  expect_true(all(c("index.qmd", "articles/sitepkg.qmd", "reference/index.qmd", "news.qmd", "citation.qmd") %in% hrefs))

  expect_true(file.exists(file.path(site, "_extensions", "dataimago", "pkgsite", "_extension.yml")))
  expect_true(file.exists(file.path(site, "assets", "fonts", "JosefinSans-400.woff2")))
  expect_true(file.exists(file.path(site, "assets", "fonts", "NotoSansMath-400.woff2")))
  expect_match(paste(readLines(file.path(site, "assets", "css", "fonts.css")), collapse = ""), "Noto Sans Mono", fixed = TRUE)

  article <- readLines(file.path(site, "articles", "sitepkg.qmd"))
  expect_equal(article[2], "title: \"Getting started\"")
  expect_false(any(grepl("html_vignette|VignetteIndexEntry", article)))
  expect_true(file.exists(file.path(site, "articles", "releases", "r12.qmd")))

  index <- paste(readLines(file.path(site, "index.qmd")), collapse = "\n")
  expect_match(index, "pkg-hero", fixed = TRUE)
  expect_match(index, "Shout and whisper words.", fixed = TRUE)
  expect_false(grepl("[![CRAN]", index, fixed = TRUE))

  cite <- paste(readLines(file.path(site, "citation.qmd")), collapse = "\n")
  expect_match(cite, "Lovelace", fixed = TRUE)

  wf <- readLines(file.path(pkg, ".github", "workflows", "quarto-publish.yml"))
  expect_true(any(grepl("branches: [master]", wf, fixed = TRUE)))
  expect_true(any(grepl("refs/heads/master", wf, fixed = TRUE)))
})

test_that("create_package_site keeps an edited _quarto.yml and index.qmd", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  site <- create_package_site(pkg, site_url = "https://example.org/sitepkg/")
  writeLines("# my own config", file.path(site, "_quarto.yml"))
  writeLines("my own index", file.path(site, "index.qmd"))
  create_package_site(pkg, site_url = "https://example.org/sitepkg/")
  expect_equal(readLines(file.path(site, "_quarto.yml")), "# my own config")
  expect_equal(readLines(file.path(site, "index.qmd")), "my own index")
  create_package_site(pkg, site_url = "https://example.org/sitepkg/", overwrite_config = TRUE)
  expect_match(readLines(file.path(site, "_quarto.yml"))[1], "Generated by")
})

test_that("the guard script accepts a generated config and rejects a broken one", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  site <- create_package_site(pkg, site_url = "https://example.org/sitepkg/")
  guard <- file.path(site, "tools", "check-quarto-yml.R")
  rscript <- file.path(R.home("bin"), "Rscript")
  ok <- suppressWarnings(system2(rscript, c(guard, file.path(site, "_quarto.yml")), stdout = FALSE, stderr = FALSE))
  expect_equal(ok, 0L)
  cfg <- readLines(file.path(site, "_quarto.yml"))
  writeLines(sub("output-dir: _site", "output-dir: ../../docs", cfg, fixed = TRUE), file.path(site, "broken.yml"))
  bad <- suppressWarnings(system2(rscript, c(guard, file.path(site, "broken.yml")), stdout = FALSE, stderr = FALSE))
  expect_equal(bad, 1L)
})

test_that("create_quarto_documentation reference = 'topics' routes the nav to the reference index", {
  skip_without_pandoc()
  pkg <- make_site_fixture()
  out <- file.path(dirname(pkg), "www2")
  suppressMessages(utils::capture.output(
    create_quarto_documentation(pkg, out,
      reference = "topics", navbar_pinned = FALSE, self_host_fonts = TRUE, template = "plain"
    )
  ))
  yml <- paste(readLines(file.path(out, "_quarto.yml")), collapse = "\n")
  expect_match(yml, "reference/index.qmd", fixed = TRUE)
  expect_match(yml, "pinned: false", fixed = TRUE)
  expect_match(yml, "css: assets/css/fonts.css", fixed = TRUE)
  expect_true(file.exists(file.path(out, "reference", "shout.qmd")))
  expect_true(file.exists(file.path(out, "news.qmd")))
  expect_false(file.exists(file.path(out, "api_reference.qmd")))
})

test_that("the default navbar scaffold is unchanged (no pinned key)", {
  pkg <- make_site_fixture()
  out <- file.path(dirname(pkg), "www3")
  suppressMessages(utils::capture.output(create_quarto_documentation(pkg, out, template = "plain")))
  yml <- paste(readLines(file.path(out, "_quarto.yml")), collapse = "\n")
  expect_false(grepl("pinned", yml, fixed = TRUE))
  expect_true(file.exists(file.path(out, "api_reference.qmd")))
})
