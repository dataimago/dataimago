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
  expect_equal(sub(" \\{#ref-data\\}$", "", index[grep("^## ", index)]), c("## Loud", "## Other"))
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
  hrefs <- vapply(cfg$website$navbar$left, function(x) x$href %||% NA_character_, character(1))
  expect_true(all(c("overview/index.qmd", "reference/index.qmd", "news.qmd") %in% hrefs))

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
  expect_match(index, "di-landing-overview", fixed = TRUE)
  expect_false(grepl("pkg-hero", index, fixed = TRUE))
  expect_true(file.exists(file.path(site, "_landing.yml")))
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

# ---- fix round 2: hardened design.json scanner -----------------------------------

merge_raw <- function(txt) {
  site <- withr::local_tempdir(.local_envir = parent.frame())
  dir.create(file.path(site, ".dataimago"))
  path <- file.path(site, ".dataimago", "design.json")
  writeBin(charToRaw(txt), path)
  err <- tryCatch(
    {
      .write_design_json(site)
      NULL
    },
    error = function(e) conditionMessage(e)
  )
  after <- rawToChar(readBin(path, "raw", file.size(path)))
  list(after = after, err = err, parsed = tryCatch(jsonlite::read_json(path), error = function(e) NULL))
}

test_that("a trailing backslash in a string value does not derail the merge", {
  cases <- c(
    first = '{"path":"C:\\\\","version":"1","outputs":{"fonts/latin/":"x/"}}',
    middle = '{"a":"b","path":"C:\\\\","z":"}","outputs":{"fonts/latin/":"x/"}}',
    inside = '{"version":"1","outputs":{"fonts/latin/":"x\\\\","k":"v"},"z":1}'
  )
  for (nm in names(cases)) {
    r <- merge_raw(cases[[nm]])
    expect_null(r$err)
    expect_false(is.null(r$parsed), info = nm)
    expect_equal(r$parsed$outputs[["fonts/math/"]], "assets/fonts/math/", info = nm)
    expect_equal(sum(gregexpr('"outputs"', r$after, fixed = TRUE)[[1]] > 0), 1L, info = nm)
  }
  expect_equal(merge_raw(cases[["inside"]])$parsed$outputs[["fonts/latin/"]], "x\\")
})

test_that("a non-object outputs aborts and leaves the file unchanged", {
  for (txt in c('{"version":"1","outputs":null}', '{"version":"1","outputs":[]}')) {
    r <- merge_raw(txt)
    expect_match(r$err, "must be an object")
    expect_identical(r$after, txt)
  }
})

test_that("CRLF and the trailing-newline state are kept; only the inserted lines differ", {
  crlf <- '{\r\n  "package": "p",\r\n  "version": "1",\r\n  "outputs": {\r\n    "fonts/latin/": "x/"\r\n  }\r\n}\r\n'
  r <- merge_raw(crlf)
  expect_false(grepl("[^\r]\n", r$after))
  expect_true(endsWith(r$after, "\r\n"))
  expect_true(startsWith(r$after, '{\r\n  "package": "p",\r\n  "version": "1",\r\n  "outputs": {\r\n    "fonts/latin/": "x/"'))
  expect_true(endsWith(r$after, '\r\n  }\r\n}\r\n'))
  expect_equal(r$parsed$outputs[["fonts/math/"]], "assets/fonts/math/")

  bare <- '{\n  "package": "p",\n  "version": "1",\n  "outputs": {\n    "fonts/latin/": "x/"\n  }\n}'
  r <- merge_raw(bare)
  expect_false(endsWith(r$after, "\n"))
  expect_true(startsWith(r$after, '{\n  "package": "p",\n  "version": "1",\n  "outputs": {\n    "fonts/latin/": "x/"'))
  expect_true(endsWith(r$after, '\n  }\n}'))
  expect_equal(r$parsed$outputs[["fonts/latin-ext/"]], "assets/fonts/latin-ext/")
})

test_that("inserted entries use the file's own indentation", {
  four <- '{\n    "package": "p",\n    "version": "1",\n    "outputs": {\n        "fonts/latin/": "x/"\n    }\n}\n'
  r <- merge_raw(four)
  expect_match(r$after, '\n        "fonts/math/": ', fixed = TRUE)
  expect_true(endsWith(r$after, '\n    }\n}\n'))
  tab <- '{\n\t"package": "p",\n\t"version": "1",\n\t"outputs": {\n\t\t"fonts/latin/": "x/"\n\t}\n}\n'
  r <- merge_raw(tab)
  expect_match(r$after, '\n\t\t"fonts/math/": ', fixed = TRUE)
  expect_true(endsWith(r$after, '\n\t}\n}\n'))
  expect_false(grepl("\n  ", r$after))
  # absent outputs: the new member follows the file's indent too
  r <- merge_raw('{\n\t"package": "p",\n\t"version": "1"\n}\n')
  expect_match(r$after, '\n\t"outputs": {\n\t\t"', fixed = TRUE)
  expect_equal(r$parsed$outputs[["fonts/josefin/"]], "assets/fonts/josefin/")
})

# ---- landing data and the author-owned index.qmd ----

test_that("landing yml matches the contract", {
  pkg <- make_site_fixture()
  desc <- c(readLines(file.path(pkg, "DESCRIPTION")), "URL: https://CRAN.R-project.org/package=sitepkg",
            "BugReports: https://github.com/o/sitepkg/issues")
  writeLines(desc, file.path(pkg, "DESCRIPTION"))
  d <- .landing_data(pkg, .read_desc(pkg), hero = NULL, repo_url = "https://github.com/o/sitepkg")
  p <- d$pkgsite
  expect_equal(names(d), "pkgsite")
  expect_equal(names(p), c("name", "title", "version", "hero", "links", "cards"))
  expect_equal(p$name, "sitepkg")
  expect_equal(p$version, "1.2-3.0")
  expect_equal(p$hero, list(kind = "fallback", alt = "Animated illustration for sitepkg"))
  expect_equal(vapply(p$links, `[[`, "", "text"), c("GitHub", "CRAN", "Issues"))
  expect_equal(p$links[[2]]$href, "https://cran.r-project.org/package=sitepkg")
  expect_equal(p$links[[3]]$href, "https://github.com/o/sitepkg/issues")
  expect_equal(vapply(p$cards, `[[`, "", "key"), c("overview", "documentation", "api", "news", "source"))
  expect_equal(vapply(p$cards, `[[`, "", "href"), c(
    "overview/index.qmd", "documentation/index.qmd", "reference/index.qmd", "news.qmd", "https://github.com/o/sitepkg"
  ))
  expect_equal(vapply(p$cards, `[[`, "", "title"), c("Overview", "Documentation", "API", "What's new", "Source"))
  desc_of <- function(k) Filter(function(c) c$key == k, p$cards)[[1]]$desc
  expect_equal(desc_of("api"), "2 functions, 1 data set")
  expect_equal(desc_of("overview"), "Why sitepkg exists and how it works")
  expect_equal(desc_of("documentation"), "2 articles; start with Getting started")
  expect_equal(desc_of("news"), "sitepkg 1.2-3.0")
  expect_equal(desc_of("source"), "github.com/o/sitepkg")
  hero <- list(kind = "svg", src = "assets/hero/hero.svg", alt = "A hero.")
  expect_equal(.landing_data(pkg, .read_desc(pkg), hero = hero, repo_url = NULL)$pkgsite$hero, hero)
})

test_that("landing yml degrades", {
  pkg <- make_site_fixture()
  unlink(file.path(pkg, "vignettes"), recursive = TRUE)
  unlink(file.path(pkg, "NEWS.md"))
  unlink(file.path(pkg, "man", "figures"), recursive = TRUE)
  p <- .landing_data(pkg, .read_desc(pkg), hero = NULL, repo_url = NULL)$pkgsite
  keys <- function(p) vapply(p$cards, `[[`, "", "key")
  # no NEWS.md and no repository: the news and source cards have no target, so they are dropped
  expect_equal(keys(p), c("overview", "documentation", "api"))
  desc_of <- function(p, k) Filter(function(c) c$key == k, p$cards)[[1]]$desc
  expect_equal(desc_of(p, "documentation"), "Guides and articles")
  for (k in keys(p)) expect_true(nzchar(desc_of(p, k)))
  expect_false(any(vapply(p$cards, function(c) identical(c$href, "#"), logical(1))))
  expect_equal(p$links, list())
  txt <- paste(.landing_yaml_lines(list(pkgsite = p)), collapse = "\n")
  expect_false(grepl("CRAN|Issues", txt))
  # a known repository gives the news card its releases page and the source card its repo
  p1 <- .landing_data(pkg, .read_desc(pkg), hero = NULL, repo_url = "https://github.com/o/sitepkg")$pkgsite
  expect_equal(keys(p1), c("overview", "documentation", "api", "news", "source"))
  news <- Filter(function(c) c$key == "news", p1$cards)[[1]]
  expect_equal(news$href, "https://github.com/o/sitepkg/releases")
  expect_equal(news$desc, "Release notes")
  # a NEWS.md with no versioned heading keeps the fallback line
  writeLines(c("# Changes", "", "* x"), file.path(pkg, "NEWS.md"))
  p2 <- .landing_data(pkg, .read_desc(pkg), hero = NULL, repo_url = NULL)$pkgsite
  expect_equal(keys(p2), c("overview", "documentation", "api", "news"))
  expect_equal(desc_of(p2, "news"), "Release notes")
  expect_equal(Filter(function(c) c$key == "news", p2$cards)[[1]]$href, "news.qmd")
  # a heading with a version number wins over an earlier plain heading
  writeLines(c("# Changes", "", "# sitepkg 2.0.1", "", "* x"), file.path(pkg, "NEWS.md"))
  p3 <- .landing_data(pkg, .read_desc(pkg), hero = NULL, repo_url = NULL)$pkgsite
  expect_equal(desc_of(p3, "news"), "sitepkg 2.0.1")
})

test_that("CRAN is linked only for a CRAN host URL", {
  pkg <- make_site_fixture()
  links_for <- function(url) {
    d <- .read_desc(pkg)
    d$URL <- url
    vapply(.landing_data(pkg, d, repo_url = NULL)$pkgsite$links, `[[`, "", "text")
  }
  expect_equal(links_for("https://cran.r-project.org/package=sitepkg"), "CRAN")
  expect_equal(links_for("https://example.org/pkg, https://www.cran.r-project.org/package=sitepkg"), "CRAN")
  expect_equal(links_for("https://example.org/pkg,\n https://cran.r-project.org"), "CRAN")
  expect_equal(links_for("https://cran.r-project.org.evil/x"), character(0))
  expect_equal(links_for("https://x.org/?u=cran.r-project.org"), character(0))
  expect_equal(links_for("https://cranXr-project.org"), character(0))
})

test_that("BugReports: http(s) linked as is, an email becomes mailto, anything else is omitted", {
  pkg <- make_site_fixture()
  issues <- function(v) {
    d <- .read_desc(pkg)
    d$BugReports <- v
    l <- .landing_data(pkg, d, repo_url = NULL)$pkgsite$links
    if (length(l)) l[[1]]$href else NULL
  }
  expect_equal(issues("https://github.com/o/p/issues"), "https://github.com/o/p/issues")
  expect_equal(issues("http://x.org/bugs"), "http://x.org/bugs")
  expect_equal(issues("bugs@example.org"), "mailto:bugs@example.org")
  expect_null(issues("see the maintainer"))
  expect_null(issues("javascript:alert(1)"))
})

test_that("API card uses singular and plural forms and counts only public functions", {
  pkg <- make_site_fixture()
  api <- function() Filter(function(c) c$key == "api", .landing_data(pkg, .read_desc(pkg), repo_url = NULL)$pkgsite$cards)[[1]]$desc
  expect_equal(api(), "2 functions, 1 data set")
  unlink(file.path(pkg, "man", "whisper.Rd"))
  expect_equal(api(), "1 function, 1 data set")
  writeLines(c("\\name{extra}", "\\alias{extra}", "\\title{Extra data}", "\\docType{data}", "\\keyword{datasets}"), file.path(pkg, "man", "extra.Rd"))
  expect_equal(api(), "1 function, 2 data sets")
})

test_that("README lead block: only a real block-level tag is fenced", {
  pkg <- make_site_fixture()
  body <- function(lines) {
    writeLines(lines, file.path(pkg, "README.md"))
    .readme_overview_body(pkg)
  }
  b1 <- body(c("<https://x.org> is the home page", "", "More."))
  expect_equal(b1[1], "<https://x.org> is the home page")
  expect_false(any(grepl("{=html}", b1, fixed = TRUE)))
  b2 <- body(c("<b>Bold</b> start of prose", "", "More."))
  expect_equal(b2[1], "<b>Bold</b> start of prose")
  b3 <- body(c("<div align=\"center\">", "Hi", "</div>", "", "More."))
  expect_equal(b3[1], "```{=html}")
  b4 <- body(c("<H2>Title</H2>", "", "More."))
  expect_equal(b4[1], "```{=html}")
})

test_that("the first-H1 strip ignores comment lines inside code fences", {
  pkg <- make_site_fixture()
  writeLines(c("Intro first.", "", "```bash", "# not a heading", "echo hi", "```", "", "# sitepkg", "", "After."), file.path(pkg, "README.md"))
  b <- .readme_overview_body(pkg)
  expect_true("# not a heading" %in% b)
  expect_false("# sitepkg" %in% b)
  writeLines(c("~~~", "# in a tilde fence", "~~~", "", "# sitepkg"), file.path(pkg, "README.md"))
  b <- .readme_overview_body(pkg)
  expect_true("# in a tilde fence" %in% b)
  expect_false("# sitepkg" %in% b)
  # with no heading outside the fences, nothing is stripped
  writeLines(c("```", "# keep me", "```"), file.path(pkg, "README.md"))
  expect_true("# keep me" %in% .readme_overview_body(pkg))
})

test_that("README images point at assets/figures and only badge lines are dropped", {
  pkg <- make_site_fixture()
  writeLines(c(
    "# sitepkg", "",
    "[![Gitter](https://badges.gitter.im/x/y.svg)](https://gitter.im/x/y)",
    "![Build](https://img.shields.io/badge/build-passing-green.svg)",
    "<img src=\"man/figures/logo.png\" align=\"right\">", "",
    "Chat with us on Gitter, and see the AppVeyor build for Windows.", "",
    "![A plot](man/figures/plot.png)", "",
    "<img src=\"man/figures/diagram.svg\" width=\"300\">", "",
    "![Remote](https://example.org/man/figures/x.png)"
  ), file.path(pkg, "README.md"))
  b <- .readme_overview_body(pkg)
  expect_false(any(grepl("badges.gitter|shields.io|logo.png", b)))
  expect_true("Chat with us on Gitter, and see the AppVeyor build for Windows." %in% b)
  expect_true("![A plot](assets/figures/plot.png)" %in% b)
  expect_true(any(grepl("<img src=\"assets/figures/diagram.svg\"", b, fixed = TRUE)))
  expect_true("![Remote](https://example.org/man/figures/x.png)" %in% b)
})

test_that("landing yml is written, round-trips, and is always regenerated", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  site <- file.path(pkg, "www")
  dir.create(site)
  data <- .landing_data(pkg, .read_desc(pkg), hero = NULL, repo_url = NULL)
  data$pkgsite$title <- "Cardinal & Ordinal: \"x\""
  data$pkgsite$version <- "1.5"
  .write_landing_yml(site, data)
  back <- yaml::read_yaml(file.path(site, "_landing.yml"))
  expect_equal(back$pkgsite$title, "Cardinal & Ordinal: \"x\"")
  expect_identical(back$pkgsite$version, "1.5")
  writeLines("stale", file.path(site, "_landing.yml"))
  .write_landing_yml(site, data)
  expect_identical(yaml::read_yaml(file.path(site, "_landing.yml"))$pkgsite$name, "sitepkg")
})

test_that("index.qmd wraps README in .di-landing-overview and is kept on regeneration", {
  pkg <- make_site_fixture()
  site <- file.path(pkg, "www")
  dir.create(site)
  .write_index_qmd(site, pkg, .read_desc(pkg), overwrite = FALSE)
  idx <- readLines(file.path(site, "index.qmd"))
  expect_equal(idx[1:5], c("---", "pagetitle: \"sitepkg\"", "page-layout: custom", "metadata-files: [_landing.yml]", "---"))
  expect_equal(idx[7:9], c("::: {.di-landing}", "::: {.di-landing-overview}", "Shout and whisper words."))
  expect_equal(tail(idx[nzchar(idx)], 2), c(":::", ":::"))
  expect_false(any(grepl("^# sitepkg|\\[!\\[CRAN", idx)))
  writeLines("mine", file.path(site, "index.qmd"))
  .write_index_qmd(site, pkg, .read_desc(pkg), overwrite = FALSE)
  expect_equal(readLines(file.path(site, "index.qmd")), "mine")
  .write_index_qmd(site, pkg, .read_desc(pkg), overwrite = TRUE)
  expect_equal(readLines(file.path(site, "index.qmd"))[2], "pagetitle: \"sitepkg\"")
})

test_that("README with leading raw HTML still yields a valid overview div", {
  skip_without_pandoc()
  pkg <- make_site_fixture()
  writeLines(c(
    "<p align=\"center\">", "  <img src=\"man/figures/logo.png\" width=\"120\">", "</p>", "",
    "<p align=\"center\"><b>Bold tagline</b>", "<br>second line</p>", "",
    "# sitepkg", "", "| a | b |", "|---|---|", "| 1 | 2 |", "", "Tail text."
  ), file.path(pkg, "README.md"))
  site <- file.path(pkg, "www")
  dir.create(site)
  .write_index_qmd(site, pkg, .read_desc(pkg), overwrite = TRUE)
  idx <- readLines(file.path(site, "index.qmd"))
  expect_false(any(grepl("<img", idx)))
  expect_equal(sum(idx == ":::"), 2L)
  html <- system2(.find_pandoc(), c("-f", "markdown", "-t", "html", file.path(site, "index.qmd")), stdout = TRUE)
  html <- paste(html, collapse = "\n")
  expect_match(html, "<div class=\"di-landing\">", fixed = TRUE)
  expect_match(html, "<div class=\"di-landing-overview\">", fixed = TRUE)
  # the overview div closes after the last README block, and the outer one after it
  expect_match(html, "Tail text\\.</p>\\s*</div>\\s*</div>\\s*$")
  expect_match(html, "Bold tagline", fixed = TRUE)
  expect_match(html, "<table", fixed = TRUE)
})

test_that("only a logo basename is dropped, not a content figure whose name starts with logo-", {
  pkg <- make_site_fixture()
  writeLines(c(
    "# sitepkg", "",
    "![Logo](man/figures/logo.png)", "",
    "![Logo2](https://example.org/a/logo.svg?v=2)", "",
    "<img src=\"man/figures/logo.png?raw=1\" align=\"right\">", "",
    "![A diagram of the pipeline](docs/logo-pipeline.png)", "",
    "<img src=\"docs/mylogo-diagram.svg\">"
  ), file.path(pkg, "README.md"))
  b <- .readme_overview_body(pkg)
  expect_false(any(grepl("man/figures/logo|assets/figures/logo|a/logo.svg", b)))
  expect_true("![A diagram of the pipeline](docs/logo-pipeline.png)" %in% b)
  expect_true(any(grepl("docs/mylogo-diagram.svg", b, fixed = TRUE)))
})

test_that("the man/figures rewrite skips fenced code", {
  pkg <- make_site_fixture()
  writeLines(c(
    "# sitepkg", "", "![P](man/figures/p.png)", "",
    "```markdown", "![P](man/figures/p.png)", "```", "",
    "~~~", "<img src=\"man/figures/q.png\">", "~~~"
  ), file.path(pkg, "README.md"))
  b <- .readme_overview_body(pkg)
  expect_true("![P](assets/figures/p.png)" %in% b)
  expect_equal(sum(b == "![P](man/figures/p.png)"), 1L)
  expect_true("<img src=\"man/figures/q.png\">" %in% b)
})

# ---- hero slot (Task B3) ----

good_hero_svg <- function(extra_style = "", body = "") {
  c('<!-- built -->',
    '<svg class="h" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">',
    '<style>',
    '@media (prefers-reduced-motion: no-preference) {',
    '  .h .a { animation: spin 2s ease; animation-iteration-count: 3; }',
    '  @keyframes spin { from { opacity: 0 } to { opacity: 1 } }',
    '}',
    extra_style,
    '</style>', body, '<circle class="a" r="2"/></svg>')
}

write_hero <- function(pkg, lines, name = "hero.svg") {
  dir.create(file.path(pkg, "ui", "hero"), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, file.path(pkg, "ui", "hero", name))
  file.path(pkg, "ui", "hero", name)
}

test_that("a clean svg hero passes and is found", {
  pkg <- make_site_fixture()
  p <- write_hero(pkg, good_hero_svg())
  expect_no_error(.check_hero_svg(p))
  h <- .find_hero(pkg)
  expect_identical(h$kind, "svg")
  expect_identical(normalizePath(h$src), normalizePath(p))
  expect_identical(h$alt, "Animated illustration for sitepkg")
})

test_that("svg hero refusals name the file and the problem", {
  pkg <- make_site_fixture()
  bad <- list(
    xml = c('<?xml version="1.0"?>', good_hero_svg()),
    script = good_hero_svg(body = "<script>alert(1)</script>"),
    animate = good_hero_svg(body = '<animate attributeName="x" dur="1s"/>'),
    animateTransform = good_hero_svg(body = '<animateTransform attributeName="transform"/>'),
    animateMotion = good_hero_svg(body = '<animateMotion path="M0 0"/>'),
    set = good_hero_svg(body = '<set attributeName="x" to="1"/>'),
    viewbox = sub("viewBox=\"0 0 10 10\"", "width=\"10\"", good_hero_svg(), fixed = TRUE)
  )
  pat <- c(xml = "<\\?xml", script = "<script", animate = "SMIL", animateTransform = "SMIL",
           animateMotion = "SMIL", set = "SMIL", viewbox = "viewBox")
  for (nm in names(bad)) {
    p <- write_hero(pkg, bad[[nm]], paste0(nm, ".svg"))
    expect_error(.check_hero_svg(p), pat[[nm]], info = nm)
    expect_error(.check_hero_svg(p), paste0(nm, ".svg"), fixed = TRUE, info = nm)
  }
})

test_that("animation outside the no-preference media block is refused", {
  pkg <- make_site_fixture()
  p1 <- write_hero(pkg, good_hero_svg(".h .b { animation: spin 2s; }"), "outside.svg")
  expect_error(.check_hero_svg(p1), "prefers-reduced-motion")
  p2 <- write_hero(pkg, good_hero_svg(".h .b { animation-name: spin; }"), "outside-name.svg")
  expect_error(.check_hero_svg(p2), "prefers-reduced-motion")
  p3 <- write_hero(pkg, good_hero_svg(
    "@media (prefers-reduced-motion: reduce) { .h .b { animation: spin 2s; } }"), "reduce.svg")
  expect_error(.check_hero_svg(p3), "prefers-reduced-motion")
  p4 <- write_hero(pkg, good_hero_svg(body = '<rect style="animation: spin 2s"/>'), "inline.svg")
  expect_error(.check_hero_svg(p4), "inline")
  # animation-duration alone is not an animation declaration
  p5 <- write_hero(pkg, good_hero_svg(".h .b { animation-duration: 2s; }"), "dur.svg")
  expect_no_error(.check_hero_svg(p5))
})

test_that("a missing or infinite iteration count warns but does not abort", {
  pkg <- make_site_fixture()
  none <- sub("animation-iteration-count: 3;", "", good_hero_svg(), fixed = TRUE)
  expect_warning(.check_hero_svg(write_hero(pkg, none, "none.svg")), "animation-iteration-count")
  inf <- sub("count: 3", "count: infinite", good_hero_svg(), fixed = TRUE)
  expect_warning(.check_hero_svg(write_hero(pkg, inf, "inf.svg")), "infinite")
  expect_no_warning(.check_hero_svg(write_hero(pkg, good_hero_svg(), "ok.svg")))
})

test_that("js hero without poster aborts; with poster it is found", {
  pkg <- make_site_fixture()
  dir.create(file.path(pkg, "ui", "hero"), recursive = TRUE)
  writeLines("export default function mount() {}", file.path(pkg, "ui", "hero", "hero.js"))
  expect_error(.find_hero(pkg), "poster")
  writeLines("x", file.path(pkg, "ui", "hero", "poster.png"))
  h <- .find_hero(pkg)
  expect_identical(h$kind, "js")
  expect_identical(basename(h$poster), "poster.png")
})

test_that("no hero gives the fallback; hero.yml supplies alt", {
  pkg <- make_site_fixture()
  expect_identical(.find_hero(pkg)$kind, "fallback")
  skip_if_not_installed("yaml")
  write_hero(pkg, good_hero_svg())
  writeLines('alt: "A nested spiral of ordinals."', file.path(pkg, "ui", "hero", "hero.yml"))
  expect_identical(.find_hero(pkg)$alt, "A nested spiral of ordinals.")
})

test_that("svg hero is copied to assets/hero and recorded in _landing.yml", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  write_hero(pkg, good_hero_svg())
  writeLines("<svg viewBox='0 0 1 1'/>", file.path(pkg, "ui", "hero", "poster.svg"))
  site <- create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_true(file.exists(file.path(site, "assets", "hero", "hero.svg")))
  expect_true(file.exists(file.path(site, "assets", "hero", "poster.svg")))
  hero <- yaml::read_yaml(file.path(site, "_landing.yml"))$pkgsite$hero
  expect_identical(hero$kind, "svg")
  expect_identical(hero$src, "assets/hero/hero.svg")
  expect_identical(hero$poster, "assets/hero/poster.svg")
  expect_identical(hero$alt, "Animated illustration for sitepkg")
})

test_that("js hero is copied with its poster and recorded", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  dir.create(file.path(pkg, "ui", "hero"), recursive = TRUE)
  writeLines("export default function mount() {}", file.path(pkg, "ui", "hero", "hero.js"))
  writeLines("png", file.path(pkg, "ui", "hero", "poster.png"))
  site <- create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  hero <- yaml::read_yaml(file.path(site, "_landing.yml"))$pkgsite$hero
  expect_identical(c(hero$kind, hero$src, hero$poster),
                   c("js", "assets/hero/hero.js", "assets/hero/poster.png"))
  expect_true(file.exists(file.path(site, "assets", "hero", "hero.js")))
})

test_that("no hero: fallback recorded and nothing copied", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  site <- create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  hero <- yaml::read_yaml(file.path(site, "_landing.yml"))$pkgsite$hero
  expect_identical(hero$kind, "fallback")
  expect_null(hero$src)
  expect_false(dir.exists(file.path(site, "assets", "hero")))
})

# ---- hero slot, review round 1 ----

G1 <- '@media (prefers-reduced-motion: no-preference) { .h .a { animation: s 2s; animation-iteration-count: 3; } }'
mk1 <- function(style = "", body = "", head = G1) {
  paste0('<svg class="h" viewBox="0 0 1 1"><style>', head, "\n", style, "</style>", body, "</svg>")
}
hero_msg <- function(pkg, txt, name = "probe.svg") {
  p <- write_hero(pkg, txt, name)
  tryCatch({ .check_hero_svg(p); NA_character_ }, error = function(e) conditionMessage(e))
}

test_that("switching to fallback clears assets/hero", {
  pkg <- make_site_fixture()
  site <- file.path(pkg, "www")
  write_hero(pkg, good_hero_svg())
  .install_hero(.find_hero(pkg), site)
  expect_true(file.exists(file.path(site, "assets", "hero", "hero.svg")))
  unlink(file.path(pkg, "ui"), recursive = TRUE)
  .install_hero(.find_hero(pkg), site)
  expect_length(list.files(file.path(site, "assets", "hero")), 0L)
})

test_that("error messages are interpolated, not raw glue, and name the culprit", {
  pkg <- make_site_fixture()
  m <- hero_msg(pkg, mk1(".h .b { animation-name: s }"))
  expect_match(m, "animation-name", fixed = TRUE)
  expect_false(grepl("[{}]", sub("\\{.*", "", m)) && grepl("\\{\\.code", m))
  expect_false(grepl("{.code", m, fixed = TRUE))
  m2 <- hero_msg(pkg, mk1(body = "<svg:animate attributeName='x'/>"))
  expect_match(m2, "svg:animate", fixed = TRUE)
  expect_false(grepl("{", m2, fixed = TRUE))
})

test_that("vendor-prefixed and uppercase animation properties are refused", {
  pkg <- make_site_fixture()
  for (css in c(".h .b { -webkit-animation: s 2s infinite }", ".h .b { -webkit-animation-name: s }",
                ".h .b { ANIMATION: s 1s }", ".h .b { -moz-animation: s 1s }")) {
    expect_match(hero_msg(pkg, mk1(css)), "animation", info = css)
  }
})

test_that("the no-preference prelude must be exact", {
  pkg <- make_site_fixture()
  bad <- c(
    "@media not (prefers-reduced-motion: no-preference) { .h .b{animation: s 1s} }",
    "@media (prefers-reduced-motion: no-preference), (prefers-reduced-motion: reduce) { .h .b{animation: s 1s} }",
    "@media only (prefers-reduced-motion: no-preference) or print { .h .b{animation: s 1s} }",
    "@media (min-width: 0) { .h .b { animation: s 1s infinite } }",
    "@media (min-width:0) /* prefers-reduced-motion: no-preference */ { .h .b{animation: s 1s} }",
    "@supports (display:block) { .h .b{animation: s 1s} }"
  )
  for (css in bad) expect_false(is.na(hero_msg(pkg, mk1(css))), info = css)
  ok <- "@MEDIA  (Prefers-Reduced-Motion:No-Preference)  and (min-width: 600px) { .h .b{animation: s 1s; animation-iteration-count: 3} }"
  expect_true(is.na(hero_msg(pkg, mk1(ok))))
})

test_that("strings and comments cannot fake or unbalance the media block", {
  pkg <- make_site_fixture()
  cases <- c(
    d1 = '<svg viewBox="0 0 1 1"><style>.x::after{content:"@media (prefers-reduced-motion: no-preference) {{"} .y{animation:s 1s infinite}</style></svg>',
    c8 = mk1('.h .b::after { content: "}" } .h .c { animation: s 1s }'),
    c8b = mk1('.h .b::after { content: "{"; } .h .c{animation:s 1s}'),
    c8x = mk1('.h .b::after { content: \'@media (prefers-reduced-motion: no-preference) {\' } .h .c { animation: s 1s }')
  )
  for (nm in names(cases)) expect_false(is.na(hero_msg(pkg, cases[[nm]])), info = nm)
  # an escaped quote does not end the string early
  esc <- mk1('.h .b::after { content: "a\\"}" } .h .d { color: red }')
  expect_true(is.na(suppressWarnings(hero_msg(pkg, esc))))
})

test_that("animation-play-state is refused anywhere", {
  pkg <- make_site_fixture()
  inside <- "@media (prefers-reduced-motion: no-preference) { .h .a { animation-play-state: paused } }"
  m <- hero_msg(pkg, mk1(inside))
  expect_match(m, "animation-play-state", fixed = TRUE)
  expect_match(hero_msg(pkg, mk1(".h .a { -webkit-animation-play-state: paused }")), "animation-play-state")
})

test_that("long transitions outside the block are refused; inside they are allowed", {
  pkg <- make_site_fixture()
  expect_match(hero_msg(pkg, mk1(".h .b { transition: opacity 2s }")), "transition")
  expect_match(hero_msg(pkg, mk1(".h .b { -webkit-transition-duration: 500ms }")), "transition")
  expect_match(hero_msg(pkg, mk1(".h .b { transition: opacity 0.4s }")), "transition")
  expect_true(is.na(hero_msg(pkg, mk1(".h .b { transition: opacity 200ms }"))))
  inside <- "@media (prefers-reduced-motion: no-preference) { .h .b { transition: opacity 2s } }"
  expect_true(is.na(hero_msg(pkg, mk1(inside))))
})

test_that("untrusted-markup rules apply to hero svgs", {
  pkg <- make_site_fixture()
  bad <- list(
    import = mk1("@import url(https://evil.example/x.css);"),
    import_str = mk1('@import "https://evil.example/x.css";'),
    onload = '<svg class="h" viewBox="0 0 1 1" onload="alert(1)"><style></style></svg>',
    onclick = mk1(body = '<rect onClick="x()"/>'),
    jsurl = mk1(body = '<a href="javascript:alert(1)"><rect/></a>'),
    jsxlink = mk1(body = '<a xlink:href=" JavaScript:alert(1)"><rect/></a>'),
    use_ext = mk1(body = '<use xlink:href="https://evil.example/x.svg#a"/>'),
    image_ext = mk1(body = '<image href="https://evil.example/x.svg"/>'),
    foreign = mk1(body = "<foreignObject><div/></foreignObject>"),
    iframe = mk1(body = "<iframe src='x'></iframe>"),
    object = mk1(body = "<object data='x'></object>"),
    embed = mk1(body = "<embed src='x'/>"),
    SET = mk1(body = '<SET attributeName="x" to="1"/>'),
    ns_animate = mk1(body = '<svg:animate attributeName="x"/>'),
    unclosed = paste0('<svg class="h" viewBox="0 0 1 1"><style>', G1)
  )
  for (nm in names(bad)) expect_false(is.na(hero_msg(pkg, bad[[nm]])), info = nm)
  ok <- mk1(body = paste0('<use href="#a"/><use xlink:href="#a"/>',
                          '<image href="data:image/png;base64,AAAA"/>'))
  expect_true(is.na(hero_msg(pkg, ok)))
})

test_that("poster.svg is checked as a still variant; poster.png is opaque", {
  pkg <- make_site_fixture()
  dir.create(file.path(pkg, "ui", "hero"), recursive = TRUE)
  writeLines("export default function mount() {}", file.path(pkg, "ui", "hero", "hero.js"))
  pp <- file.path(pkg, "ui", "hero", "poster.svg")
  for (bad in c(
    '<svg viewBox="0 0 1 1"><style>.a{animation: s 1s}</style></svg>',
    '<svg viewBox="0 0 1 1"><style>.a{transition: opacity 1ms}</style></svg>',
    '<svg viewBox="0 0 1 1"><style>@media (prefers-reduced-motion: no-preference){.a{animation: s 1s}}</style></svg>',
    '<svg viewBox="0 0 1 1"><script>1</script></svg>',
    '<svg viewBox="0 0 1 1"><animate/></svg>',
    '<?xml version="1.0"?><svg viewBox="0 0 1 1"/>',
    '<svg viewBox="0 0 1 1" onload="x()"/>',
    '<svg width="1"/>'
  )) {
    writeLines(bad, pp)
    expect_error(.find_hero(pkg), "poster.svg", fixed = TRUE, info = bad)
  }
  writeLines('<svg viewBox="0 0 1 1"><rect/></svg>', pp)
  expect_identical(.find_hero(pkg)$kind, "js")
  unlink(pp)
  writeLines("not really a png <script>", file.path(pkg, "ui", "hero", "poster.png"))
  expect_identical(.find_hero(pkg)$kind, "js")
  # an svg hero's poster.svg is checked too
  write_hero(pkg, good_hero_svg())
  writeLines('<svg viewBox="0 0 1 1"><script>1</script></svg>', pp)
  expect_error(.find_hero(pkg), "poster.svg", fixed = TRUE)
})

test_that("comment-split tags, uppercase xml, unquoted style and nested media are handled", {
  pkg <- make_site_fixture()
  expect_false(is.na(hero_msg(pkg, mk1(body = "<scr<!-- -->ipt>"))))
  expect_false(is.na(hero_msg(pkg, paste0(" <?XML version='1.0'?>", mk1()))))
  expect_false(is.na(hero_msg(pkg, '<svg viewBox="0 0 1 1"><rect style=animation:s></rect></svg>')))
  nested <- "@media (prefers-reduced-motion: no-preference) { @media (prefers-reduced-motion: reduce) { .h .b { animation: s 1s } } }"
  expect_false(is.na(hero_msg(pkg, mk1(nested))))
})

test_that("transition-delay longhand over 300ms is refused outside the block", {
  pkg <- make_site_fixture()
  expect_match(hero_msg(pkg, mk1(".h .b{transition-delay: 2s}")), "transition-delay")
  expect_true(is.na(hero_msg(pkg, mk1(".h .b{transition-delay: 100ms}"))))
})

test_that("only raster data:image URIs are allowed in hrefs", {
  pkg <- make_site_fixture()
  for (u in c("data:image/svg+xml;base64,PHN2Zy8+", "data:image/svg+xml,%3Csvg%2F%3E", "DATA:IMAGE/SVG+XML;base64,AAAA")) {
    expect_false(is.na(hero_msg(pkg, mk1(body = sprintf('<image href="%s"/>', u)))), info = u)
  }
  for (u in c("data:image/png;base64,AAAA", "DATA:IMAGE/JPEG;base64,AAAA", "data:image/webp,AA", "data:image/gif;base64,AA")) {
    expect_true(is.na(hero_msg(pkg, mk1(body = sprintf('<image href="%s"/>', u)))), info = u)
  }
})

# ---- B4: Overview . Documentation . API navigation ----

nav_site <- function(pkg, ...) {
  suppressWarnings(create_package_site(pkg, sync = FALSE, repo_url = "https://github.com/o/sitepkg", ...))
}
nav_cfg <- function(site) yaml::read_yaml(file.path(site, "_quarto.yml"))$website$navbar

test_that("navbar is Overview, Documentation, API, What's new, GitHub", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  dir.create(file.path(pkg, "ui"))
  writeLines(c("- title: P", "  url: https://e.org/p", "  authors: A", "  year: 2025", "  venue: V"), file.path(pkg, "ui", "papers.yml"))
  writeLines(c("- title: T", "  url: https://e.org/t", "  venue: V", "  date: 2026-01-02"), file.path(pkg, "ui", "talks.yml"))
  nav <- nav_cfg(nav_site(pkg))
  expect_equal(vapply(nav$left, function(x) x$text, ""), c("Overview", "Documentation", "API", "What's new"))
  expect_equal(nav$left[[1]]$href, "overview/index.qmd")
  expect_equal(nav$left[[3]]$href, "reference/index.qmd")
  expect_equal(nav$left[[4]]$href, "news.qmd")
  menu <- nav$left[[2]]$menu
  expect_equal(vapply(menu, function(x) x$text, ""), c("Get started", "Articles", "Papers", "Talks", "Data", "Cite"))
  expect_equal(vapply(menu, function(x) x$href, ""), c(
    "articles/sitepkg.qmd", "articles/index.qmd", "papers.qmd", "talks.qmd", "reference/index.qmd#ref-data", "citation.qmd"
  ))
  expect_equal(nav$right[[1]]$icon, "github")
  expect_false(any(c("Home", "Reference", "News", "Citation") %in% vapply(nav$left, function(x) x$text, "")))
})

test_that("Data, Papers and Talks leave the menu when absent", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  unlink(file.path(pkg, "man", "words.Rd"))
  site <- nav_site(pkg)
  menu <- nav_cfg(site)$left[[2]]$menu
  expect_equal(vapply(menu, function(x) x$text, ""), c("Get started", "Articles", "Cite"))
  expect_false(file.exists(file.path(site, "papers.qmd")))
  expect_false(file.exists(file.path(site, "talks.qmd")))
  doc <- paste(readLines(file.path(site, "documentation", "index.qmd")), collapse = "\n")
  expect_false(grepl("papers.qmd|talks.qmd|Data", doc))
  expect_match(doc, "../articles/sitepkg.qmd", fixed = TRUE)
  expect_match(doc, "../citation.qmd", fixed = TRUE)
})

test_that("papers and talks pages from yml; absent yml omits them", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  dir.create(file.path(pkg, "ui"))
  writeLines(c(
    "- title: Old *one* [x]", "  url: https://e.org/old", "  authors: [A, B]", "  year: 2020", "  venue: J1",
    "- title: New", "  url: https://e.org/new", "  authors: C", "  year: 2024", "  venue: J2",
    "  doi: 10.1/abc", "  abstract: About it."
  ), file.path(pkg, "ui", "papers.yml"))
  writeLines(c(
    "- title: Early", "  url: https://e.org/e", "  venue: V", "  date: 2025-01-05",
    "- title: Late", "  url: https://e.org/l", "  venue: V", "  date: 2026-03-01", "  thumb: assets/l.png"
  ), file.path(pkg, "ui", "talks.yml"))
  site <- nav_site(pkg)
  pp <- readLines(file.path(site, "papers.qmd"))
  expect_lt(grep("New", pp)[1], grep("Old", pp)[1])
  expect_true(any(grepl("Old \\*one\\* \\[x\\]", pp, fixed = TRUE)))
  expect_true(any(grepl("https://doi.org/10.1/abc", pp, fixed = TRUE)))
  expect_true(any(grepl("About it.", pp, fixed = TRUE)))
  expect_false(any(grepl("doi.org", pp[grep("Old", pp)[1]:length(pp)][1:3], fixed = TRUE)))
  tt <- readLines(file.path(site, "talks.qmd"))
  expect_lt(grep("Late", tt)[1], grep("Early", tt)[1])
  expect_true(any(grepl("assets/l.png", tt, fixed = TRUE)))
  unlink(file.path(pkg, "ui"), recursive = TRUE)
  site2 <- nav_site(pkg, output_path = "www2")
  expect_false(file.exists(file.path(site2, "papers.qmd")))
  expect_false(file.exists(file.path(site2, "talks.qmd")))
})

test_that("papers and talks yml errors abort with file and entry", {
  pkg <- make_site_fixture()
  dir.create(file.path(pkg, "ui"))
  site <- file.path(pkg, "ui", "www"); dir.create(site, recursive = TRUE)
  writeLines(c("- title: [unclosed", "  url: x: y: :"), file.path(pkg, "ui", "papers.yml"))
  expect_error(.papers_page(pkg, site), "papers.yml")
  writeLines(c("- title: A", "  url: https://e.org", "- title: B"), file.path(pkg, "ui", "papers.yml"))
  expect_error(.papers_page(pkg, site), "papers.yml.*entry 2.*url")
  writeLines(c("- title: A", "  url: https://e.org", "  venue: V"), file.path(pkg, "ui", "talks.yml"))
  expect_error(.talks_page(pkg, site), "talks.yml.*entry 1.*date")
})

test_that("overview placeholder kept on regeneration", {
  pkg <- make_site_fixture()
  site <- nav_site(pkg)
  ov <- file.path(site, "overview", "index.qmd")
  expect_true(file.exists(ov))
  txt <- paste(readLines(ov), collapse = "\n")
  expect_match(txt, "The overview of sitepkg", fixed = TRUE)
  expect_match(txt, "is being written", fixed = TRUE)
  expect_match(txt, "../documentation/index.qmd", fixed = TRUE)
  expect_match(txt, "../reference/index.qmd", fixed = TRUE)
  writeLines(c("---", "title: Overview", "---", "", "Authored."), ov)
  nav_site(pkg)
  expect_equal(readLines(ov)[5], "Authored.")
  expect_true(file.exists(file.path(site, "documentation", "index.qmd")))
})

test_that("news alias for pkgdown url", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  out <- withr::local_tempdir()
  create_package_news(pkg, out)
  fm <- yaml::yaml.load(paste(.split_front_matter(readLines(file.path(out, "news.qmd")))$yaml, collapse = "\n"))
  expect_equal(fm$aliases, "news/index.html")
})

# ---- B4 fix round 1 ----

ui_site <- function(papers = NULL, talks = NULL) {
  pkg <- make_site_fixture(withr::local_tempdir(.local_envir = parent.frame()))
  dir.create(file.path(pkg, "ui"))
  if (!is.null(papers)) writeLines(papers, file.path(pkg, "ui", "papers.yml"))
  if (!is.null(talks)) writeLines(talks, file.path(pkg, "ui", "talks.yml"))
  site <- file.path(pkg, "ui", "www"); dir.create(site, recursive = TRUE)
  list(pkg = pkg, site = site)
}
ok_paper <- c("- title: A", "  url: https://e.org/a")
ok_talk <- c("- title: T", "  url: https://e.org/t", "  date: 2026-01-02")
marker <- "<!-- generated by dataimago::create_package_site() -->"

test_that("generated papers and talks carry a marker; only marked pages are deleted or overwritten", {
  u <- ui_site(ok_paper, ok_talk)
  .papers_page(u$pkg, u$site); .talks_page(u$pkg, u$site)
  expect_true(marker %in% readLines(file.path(u$site, "papers.qmd")))
  expect_true(marker %in% readLines(file.path(u$site, "talks.qmd")))
  expect_no_error(.papers_page(u$pkg, u$site))  # regeneration over its own page
  unlink(file.path(u$pkg, "ui", "papers.yml"))
  writeLines("", file.path(u$pkg, "ui", "talks.yml"))
  expect_null(.papers_page(u$pkg, u$site)); expect_null(.talks_page(u$pkg, u$site))
  expect_false(file.exists(file.path(u$site, "papers.qmd")))
  expect_false(file.exists(file.path(u$site, "talks.qmd")))
  # hand-written page: kept without yml, protected with yml
  writeLines("Mine", file.path(u$site, "papers.qmd"))
  expect_null(.papers_page(u$pkg, u$site))
  expect_equal(readLines(file.path(u$site, "papers.qmd")), "Mine")
  writeLines(ok_paper, file.path(u$pkg, "ui", "papers.yml"))
  expect_error(.papers_page(u$pkg, u$site), "papers.qmd.*kept")
  expect_equal(readLines(file.path(u$site, "papers.qmd")), "Mine")
})

test_that("the Data link follows the resolved data section, whatever it is called", {
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  cfg <- list(
    list(title = "Things", contents = list("shout", "whisper")),
    list(title = "Corpora", contents = list("words"))
  )
  site <- suppressWarnings(create_package_site(pkg, sync = FALSE, reference_config = cfg))
  idx <- readLines(file.path(site, "reference", "index.qmd"))
  expect_true("## Corpora {#ref-data}" %in% idx)
  expect_false(any(grepl("{#ref-data}", idx[idx == "## Things"], fixed = TRUE)))
  menu <- nav_cfg(site)$left[[2]]$menu
  expect_true("reference/index.qmd#ref-data" %in% vapply(menu, function(x) x$href, ""))
  # data topics left out of a custom config still land in Other, which carries the id
  cfg2 <- list(list(title = "Things", contents = list("shout")))
  site2 <- suppressWarnings(create_package_site(pkg, output_path = "w2", sync = FALSE, reference_config = cfg2))
  expect_true(any(grepl("^## Other \\{#ref-data\\}$", readLines(file.path(site2, "reference", "index.qmd")))))
})

test_that("interpolated text is HTML-escaped and single-line", {
  u <- ui_site(c(
    "- title: \"<script>alert(1)</script> & co\"", "  url: https://e.org/a",
    "  authors: \"A <b>\\nB\"", "  venue: \"V\\n\\n# not a heading\"", "  doi: \"10.1/<x>\""
  ), c(ok_talk[1:2], "  date: 2026-01-02", "  venue: \"<i>V</i>\""))
  p <- paste(readLines(.papers_page(u$pkg, u$site)), collapse = "\n")
  expect_false(grepl("<script>|<b>|<x>", p))
  expect_match(p, "&lt;script&gt;alert(1)&lt;/script&gt; &amp; co", fixed = TRUE)
  expect_match(p, "A &lt;b&gt; B", fixed = TRUE)
  expect_match(p, "V # not a heading", fixed = TRUE)
  t <- paste(readLines(.talks_page(u$pkg, u$site)), collapse = "\n")
  expect_false(grepl("<i>", t))
})

test_that("abstract is a blockquote with block syntax neutralised", {
  u <- ui_site(c(ok_paper, "  abstract: |", "    # Head", "    - item", "    ::: {.x}", "    > quoted", "", "    1. num"))
  p <- readLines(.papers_page(u$pkg, u$site))
  expect_true("> \\# Head" %in% p)
  expect_true("> \\- item" %in% p)
  expect_true("> \\::: {.x}" %in% p)
  expect_true("> \\&gt; quoted" %in% p || "> &gt; quoted" %in% p)
  expect_true("> 1\\. num" %in% p)
  expect_false(any(grepl("^(# |- |::: |> >)", p)))
})

test_that("url and thumb schemes are checked", {
  for (bad in c("javascript:alert(1)", "ftp://x", "//e.org", "data:text/html,x")) {
    u <- ui_site(c("- title: A", paste0("  url: \"", bad, "\"")))
    expect_error(.papers_page(u$pkg, u$site), "papers.yml.*entry 1.*url", info = bad)
  }
  for (bad in c("javascript:x", "../up.png", "a/../b.png", "data:image/svg+xml;base64,AA", "file:///x")) {
    u <- ui_site(talks = c(ok_talk, paste0("  thumb: \"", bad, "\"")))
    expect_error(.talks_page(u$pkg, u$site), "talks.yml.*entry 1.*thumb", info = bad)
  }
  for (good in c("https://e.org/i.png", "assets/i.png", "data:image/png;base64,AA")) {
    u <- ui_site(talks = c(ok_talk, paste0("  thumb: \"", good, "\"")))
    expect_no_error(.talks_page(u$pkg, u$site))
  }
})

test_that("dates and years are validated and sorted on parsed values", {
  for (bad in c("2026-13-01", "2026-02-30", "Jan 5 2026", "26-01-01", "2026")) {
    u <- ui_site(talks = c("- title: T", "  url: https://e.org", paste0("  date: \"", bad, "\"")))
    expect_error(.talks_page(u$pkg, u$site), "talks.yml.*entry 1.*date", info = bad)
  }
  u <- ui_site(papers = c(ok_paper, "  year: 99"))
  expect_error(.papers_page(u$pkg, u$site), "papers.yml.*entry 1.*year")
  u <- ui_site(papers = c(ok_paper, "  year: 2024.5"))
  expect_error(.papers_page(u$pkg, u$site), "year")
  mk <- function(d, n) c(paste0("- title: ", n), "  url: https://e.org", paste0("  date: \"", d, "\""))
  u <- ui_site(talks = c(mk("2026-01", "Month"), mk("2026-01-15", "Day"), mk("2025-12-31", "Old"), mk("2026-01", "Month2")))
  tt <- readLines(.talks_page(u$pkg, u$site))
  ord <- sub("^## \\[(.*)\\]\\(.*", "\\1", grep("^## ", tt, value = TRUE))
  expect_equal(ord, c("Day", "Month", "Month2", "Old"))
})

test_that("field types are enforced", {
  for (f in c("title", "authors", "venue", "url")) {
    for (val in c("true", "42")) {
      e <- list(title = "A", url = "https://e.org/a")
      e[[f]] <- val
      u <- ui_site(c(paste0("- ", names(e)[1], ": ", e[[1]]), paste0("  ", names(e)[-1], ": ", unlist(e[-1]))))
      expect_error(.papers_page(u$pkg, u$site), paste0("papers.yml.*entry 1.*", f), info = paste(f, val))
    }
  }
})

# ---- B5: output_path everywhere, URL defaults, pinned Quarto, sync check, Rbuildignore ----

test_that("custom output_path flows into workflow and guard", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  site <- create_package_site(pkg, output_path = "docs/site", sync = FALSE, site_url = "https://example.org/sitepkg/")
  wf <- readLines(file.path(pkg, ".github", "workflows", "quarto-publish.yml"))
  expect_false(any(grepl("ui/www", wf, fixed = TRUE)))
  expect_true(any(grepl("\"docs/site/**\"", wf, fixed = TRUE)))
  expect_true(any(grepl("run: Rscript docs/site/tools/check-quarto-yml.R", wf, fixed = TRUE)))
  expect_true(any(grepl("run: quarto render docs/site", wf, fixed = TRUE)))
  expect_true(any(grepl("path: docs/site/_site", wf, fixed = TRUE)))
  expect_true(any(grepl("working-directory: docs/site", wf, fixed = TRUE)))
  guard <- readLines(file.path(site, "tools", "check-quarto-yml.R"))
  expect_false(any(grepl("ui/www", guard, fixed = TRUE)))
  expect_true(any(grepl("docs/site/_quarto.yml", guard, fixed = TRUE)))
})

test_that("site and repo url default from DESCRIPTION", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  cat("URL: https://example.org/x, https://someone.github.io/sitepkg/ https://github.com/someone/sitepkg.git\n",
    file = file.path(pkg, "DESCRIPTION"), append = TRUE
  )
  site <- create_package_site(pkg, sync = FALSE)
  cfg <- yaml::read_yaml(file.path(site, "_quarto.yml"))
  expect_equal(cfg$website$`site-url`, "https://someone.github.io/sitepkg/")
  expect_equal(cfg$website$`repo-url`, "https://github.com/someone/sitepkg")
  landing <- paste(readLines(file.path(site, "_landing.yml")), collapse = "\n")
  expect_match(landing, "https://github.com/someone/sitepkg", fixed = TRUE)
  # explicit arguments win
  site2 <- create_package_site(pkg,
    sync = FALSE, overwrite_config = TRUE,
    site_url = "https://other.example/", repo_url = "https://github.com/o/r"
  )
  cfg2 <- yaml::read_yaml(file.path(site2, "_quarto.yml"))
  expect_equal(cfg2$website$`site-url`, "https://other.example/")
  expect_equal(cfg2$website$`repo-url`, "https://github.com/o/r")
})

test_that("workflow pins quarto and checks sync", {
  wf <- .publish_workflow("main", "ui/www")
  expect_true(any(grepl("uses: quarto-dev/quarto-actions/setup@v2", wf, fixed = TRUE)))
  expect_true(any(grepl("version: 1.8.24", wf, fixed = TRUE)))
  expect_true(any(grepl("actions/setup-node@v5", wf, fixed = TRUE)))
  expect_true(any(grepl("node-version: 22", wf, fixed = TRUE)))
  expect_true(any(grepl("package-manager-cache: false", wf, fixed = TRUE)))
  sync <- grep("dataimago-sync --check", wf, fixed = TRUE, value = TRUE)
  expect_length(sync, 1L)
  expect_match(sync, "^\\s+npx ")
  expect_false(grepl("$(", sync, fixed = TRUE))
  blk <- paste(wf, collapse = "\n")
  expect_match(blk, "V=$(node -p \"require('./.dataimago/design.json').version\") || {", fixed = TRUE)
  expect_match(blk, "::error::missing or unreadable .dataimago/design.json", fixed = TRUE)
  expect_match(blk, "[ -n \"$V\" ] || {", fixed = TRUE)
  expect_match(blk, "::error::design.json has no version", fixed = TRUE)
  expect_match(blk, "npx --yes -p \"@dataimago/css@${V}\" dataimago-sync --check", fixed = TRUE)
  expect_false(grepl("@dataimago/css@[0-9]", blk))
  expect_equal(sum(grepl("^      - \".github/workflows/quarto-publish.yml\"$", wf)), 2L)
  i_sync <- grep("dataimago-sync --check", wf, fixed = TRUE)
  i_node <- grep("setup-node", wf, fixed = TRUE)
  i_render <- grep("quarto render", wf, fixed = TRUE)
  expect_true(i_node < i_sync && i_sync < i_render)
  expect_identical(names(formals(.publish_workflow)), c("branch", "output_path"))
  expect_false(exists(".readme_to_index"))
})

test_that("Rbuildignore entries added once", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  bi <- file.path(pkg, ".Rbuildignore")
  writeBin(charToRaw("^foo$\r\n^ui$ \r\n"), bi)
  create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  raw1 <- rawToChar(readBin(bi, "raw", file.size(bi)))
  expect_equal(raw1, "^foo$\r\n^ui$ \r\n^\\.github$\r\n")
  create_package_site(pkg, sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_equal(rawToChar(readBin(bi, "raw", file.size(bi))), raw1)
  # no file: created with both
  pkg2 <- make_site_fixture()
  create_package_site(pkg2, sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_equal(readLines(file.path(pkg2, ".Rbuildignore")), c("^ui$", "^\\.github$"))
  # no trailing newline kept as is
  pkg3 <- make_site_fixture()
  writeBin(charToRaw("^a$"), file.path(pkg3, ".Rbuildignore"))
  create_package_site(pkg3, sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_equal(rawToChar(readBin(file.path(pkg3, ".Rbuildignore"), "raw", 100)), "^a$\n^ui$\n^\\.github$")
})

test_that("output_path with unsafe characters aborts", {
  pkg <- make_site_fixture()
  expect_error(create_package_site(pkg, output_path = "my site/x", sync = FALSE), "output_path")
  expect_error(create_package_site(pkg, output_path = "a'b", sync = FALSE), "output_path")
  expect_false(dir.exists(file.path(pkg, "my site")))
})

test_that("Rbuildignore excludes the first segment of output_path", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  create_package_site(pkg, output_path = "docs/site", sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_equal(readLines(file.path(pkg, ".Rbuildignore")), c("^docs$", "^\\.github$"))
  pkg2 <- make_site_fixture()
  create_package_site(pkg2, output_path = "web.v2", sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_equal(readLines(file.path(pkg2, ".Rbuildignore")), c("^web\\.v2$", "^\\.github$"))
})

test_that("desc urls drop fragments and non-repo github paths", {
  u <- .desc_urls(list(URL = "https://github.com/orgs/foo, https://github.com/sponsors/x https://github.com/settings/y https://github.com/real/repo#readme"))
  expect_equal(u$repo_url, "https://github.com/real/repo")
  u2 <- .desc_urls(list(URL = "https://a.github.io/p/?x=1#top"))
  expect_equal(u2$site_url, "https://a.github.io/p/")
  expect_null(.desc_urls(list(URL = "https://github.com/orgs/foo"))$repo_url)
  expect_null(.desc_urls(list(URL = "https://github.com/onlyowner"))$repo_url)
})

test_that("output_path outside the package or degenerate aborts", {
  pkg <- make_site_fixture()
  for (bad in c(".", "./", "..", "../x", "a/../b", "/abs/path", "a//b")) {
    expect_error(create_package_site(pkg, output_path = bad, sync = FALSE), "output_path", info = bad)
  }
})

test_that("a leading ./ output_path is allowed", {
  skip_without_pandoc()
  skip_if_not_installed("yaml")
  pkg <- make_site_fixture()
  create_package_site(pkg, output_path = "./docs/site", sync = FALSE, site_url = "https://example.org/sitepkg/")
  expect_equal(readLines(file.path(pkg, ".Rbuildignore")), c("^docs$", "^\\.github$"))
})
