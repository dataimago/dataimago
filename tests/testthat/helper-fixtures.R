# Shared test fixtures. testthat sources helper-*.R before any test file, so
# `make_fixture_pkg()` and `make_spec()` are available to every test
# (test-phase-2e-generators.R, test-ai-spec.R, test-knowledge-layer.R, ...).

# A complete, valid ProjectSpec as an R list. Tests mutate fields directly
# before writing, so nested merges aren't needed. Kept fully JSON-Schema-valid
# (complete metadata + exactly one vertical) so ai(spec_path) tests pass the
# bundled-schema gate when jsonvalidate is installed.
make_spec <- function() {
  list(
    apiVersion = "dataimago.ai/v1alpha1",
    kind = "ProjectSpec",
    metadata = list(
      name = "test-project",
      vertical = "rpkg",
      generatedBy = "test-suite",
      generatedAt = "2026-07-05T12:00:00Z",
      specVersion = 1L
    ),
    user = list(
      name = "Tester",
      email = "t@example.com",
      githubUsername = "tester"
    ),
    project = list(title = "Test", description = "A test project"),
    source = list(
      case = "retrofit",
      rPackage = list(
        name = "fixtpkg",
        submoduleUrl = "https://github.com/x/fixtpkg",
        submodulePath = "packages/r-packages/fixtpkg",
        quartoRoot = "ui/www"
      )
    ),
    vertical = list(
      rpkg = list(
        package = list(
          name = "fixtpkg",
          title = "Fixture Package for Generator Tests",
          description = "Synthetic package used by the test suite."
        )
      )
    ),
    features = list(
      quartoBuild = FALSE,
      thesisPdf = TRUE,
      mcpTools = TRUE,
      aiContext = TRUE,
      apiScaffolding = TRUE
    ),
    generator = list(outputDir = ".")
  )
}

#' Build a synthetic R package under `parent_dir`.
#'
#' The caller must supply a parent directory whose lifetime spans the test;
#' pass `withr::local_tempdir()` inside the test body (not as a default
#' argument here — withr scopes to the callee frame and would delete the
#' tempdir as soon as this helper returns).
make_fixture_pkg <- function(parent_dir, pkg_name = "fixtpkg") {
  pkg_dir <- fs::path(parent_dir, pkg_name)
  fs::dir_create(fs::path(pkg_dir, "R"), recurse = TRUE)

  writeLines(c(
    paste0("Package: ", pkg_name),
    "Version: 1.2.3",
    "Title: Fixture package for generator tests",
    "Description: Synthetic package used by the test suite.",
    "License: MIT",
    "Encoding: UTF-8"
  ), fs::path(pkg_dir, "DESCRIPTION"))

  writeLines(c(
    "#' Greet in a Language",
    "#'",
    "#' @description Returns a canned greeting for demonstration purposes.",
    "#' @param language Character. One of \"english\", \"spanish\", \"french\".",
    "#' @return list with status, data, request.",
    "#' @export",
    "hello <- function(language = c(\"english\", \"spanish\", \"french\")) {",
    "  language <- match.arg(language)",
    "  greeting <- switch(language,",
    "    english = \"Hello\",",
    "    spanish = \"Hola\",",
    "    french  = \"Bonjour\"",
    "  )",
    "  list(",
    "    status = \"success\",",
    "    data = list(greeting = greeting, language = language),",
    "    request = list(language = language)",
    "  )",
    "}",
    "",
    "#' Pair summarizer (no params)",
    "#'",
    "#' @description A stub function with no parameters, used to exercise the",
    "#'   default.json path.",
    "#' @return list",
    "#' @export",
    "summarize <- function() {",
    "  list(status = \"success\", data = list(count = 0L), request = list())",
    "}"
  ), fs::path(pkg_dir, "R", "functions.R"))

  pkg_dir
}

# A schema-valid spec file at <tmp>/dataimago-spec.yaml with quartoBuild on (or off) and
# an optional generator.siteMode; returns its path.
site_spec_fixture <- function(tmp, site_mode = NULL, quarto = TRUE) {
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec <- make_spec()
  spec$features$quartoBuild <- quarto
  spec$features$aiContext <- FALSE
  if (!is.null(site_mode)) spec$generator$siteMode <- site_mode
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)
  spec_path
}

# The published spec schema does not carry generator.siteMode yet; schema-validated spec
# files that set it are rejected until @dataimago/spec adds it. Skips automatically once
# the bundled schema gains the property.
skip_if_schema_lacks_sitemode <- function() {
  schema <- jsonlite::read_json(system.file("schemas", "dataimago-spec.v1alpha1.schema.json", package = "dataimago"))
  has_site_mode <- !is.null(schema$properties$generator$properties$siteMode)
  testthat::skip_if_not(
    has_site_mode,
    "bundled spec schema has no generator.siteMode yet (wi-20261101-spec-generator-sitemode)"
  )
}

# TRUE when ai() refuses the curated _quarto.yml written from `lines`
# (or `raw` bytes) and never calls create_package_site().
curated_refused <- function(lines, raw = NULL) {
  tmp <- withr::local_tempdir()
  spec_path <- site_spec_fixture(tmp)
  www <- fs::path(tmp, "packages", "r-packages", "fixtpkg", "ui", "www")
  fs::dir_create(www)
  if (is.null(raw)) {
    writeLines(lines, fs::path(www, "_quarto.yml"))
  } else {
    writeBin(raw, fs::path(www, "_quarto.yml"))
  }
  called <- FALSE
  testthat::local_mocked_bindings(create_package_site = function(...) called <<- TRUE)
  err <- tryCatch(
    suppressWarnings(ai(spec_path = spec_path, verbose = FALSE)),
    error = function(e) e
  )
  inherits(err, "error") && !called
}
