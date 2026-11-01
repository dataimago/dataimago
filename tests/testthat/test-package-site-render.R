test_that("site renders with the synced leaf", {
  require_quarto <- identical(Sys.getenv("DATAIMAGO_REQUIRE_QUARTO"), "1")
  from <- Sys.getenv("DATAIMAGO_DESIGN_FROM")
  have <- nzchar(Sys.which("quarto")) && nzchar(from)
  if (!have) {
    if (require_quarto) {
      fail("DATAIMAGO_REQUIRE_QUARTO=1 but quarto is not on PATH or DATAIMAGO_DESIGN_FROM is unset")
    }
    skip("needs quarto on PATH and DATAIMAGO_DESIGN_FROM naming a built dataimago-design checkout")
  }
  skip_if_not_installed("yaml")

  pkg <- make_site_fixture()
  site <- create_package_site(pkg, site_url = "https://example.org/sitepkg/", sync = TRUE)
  expect_true(dir.exists(file.path(site, "_extensions", "dataimago", "pkgsite")))

  out <- suppressWarnings(system2("quarto", c("render", shQuote(site)), stdout = TRUE, stderr = TRUE))
  status <- attr(out, "status") %||% 0L
  expect_equal(status, 0L, info = paste(utils::tail(out, 30), collapse = "\n"))

  index <- file.path(site, "_site", "index.html")
  expect_true(file.exists(index))
  html <- paste(readLines(index, warn = FALSE), collapse = "\n")
  for (cls in c("di-landing-intro", "di-landing-overview", "di-landing-hero", "di-landing-cards")) {
    expect_match(html, paste0("class=\"", cls, "\""), fixed = TRUE)
  }
  nav <- regmatches(html, regexpr("(?s)<nav[^>]*navbar.*?</nav>", html, perl = TRUE))
  expect_length(nav, 1L)
  nav_text <- gsub("\\s+", " ", gsub("<[^>]+>", " ", nav))
  labels <- c("Overview", "Documentation", "API", "What's new")
  nav_text <- gsub("&#39;|&rsquo;|’", "'", nav_text)
  pos <- vapply(labels, function(l) regexpr(l, nav_text, fixed = TRUE)[1], numeric(1))
  expect_true(all(pos > 0), info = nav_text)
  expect_false(is.unsorted(pos))

  for (p in c("overview", "documentation", "reference")) {
    expect_true(file.exists(file.path(site, "_site", p, "index.html")), info = p)
  }
})
