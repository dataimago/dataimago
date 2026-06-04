# ============================================================================
# test-ai-spec.R
# ----------------------------------------------------------------------------
# Verifies the D.2.3.b spec-driven entry point:
#
#   ai(spec_path = "dataimago-spec.yaml")
#     reads + validates the project spec, locates the R package it points at,
#     and runs the producer-driver generators gated by `features`, writing the
#     integration-contract artifact family (discover.json, types.ts,
#     mcp-schema.json) under generator.outputDir.
#
# Uses make_fixture_pkg() from helper-fixtures.R + withr::local_tempdir().
# Fixture setup is inlined in each test_that() block (rather than a shared
# closure) so object_usage_linter doesn't flag the helper as an undefined
# global -- matching the convention in test-phase-2e-generators.R.
# ============================================================================

# A complete, valid spec as an R list. Tests mutate fields directly before
# writing, so nested merges aren't needed.
make_spec <- function() {
  list(
    apiVersion = "dataimago.ai/v1alpha1",
    kind = "ProjectSpec",
    metadata = list(name = "test-project"),
    user = list(name = "Tester", email = "t@example.com", githubUsername = "tester"),
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
    features = list(
      quartoBuild = TRUE, thesisPdf = TRUE, mcpTools = TRUE,
      aiContext = TRUE, apiScaffolding = TRUE
    ),
    generator = list(outputDir = ".")
  )
}

test_that("ai(spec_path) writes the producer-driver artifact family", {
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(make_spec(), spec_path)

  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_true(fs::file_exists(fs::path(tmp, "public", "api", "discover.json")))
  expect_true(fs::file_exists(fs::path(tmp, "packages", "shared-utils", "src", "types.ts")))
  expect_true(fs::file_exists(fs::path(tmp, "public", "api", "mcp-schema.json")))
})

test_that("ai(spec_path) returns a spec-mode result carrying the project name", {
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(make_spec(), spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_equal(res$mode, "spec")
  expect_equal(res$project_name, "test-project")
  expect_true(res$success)
  expect_true("export_static_api" %in% res$generators_run)
})

test_that("features$mcpTools = FALSE skips mcp-schema.json", {
  spec <- make_spec()
  spec$features$mcpTools <- FALSE
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_false(fs::file_exists(fs::path(tmp, "public", "api", "mcp-schema.json")))
  # the always-on generators still ran
  expect_true(fs::file_exists(fs::path(tmp, "public", "api", "discover.json")))
})

test_that("source$case = 'no-r' is a no-op for the producer-driver family", {
  spec <- make_spec()
  spec$source$case <- "no-r"
  spec$source$rPackage <- NULL
  tmp <- withr::local_tempdir()
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_equal(length(res$generators_run), 0)
  expect_false(fs::dir_exists(fs::path(tmp, "public", "api")))
})

test_that("validate_spec rejects a non-dataimago apiVersion", {
  spec <- make_spec()
  spec$apiVersion <- "example.com/v1"
  expect_error(validate_spec(spec), "apiVersion")
})

test_that("validate_spec rejects a missing metadata$name", {
  spec <- make_spec()
  spec$metadata$name <- NULL
  expect_error(validate_spec(spec), "name")
})

test_that("validate_spec rejects 'no-r' carrying an rPackage", {
  spec <- make_spec()
  spec$source$case <- "no-r" # rPackage still present -> invariant violation
  expect_error(validate_spec(spec), "no-r")
})

test_that("validate_spec applies feature + generator defaults when absent", {
  spec <- make_spec()
  spec$features <- NULL
  spec$generator <- NULL

  normalized <- validate_spec(spec)

  expect_true(normalized$features$apiScaffolding)
  expect_true(normalized$features$mcpTools)
  expect_equal(normalized$generator$outputDir, ".")
})
