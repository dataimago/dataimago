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

# make_spec() -- the complete, schema-valid ProjectSpec fixture -- lives in
# helper-fixtures.R (shared with test-knowledge-layer.R).

test_that("ai(spec_path) writes the producer-driver artifact family", {
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(make_spec(), spec_path)

  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_true(fs::file_exists(fs::path(tmp, "data", "api", "discover.json")))
  expect_true(fs::file_exists(fs::path(
    tmp,
    "packages",
    "shared-utils",
    "src",
    "types.ts"
  )))
  expect_true(fs::file_exists(fs::path(
    tmp,
    "public",
    "api",
    "mcp-schema.json"
  )))
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

test_that("ai(spec_path) writes an AI skill bundle by default for R packages", {
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(make_spec(), spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_true("generate_ai_skill" %in% res$generators_run)
  skill_md <- res$files_written[grepl("^\\.claude/skills/.+/SKILL\\.md$", res$files_written)]
  expect_length(skill_md, 1L)
  expect_true(fs::file_exists(fs::path(tmp, skill_md)))
})

test_that("ai(spec_path) skips the AI skill bundle when aiAgent skillMode is skip", {
  spec <- make_spec()
  spec$aiAgent <- list(skillBundle = TRUE, skillMode = "skip")
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_false("generate_ai_skill" %in% res$generators_run)
  expect_false(fs::dir_exists(fs::path(tmp, ".claude", "skills")))
})

test_that("ai(spec_path) includes all generated AI skill files in files_written", {
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(make_spec(), spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  skill_files <- res$files_written[grepl("^\\.claude/skills/", res$files_written)]
  expect_true(any(grepl("/SKILL\\.md$", skill_files)))
  expect_true(any(grepl("/workflows\\.md$", skill_files)))
  expect_true(any(grepl("/examples\\.md$", skill_files)))
})

test_that("features$mcpTools = FALSE skips mcp-schema.json", {
  spec <- make_spec()
  spec$features$mcpTools <- FALSE
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_false(fs::file_exists(fs::path(
    tmp,
    "public",
    "api",
    "mcp-schema.json"
  )))
  # the always-on generators still ran
  expect_true(fs::file_exists(fs::path(tmp, "data", "api", "discover.json")))
})

test_that("aiAgent$mcpTools does not emit api_start when apiScaffolding is disabled", {
  spec <- make_spec()
  spec$features$mcpTools <- FALSE
  spec$features$apiScaffolding <- FALSE
  spec$aiAgent <- list(mcpTools = TRUE)
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  schema <- jsonlite::fromJSON(
    fs::path(tmp, "public", "api", "mcp-schema.json"),
    simplifyDataFrame = FALSE
  )
  tool_names <- vapply(schema$tools, function(t) t$name, character(1))
  expect_true("fixtpkg_hello" %in% tool_names)
  expect_false("fixtpkg_api_start" %in% tool_names)
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
  expect_false(fs::dir_exists(fs::path(tmp, "data", "api")))
})

# source$referencedRepo: an `extension` author's existing repository is the
# whole dissertation, not an R package (@dataimago/spec 0.1.0-alpha.21
# superRefine; the dissertation hub's extensionRepoKind = project).
test_that("validate_spec accepts an extension spec that references a repo instead of a package", {
  spec <- make_spec()
  spec$source$case <- "extension"
  spec$source$rPackage <- NULL
  spec$source$referencedRepo <- list(url = "https://github.com/tester/my-dissertation")
  out <- validate_spec(spec)
  expect_equal(out$source$referencedRepo$url, "https://github.com/tester/my-dissertation")
})

test_that("validate_spec still requires rPackage for extension without a referenced repo", {
  spec <- make_spec()
  spec$source$case <- "extension"
  spec$source$rPackage <- NULL
  expect_error(validate_spec(spec), "rPackage is required")
})

test_that("validate_spec allows referencedRepo only for the extension case", {
  for (case in c("retrofit", "greenfield", "no-r")) {
    spec <- make_spec()
    spec$source$case <- case
    spec$source$rPackage <- NULL
    spec$source$referencedRepo <- list(url = "https://github.com/tester/x")
    expect_error(validate_spec(spec), "only valid when source\\$case is 'extension'", info = case)
  }
})

test_that("validate_spec rejects referencedRepo together with rPackage", {
  spec <- make_spec()
  spec$source$case <- "extension"
  spec$source$referencedRepo <- list(url = "https://github.com/tester/x")
  expect_error(validate_spec(spec), "mutually exclusive")
})

test_that("validate_spec rejects a referencedRepo without a repository URL", {
  for (ref in list(list(url = ""), list(url = "not a url"), list(), "https://github.com/tester/x")) {
    spec <- make_spec()
    spec$source$case <- "extension"
    spec$source$rPackage <- NULL
    spec$source$referencedRepo <- ref
    expect_error(validate_spec(spec), "referencedRepo\\$url")
  }
})

test_that("ai(spec_path) generates nothing for a referenced repo and records the pointer", {
  spec <- make_spec()
  spec$source$case <- "extension"
  spec$source$rPackage <- NULL
  spec$source$referencedRepo <- list(url = "https://github.com/tester/my-dissertation")
  tmp <- withr::local_tempdir()
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_true(res$success)
  expect_equal(length(res$generators_run), 0)
  expect_equal(res$referenced_repo, "https://github.com/tester/my-dissertation")
  expect_false(fs::dir_exists(fs::path(tmp, "data", "api")))
})

test_that("validate_spec_schema accepts the referenced-repo shape the hub writes", {
  skip_if_not_installed("jsonvalidate")
  spec <- make_spec()
  spec$source$case <- "extension"
  spec$source$rPackage <- NULL # written as an explicit null, as the hub does
  spec$source$referencedRepo <- list(url = "https://github.com/tester/my-dissertation")
  tmp <- withr::local_tempdir()
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  res <- suppressWarnings(validate_spec_schema(spec_path))
  skip_if(is.na(res), "jsonvalidate engine unavailable for the bundled schema")
  expect_true(res)
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
  spec$features <- list(aiContext = FALSE)
  spec$generator <- NULL

  normalized <- validate_spec(spec)

  expect_false(normalized$features$apiScaffolding)
  expect_false(normalized$features$mcpTools)
  expect_equal(normalized$generator$staticExport, "full")
  expect_equal(normalized$generator$outputDir, ".")
  expect_equal(normalized$knowledge$wikiMode, "merge-seeded")
  expect_true(normalized$aiAgent$skillBundle)
  expect_false(normalized$aiAgent$mcpTools)
  expect_equal(normalized$aiAgent$skillMode, "merge-seeded")
  expect_true(normalized$aiAgent$includeWikiResources)
  expect_false(normalized$aiAgent$includePrototypeFunctions)
})

test_that("validate_spec mirrors explicit feature MCP opt-in into aiAgent defaults", {
  spec <- make_spec()

  normalized <- validate_spec(spec)

  expect_true(normalized$features$mcpTools)
  expect_true(normalized$aiAgent$mcpTools)
})

test_that("validate_spec rejects invalid static export, wiki, and aiAgent modes", {
  spec <- make_spec()
  spec$generator$staticExport <- "cartesian-everything"
  expect_error(validate_spec(spec), "staticExport")

  spec <- make_spec()
  spec$knowledge <- list(wikiMode = "clobber")
  expect_error(validate_spec(spec), "wikiMode")

  spec <- make_spec()
  spec$aiAgent <- list(skillMode = "clobber")
  expect_error(validate_spec(spec), "skillMode")
})

test_that("generator$staticExport = 'off' skips static API export", {
  spec <- make_spec()
  spec$features$mcpTools <- FALSE
  spec$features$apiScaffolding <- FALSE
  spec$generator$staticExport <- "off"
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_false("export_static_api" %in% res$generators_run)
  expect_false(fs::dir_exists(fs::path(tmp, "data", "api")))
  expect_true(fs::file_exists(fs::path(
    tmp,
    "packages",
    "shared-utils",
    "src",
    "types.ts"
  )))
})

test_that("generator$staticExport = 'discover-only' omits endpoint fixtures", {
  spec <- make_spec()
  spec$features$mcpTools <- FALSE
  spec$features$apiScaffolding <- FALSE
  spec$generator$staticExport <- "discover-only"
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_true(fs::file_exists(fs::path(tmp, "data", "api", "discover.json")))
  expect_true(fs::file_exists(fs::path(tmp, "data", "api", "openapi.json")))
  expect_false(fs::dir_exists(fs::path(tmp, "data", "api", "hello")))
})

test_that("ai() never writes a store artifact into public/, which NextJS serves verbatim", {
  spec <- make_spec()
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  # `public/api/mcp-schema.json` is the one deliberate resident: an agent-facing
  # contract document, not a store artifact, and nothing in the manifest lists it.
  # Anything else under public/api would answer at GET /api/<name>.json, bypassing
  # the driver, the manifest gate, and the sha256 check.
  public_api <- fs::path(tmp, "public", "api")
  leaked <- character(0)
  if (fs::dir_exists(public_api)) {
    leaked <- setdiff(
      basename(fs::dir_ls(public_api, recurse = TRUE, type = "file")),
      "mcp-schema.json"
    )
  }
  expect_identical(leaked, character(0))

  # And the store really is where the driver's staticRoot() looks for it.
  expect_true(fs::file_exists(fs::path(tmp, "data", "api", "store.manifest.json")))
})

test_that("validate_spec accepts 'greenfield' with the everything-on feature stance", {
  spec <- make_spec()
  spec$source$case <- "greenfield"
  spec$features <- list(aiContext = FALSE)

  normalized <- validate_spec(spec)

  # Retrofit gating must NOT apply to greenfield.
  expect_true(normalized$features$mcpTools)
  expect_true(normalized$features$apiScaffolding)
})

test_that("ai(spec_path) aborts honestly for 'greenfield' (not yet implemented)", {
  spec <- make_spec()
  spec$source$case <- "greenfield"
  tmp <- withr::local_tempdir()
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  expect_error(
    suppressWarnings(ai(spec_path = spec_path, verbose = FALSE)),
    "greenfield"
  )
})

test_that("validate_spec requires exactly one vertical (superRefine parity)", {
  spec <- make_spec()
  spec$vertical <- NULL
  expect_error(validate_spec(spec), "vertical")

  spec <- make_spec()
  spec$vertical$dissertation <- list(institution = list(name = "X"))
  expect_error(validate_spec(spec), "vertical")
})

test_that("validate_spec_schema validates a well-formed spec against the bundled schema", {
  skip_if_not_installed("jsonvalidate")
  tmp <- withr::local_tempdir()
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(make_spec(), spec_path)

  res <- suppressWarnings(validate_spec_schema(spec_path))
  skip_if(is.na(res), "jsonvalidate engine unavailable for the bundled schema")
  expect_true(res)
})

test_that("validate_spec_schema rejects a schema-invalid spec, naming the violating path", {
  skip_if_not_installed("jsonvalidate")
  tmp <- withr::local_tempdir()

  # Prove the engine is live on this machine first (valid twin passes).
  twin <- fs::path(tmp, "valid.yaml")
  yaml::write_yaml(make_spec(), twin)
  live <- suppressWarnings(validate_spec_schema(twin))
  skip_if(is.na(live), "jsonvalidate engine unavailable for the bundled schema")

  spec <- make_spec()
  spec$source$case <- "bogus-case"
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  expect_error(validate_spec_schema(spec_path), "case")
})

test_that("validate_spec_schema warns on (and tolerates) a legacy top-level knowledge block", {
  skip_if_not_installed("jsonvalidate")
  tmp <- withr::local_tempdir()

  twin <- fs::path(tmp, "valid.yaml")
  yaml::write_yaml(make_spec(), twin)
  live <- suppressWarnings(validate_spec_schema(twin))
  skip_if(is.na(live), "jsonvalidate engine unavailable for the bundled schema")

  spec <- make_spec()
  spec$knowledge <- list(wikiMode = "skip")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  expect_warning(res <- validate_spec_schema(spec_path), "knowledge")
  expect_true(res)
})

test_that("knowledge$wikiMode = 'skip' skips wiki and KNOWLEDGE scaffolding", {
  spec <- make_spec()
  spec$features$mcpTools <- FALSE
  spec$features$apiScaffolding <- FALSE
  spec$knowledge <- list(domainType = "framework", wikiMode = "skip")
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_false("bootstrap_wiki" %in% res$generators_run)
  expect_false("generate_knowledge_md" %in% res$generators_run)
  expect_false(fs::dir_exists(fs::path(tmp, "wiki")))
  expect_false(fs::file_exists(fs::path(tmp, "KNOWLEDGE.md")))
})

# ---- quartoBuild dispatches to create_package_site(); generator.siteMode ----

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

test_that("quartoBuild dispatches to create_package_site", {
  tmp <- withr::local_tempdir()
  spec_path <- site_spec_fixture(tmp)
  calls <- list()
  testthat::local_mocked_bindings(
    create_package_site = function(...) {
      calls[[length(calls) + 1L]] <<- list(...)
      invisible(NULL)
    }
  )
  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))
  expect_length(calls, 1L)
  expect_equal(calls[[1]]$output_path, "ui/www")
  expect_false(calls[[1]]$overwrite_config)
  expect_true(calls[[1]]$sync)
  expect_match(
    as.character(calls[[1]]$package_path),
    "packages/r-packages/fixtpkg$"
  )
  expect_true("create_package_site" %in% res$generators_run)
})

test_that("quartoBuild = FALSE does not call create_package_site", {
  tmp <- withr::local_tempdir()
  spec_path <- site_spec_fixture(tmp, quarto = FALSE)
  called <- FALSE
  testthat::local_mocked_bindings(
    create_package_site = function(...) called <<- TRUE
  )
  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))
  expect_false(called)
})

test_that("conflicting quartoRoot aborts", {
  spec <- make_spec()
  spec$source$rPackage$quartoRoot <- "ui/www"
  spec$vertical$rpkg$integration <- list(quartoRoot = "docs/site")
  expect_error(validate_spec(spec), "ui/www.*docs/site|docs/site.*ui/www")
  spec$vertical$rpkg$integration$quartoRoot <- "ui/www"
  expect_no_error(validate_spec(spec))
})

test_that("quartoRoot falls back to integration then ui/www", {
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec <- make_spec()
  spec$source$rPackage$quartoRoot <- NULL
  spec$features$quartoBuild <- TRUE
  spec$vertical$rpkg$integration <- list(quartoRoot = "docs/site")
  spec$features$aiContext <- FALSE
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)
  got <- NULL
  testthat::local_mocked_bindings(
    create_package_site = function(...) got <<- list(...)$output_path
  )
  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))
  expect_equal(got, "docs/site")
})

test_that("curated site refused under bootstrap", {
  tmp <- withr::local_tempdir()
  spec_path <- site_spec_fixture(tmp)
  www <- fs::path(tmp, "packages", "r-packages", "fixtpkg", "ui", "www")
  fs::dir_create(www)
  writeLines(c("project:", "  type: website"), fs::path(www, "_quarto.yml"))
  called <- FALSE
  testthat::local_mocked_bindings(
    create_package_site = function(...) called <<- TRUE
  )
  expect_error(
    suppressWarnings(ai(spec_path = spec_path, verbose = FALSE)),
    "merge-seeded"
  )
  expect_false(called)
  expect_equal(
    readLines(fs::path(www, "_quarto.yml"))[1],
    "project:"
  )
})

test_that("generated site is re-runnable under bootstrap", {
  tmp <- withr::local_tempdir()
  spec_path <- site_spec_fixture(tmp)
  www <- fs::path(tmp, "packages", "r-packages", "fixtpkg", "ui", "www")
  fs::dir_create(www)
  writeLines(
    "# Generated by dataimago::create_package_site(). Re-running keeps edits.",
    fs::path(www, "_quarto.yml")
  )
  called <- FALSE
  testthat::local_mocked_bindings(
    create_package_site = function(...) called <<- TRUE
  )
  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))
  expect_true(called)
})

test_that("merge-seeded runs over a curated site without overwriting config", {
  tmp <- withr::local_tempdir()
  spec_path <- site_spec_fixture(tmp, "merge-seeded")
  www <- fs::path(tmp, "packages", "r-packages", "fixtpkg", "ui", "www")
  fs::dir_create(www)
  writeLines("project:", fs::path(www, "_quarto.yml"))
  got <- NULL
  testthat::local_mocked_bindings(
    create_package_site = function(...) got <<- list(...)
  )
  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))
  expect_false(is.null(got))
  expect_false(got$overwrite_config)
})

test_that("skip does nothing", {
  tmp <- withr::local_tempdir()
  spec_path <- site_spec_fixture(tmp, "skip")
  called <- FALSE
  testthat::local_mocked_bindings(
    create_package_site = function(...) called <<- TRUE
  )
  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))
  expect_false(called)
  expect_false("create_package_site" %in% res$generators_run)
})

test_that("schema accepts siteMode", {
  skip_if_not_installed("jsonvalidate")
  tmp <- withr::local_tempdir()
  for (mode in c("bootstrap", "merge-seeded", "skip")) {
    spec <- make_spec()
    spec$generator$siteMode <- mode
    p <- fs::path(tmp, paste0(mode, ".yaml"))
    yaml::write_yaml(spec, p)
    expect_no_error(validate_spec_schema(p))
  }
  spec <- make_spec()
  spec$generator$siteMode <- "bogus"
  p <- fs::path(tmp, "bogus.yaml")
  yaml::write_yaml(spec, p)
  expect_error(validate_spec_schema(p))
})

# ---- B6 fix round 1 ----

test_that("spec_site_urls splits every URL like DESCRIPTION", {
  e <- dataimago:::spec_site_urls
  r <- e(list(url = "https://cran.r-project.org/package=x"))
  expect_null(r$site_url)
  expect_null(r$repo_url)
  r <- e(list(url = c("https://o.github.io/p/", "https://github.com/o/p")))
  expect_equal(r$site_url, "https://o.github.io/p/")
  expect_equal(r$repo_url, "https://github.com/o/p")
  r <- e(list(url = list("https://x.org", "https://github.com/o/p/tree/main/sub.git")))
  expect_equal(r$repo_url, "https://github.com/o/p")
  r <- e(list(url = "https://github.com/orgs/o, https://github.com/o/p, https://o.github.io/p"))
  expect_equal(r$repo_url, "https://github.com/o/p")
  expect_equal(r$site_url, "https://o.github.io/p")
  r <- e(list(bugReports = "https://github.com/o/p/issues"))
  expect_equal(r$repo_url, "https://github.com/o/p")
  r <- e(list(url = "https://github.com/a/b", bugReports = "https://github.com/o/p/issues"))
  expect_equal(r$repo_url, "https://github.com/a/b")
})

test_that("quartoRoot is normalised before comparing", {
  spec <- make_spec()
  spec$source$rPackage$quartoRoot <- "ui/www/"
  spec$vertical$rpkg$integration <- list(quartoRoot = "./ui/www")
  expect_no_error(validate_spec(spec))
  expect_equal(dataimago:::spec_quarto_root(spec), "ui/www")
})

curated_refused <- function(lines, raw = NULL) {
  tmp <- withr::local_tempdir()
  spec_path <- site_spec_fixture(tmp)
  www <- fs::path(tmp, "packages", "r-packages", "fixtpkg", "ui", "www")
  fs::dir_create(www)
  if (is.null(raw)) writeLines(lines, fs::path(www, "_quarto.yml"))
  else writeBin(raw, fs::path(www, "_quarto.yml"))
  called <- FALSE
  testthat::local_mocked_bindings(create_package_site = function(...) called <<- TRUE)
  err <- tryCatch(
    suppressWarnings(ai(spec_path = spec_path, verbose = FALSE)),
    error = function(e) e
  )
  inherits(err, "error") && !called
}

test_that("header check is strict", {
  hdr <- "# Generated by dataimago::create_package_site(). Re-running keeps edits."
  expect_true(curated_refused(c("", hdr)))
  expect_true(curated_refused("# Generated by dataimago::create_package_site"))
  expect_true(curated_refused(character(0)))
  expect_true(curated_refused("# NOT Generated by dataimago::create_package_site()"))
  expect_false(curated_refused(NULL, raw = c(as.raw(c(0xef, 0xbb, 0xbf)), charToRaw(paste0(hdr, "\n")))))
})

test_that("siteMode must be a single string", {
  spec <- make_spec()
  spec$generator$siteMode <- c("skip", "bootstrap")
  expect_error(validate_spec(spec), "siteMode")
  spec$generator$siteMode <- list()
  expect_error(validate_spec(spec), "siteMode")
})

test_that("omitting features still dispatches (default quartoBuild TRUE)", {
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec <- make_spec()
  spec$features <- list(aiContext = FALSE)
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)
  called <- FALSE
  testthat::local_mocked_bindings(create_package_site = function(...) called <<- TRUE)
  suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))
  expect_true(called)
})
