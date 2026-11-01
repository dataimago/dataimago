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
    "\\title{sitepkg: A fixture}",
    "\\description{The fixture. \\if{html}{\\figure{logo.svg}{options: style='float: right' alt='logo' width='120'}}}"
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
    sync = FALSE, site_url = "https://example.org/sitepkg/", repo_url = "https://github.com/example/sitepkg",
    org = "Example Org", org_url = "https://example.org", branch = "master"
  )
  cfg <- yaml::read_yaml(file.path(site, "_quarto.yml"))
  expect_equal(cfg$project$`output-dir`, "_site")
  expect_false(cfg$website$navbar$pinned)
  expect_equal(cfg$website$navbar$logo, "assets/brand/logo.svg")
  expect_true("pkgsite-html" %in% names(cfg$format))
  hrefs <- vapply(cfg$website$navbar$left, function(x) x$href, character(1))
  expect_true(all(c("index.qmd", "articles/sitepkg.qmd", "reference/index.qmd", "news.qmd", "citation.qmd") %in% hrefs))

  expect_true(file.exists(file.path(site, ".dataimago", "design.json")))
  expect_equal(
    unlist(cfg$format$`pkgsite-html`$css),
    c(
      "assets/fonts/latin/fonts.css", "assets/fonts/latin-ext/fonts.css",
      "assets/fonts/josefin/fonts.css", "assets/fonts/math/fonts.css", "assets/fonts/lang.css"
    )
  )

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
  site <- create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  writeLines("# my own config", file.path(site, "_quarto.yml"))
  writeLines("my own index", file.path(site, "index.qmd"))
  create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_equal(readLines(file.path(site, "_quarto.yml")), "# my own config")
  expect_equal(readLines(file.path(site, "index.qmd")), "my own index")
  create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/", overwrite_config = TRUE)
  expect_match(readLines(file.path(site, "_quarto.yml"))[1], "Generated by")
})

test_that("the guard script accepts a generated config and rejects a broken one", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  site <- create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
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
  synced <- NULL
  local_mocked_bindings(.run_dataimago_sync = function(site_dir, version, ...) synced <<- c(site_dir, version))
  suppressMessages(utils::capture.output(
    create_quarto_documentation(pkg, out,
      reference = "topics", navbar_pinned = FALSE, self_host_fonts = TRUE, template = "plain"
    )
  ))
  expect_equal(synced, c(out, "0.1.0-alpha.21")) # self_host_fonts routes through the sync path
  expect_true(file.exists(file.path(out, ".dataimago", "design.json")))
  yml <- paste(readLines(file.path(out, "_quarto.yml")), collapse = "\n")
  expect_match(yml, "reference/index.qmd", fixed = TRUE)
  expect_match(yml, "pinned: false", fixed = TRUE)
  expect_match(yml, "assets/fonts/latin/fonts.css", fixed = TRUE)
  expect_match(yml, "assets/fonts/lang.css", fixed = TRUE)
  expect_false(grepl("assets/css/fonts.css", yml, fixed = TRUE))
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

test_that(".normalize_date turns prose dates into ISO dates and drops what it cannot read", {
  expect_equal(.normalize_date("September 26th, 2017"), "2017-09-26")
  expect_equal(.normalize_date("April 21st, 2021"), "2021-04-21")
  expect_equal(.normalize_date("January 1st, 2019"), "2019-01-01")
  expect_equal(.normalize_date("2020-12-18"), "2020-12-18")
  expect_equal(.normalize_date("Jun 5, 2011"), "2011-06-05")
  expect_true(is.na(.normalize_date("sometime in spring")))
})

test_that("vignette dates reach the article front matter in ISO form", {
  v <- tempfile(fileext = ".Rmd")
  writeLines(c("---", "title: T", "date: \"September 26th, 2017\"", "---", "", "Body"), v)
  out <- .vignette_to_article(v)
  expect_true(any(out == "date: \"2017-09-26\""))
  writeLines(c("---", "title: T", "date: \"whenever\"", "---", "", "Body"), v)
  expect_false(any(grepl("^date:", .vignette_to_article(v))))
})

test_that("figures included with \\figure{} are copied and linked from the site", {
  skip_without_pandoc()
  pkg <- make_site_fixture()
  out <- file.path(pkg, "ui", "www")
  create_package_reference(pkg, out)
  page <- paste(readLines(file.path(out, "reference", "sitepkg-package.qmd")), collapse = "\n")
  expect_false(grepl("help/figures", page, fixed = TRUE))
  expect_true(grepl("../assets/figures/logo.svg", page, fixed = TRUE))
  expect_true(file.exists(file.path(out, "assets", "figures", "logo.svg")))
})

# ---- theme and fonts are synced from @dataimago/css, never vendored ----------

spec_outputs <- c(
  "quarto/_extensions/dataimago/pkgsite/" = "_extensions/dataimago/pkgsite/",
  "fonts/latin/" = "assets/fonts/latin/", "fonts/latin-ext/" = "assets/fonts/latin-ext/",
  "fonts/josefin/" = "assets/fonts/josefin/", "fonts/math/" = "assets/fonts/math/",
  "fonts/lang.css" = "assets/fonts/"
)

test_that("design.json is written with the spec keys", {
  site <- withr::local_tempdir()
  path <- .write_design_json(site)
  expect_equal(path, file.path(site, ".dataimago", "design.json"))
  d <- jsonlite::read_json(path)
  expect_equal(d$package, "@dataimago/css")
  expect_equal(d$version, "0.1.0-alpha.21")
  expect_equal(unlist(d$outputs), spec_outputs)
})

test_that("design.json merge keeps author keys and version", {
  site <- withr::local_tempdir()
  dir.create(file.path(site, ".dataimago"))
  jsonlite::write_json(
    list(
      package = "@dataimago/css", version = "0.1.0-alpha.20",
      outputs = list(
        "quarto/_extensions/dataimago/monograph/" = "_extensions/dataimago/monograph/",
        "fonts/latin/" = "custom/latin/"
      )
    ),
    file.path(site, ".dataimago", "design.json"),
    auto_unbox = TRUE
  )
  d <- jsonlite::read_json(.write_design_json(site))
  expect_equal(d$version, "0.1.0-alpha.20")
  expect_equal(d$outputs[["quarto/_extensions/dataimago/monograph/"]], "_extensions/dataimago/monograph/")
  expect_equal(d$outputs[["fonts/latin/"]], "custom/latin/") # never rewritten
  expect_equal(d$outputs[["fonts/math/"]], "assets/fonts/math/") # missing key added
  expect_equal(d$outputs[["quarto/_extensions/dataimago/pkgsite/"]], "_extensions/dataimago/pkgsite/")
})

test_that("no vendored theme or fonts are written", {
  pkg <- make_site_fixture()
  site <- create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_length(list.files(file.path(site, "assets"), pattern = "\\.woff2$", recursive = TRUE), 0L)
  expect_false(dir.exists(file.path(site, "_extensions", "dataimago", "pkgsite")))
  expect_length(list.files(site, pattern = "\\.scss$", recursive = TRUE), 0L)
  expect_false(dir.exists(system.file("quarto-assets", "pkgsite", package = "dataimago")))
})

test_that("sync command uses npx with the pinned version", {
  site <- withr::local_tempdir()
  seen <- NULL
  local_mocked_bindings(
    .tool_path = function(name) "/usr/bin/fake",
    .run_tool = function(command, args, wd) {
      seen <<- list(command = command, args = args, wd = wd)
      0L
    }
  )
  expect_equal(.run_dataimago_sync(site, "0.1.0-alpha.21", from = ""), 0L)
  expect_equal(seen$command, "npx")
  expect_equal(seen$args, c("--yes", "-p", "@dataimago/css@0.1.0-alpha.21", "dataimago-sync"))
  expect_equal(seen$wd, site)

  from <- normalizePath(withr::local_tempdir())
  .run_dataimago_sync(site, "0.1.0-alpha.21", from = from)
  expect_equal(seen$command, "node")
  expect_equal(seen$args, c(file.path(from, "packages/css/dist/bin/dataimago-sync.mjs"), "--from", from))
  expect_equal(seen$wd, site)
})

test_that("create_package_site syncs by default and skips with sync = FALSE", {
  pkg <- make_site_fixture()
  calls <- 0L
  local_mocked_bindings(.run_dataimago_sync = function(site_dir, version, ...) calls <<- calls + 1L)
  create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_equal(calls, 0L)
  create_package_site(pkg, site_url = "https://example.org/sitepkg/")
  expect_equal(calls, 1L)
})

test_that("missing npx aborts with the command", {
  site <- withr::local_tempdir()
  local_mocked_bindings(.tool_path = function(name) "")
  expect_error(.run_dataimago_sync(site, "0.1.0-alpha.21", from = ""), "npx --yes -p @dataimago/css@0.1.0-alpha.21 dataimago-sync", fixed = TRUE)
  from <- normalizePath(withr::local_tempdir())
  expect_error(.run_dataimago_sync(site, "0.1.0-alpha.21", from = from), paste("node", file.path(from, "packages/css/dist/bin/dataimago-sync.mjs"), "--from", from), fixed = TRUE)
})

# ---- fix round 1 ---------------------------------------------------------------

test_that("an up-to-date design.json is left byte-identical, nulls included", {
  site <- withr::local_tempdir()
  dir.create(file.path(site, ".dataimago"))
  path <- file.path(site, ".dataimago", "design.json")
  outs <- paste0('"', names(spec_outputs), '": "', spec_outputs, '"', collapse = ", ")
  writeLines(paste0('{"package":"@dataimago/css","version":"9","n":null,"outputs":{', outs, "}}"), path)
  before <- readBin(path, "raw", file.size(path))
  .write_design_json(site)
  expect_identical(readBin(path, "raw", file.size(path)), before)
})

test_that("adding missing keys preserves nulls, empty objects and arrays", {
  site <- withr::local_tempdir()
  dir.create(file.path(site, ".dataimago"))
  path <- file.path(site, ".dataimago", "design.json")
  writeLines('{"extra":{"a":[1,2],"e":{},"n":null},"version":"9","outputs":{"fonts/latin/":"custom/{x}\\"/"}}', path)
  .write_design_json(site)
  txt <- paste(readLines(path), collapse = "\n")
  expect_match(txt, '"extra":{"a":[1,2],"e":{},"n":null}', fixed = TRUE)
  d <- jsonlite::read_json(path)
  expect_equal(d$version, "9")
  expect_equal(d$outputs[["fonts/latin/"]], "custom/{x}\"/")
  expect_equal(d$outputs[["fonts/math/"]], "assets/fonts/math/")
  expect_equal(d$package, "@dataimago/css")
})

test_that("a relative `from` is normalised before the process runs in site_dir", {
  site <- withr::local_tempdir()
  base <- normalizePath(withr::local_tempdir())
  dir.create(file.path(base, "design"))
  withr::local_dir(base)
  seen <- NULL
  local_mocked_bindings(
    .tool_path = function(name) "/usr/bin/fake",
    .run_tool = function(command, args, wd) {
      seen <<- args
      0L
    }
  )
  .run_dataimago_sync(site, "1", from = "design")
  expect_equal(seen[3], normalizePath(file.path(base, "design")))
  expect_equal(seen[1], file.path(normalizePath(file.path(base, "design")), "packages/css/dist/bin/dataimago-sync.mjs"))
})

test_that("font css paths follow the mapped destinations", {
  out <- spec_outputs
  out[["fonts/latin/"]] <- "custom/"
  expect_equal(
    .pkgsite_font_css(as.list(out)),
    c("custom/fonts.css", "assets/fonts/latin-ext/fonts.css", "assets/fonts/josefin/fonts.css",
      "assets/fonts/math/fonts.css", "assets/fonts/lang.css")
  )
})

test_that("self_host_fonts reads the font list from the site's merged design.json", {
  skip_without_pandoc()
  pkg <- make_site_fixture()
  out <- file.path(dirname(pkg), "www5")
  dir.create(file.path(out, ".dataimago"), recursive = TRUE)
  jsonlite::write_json(list(version = "9", outputs = list("fonts/latin/" = "custom/")),
    file.path(out, ".dataimago", "design.json"), auto_unbox = TRUE)
  local_mocked_bindings(.run_dataimago_sync = function(...) invisible(0L))
  suppressMessages(utils::capture.output(
    create_quarto_documentation(pkg, out, self_host_fonts = TRUE, template = "plain")
  ))
  yml <- paste(readLines(file.path(out, "_quarto.yml")), collapse = "\n")
  expect_match(yml, "      - custom/fonts.css", fixed = TRUE)
  expect_false(grepl("assets/fonts/latin/fonts.css", yml, fixed = TRUE))
  expect_match(yml, "assets/fonts/math/fonts.css", fixed = TRUE)
})

test_that("the guard names assets/fonts/** and requires a fonts-directory resource", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  site <- create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  guard <- file.path(site, "tools", "check-quarto-yml.R")
  cfg <- readLines(file.path(site, "_quarto.yml"))
  writeLines(sub("assets/fonts/**", "static/unrelated-fonts-list/*.txt", cfg, fixed = TRUE), file.path(site, "bad.yml"))
  rscript <- file.path(R.home("bin"), "Rscript")
  res <- suppressWarnings(system2(rscript, c(guard, file.path(site, "bad.yml")), stdout = TRUE, stderr = TRUE))
  expect_equal(attr(res, "status"), 1L)
  expect_match(paste(res, collapse = "\n"), "assets/fonts/**", fixed = TRUE)
})
