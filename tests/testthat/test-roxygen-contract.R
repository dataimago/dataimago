test_that("match.arg enum defaults are accepted and normalized", {
  parent <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(parent)

  exports <- parse_roxygen_exports(pkg_dir, verbose = FALSE)

  language <- exports$hello$params$language
  expect_equal(language$enum, c("english", "spanish", "french"))
  expect_equal(language$default, "\"english\"")
  expect_false(language$required)
})

test_that("c() defaults without match.arg are rejected", {
  parent <- withr::local_tempdir()
  pkg_dir <- fs::path(parent, "badpkg")
  fs::dir_create(fs::path(pkg_dir, "R"), recurse = TRUE)
  writeLines(c(
    "Package: badpkg",
    "Version: 0.0.1",
    "Title: Bad Fixture",
    "Description: Exercises roxygen contract failures.",
    "License: MIT",
    "Encoding: UTF-8"
  ), fs::path(pkg_dir, "DESCRIPTION"))
  writeLines(c(
    "#' Bad Enum",
    "#'",
    "#' @param grades Character. One of \"3\", \"4\", \"5\".",
    "#' @return list",
    "#' @export",
    "bad_enum <- function(grades = c(\"3\", \"4\", \"5\")) {",
    "  list(status = \"success\", data = list(grades = grades))",
    "}"
  ), fs::path(pkg_dir, "R", "bad.R"))

  expect_error(parse_roxygen_exports(pkg_dir, verbose = FALSE), "match.arg")
})

test_that("quoted examples do not become enums without an enum marker", {
  parent <- withr::local_tempdir()
  pkg_dir <- fs::path(parent, "examplepkg")
  fs::dir_create(fs::path(pkg_dir, "R"), recurse = TRUE)
  writeLines(c(
    "Package: examplepkg",
    "Version: 0.0.1",
    "Title: Example Fixture",
    "Description: Exercises quoted roxygen examples.",
    "License: MIT",
    "Encoding: UTF-8"
  ), fs::path(pkg_dir, "DESCRIPTION"))
  writeLines(c(
    "#' Compare scores",
    "#'",
    "#' @param prior_score Numeric. Earlier score, e.g. \"fall\" administration.",
    "#' @param current_score Numeric. Later score, e.g. \"spring\" administration.",
    "#' @return list",
    "#' @export",
    "compare_scores <- function(prior_score, current_score) {",
    "  list(status = \"success\", data = list(delta = current_score - prior_score))",
    "}"
  ), fs::path(pkg_dir, "R", "compare.R"))

  exports <- parse_roxygen_exports(pkg_dir, verbose = FALSE)

  expect_null(exports$compare_scores$params$prior_score$enum)
  expect_null(exports$compare_scores$params$current_score$enum)
})

test_that("scalar defaults with documented enums remain valid", {
  parent <- withr::local_tempdir()
  pkg_dir <- fs::path(parent, "scalarpkg")
  fs::dir_create(fs::path(pkg_dir, "R"), recurse = TRUE)
  writeLines(c(
    "Package: scalarpkg",
    "Version: 0.0.1",
    "Title: Scalar Fixture",
    "Description: Exercises scalar enum defaults.",
    "License: MIT",
    "Encoding: UTF-8"
  ), fs::path(pkg_dir, "DESCRIPTION"))
  writeLines(c(
    "#' Fit model",
    "#'",
    "#' @param family Character. One of \"gaussian\", \"clayton\", \"gumbel\".",
    "#' @return list",
    "#' @export",
    "fit_model <- function(family = \"gaussian\") {",
    "  family <- match.arg(family, c(\"gaussian\", \"clayton\", \"gumbel\"))",
    "  list(status = \"success\", data = list(family = family))",
    "}"
  ), fs::path(pkg_dir, "R", "fit.R"))

  exports <- parse_roxygen_exports(pkg_dir, verbose = FALSE)

  expect_equal(exports$fit_model$params$family$enum, c("gaussian", "clayton", "gumbel"))
  expect_equal(exports$fit_model$params$family$default, "\"gaussian\"")
})
