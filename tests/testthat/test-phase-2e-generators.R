# ============================================================================
# test-phase-2e-generators.R
# ----------------------------------------------------------------------------
# Verifies that the Phase 2e contract holds for the rpkg generators:
#
#   (a) export_static_api() writes discover.json + openapi.json at the root
#       of output_dir, and endpoint files use values-only filenames
#       (matching StaticProducerDriver.filenameFor in
#       packages/shared-utils/src/producers/static-driver.ts).
#   (b) generate_shared_utils() emits a single-path api-client.ts that
#       targets the NextJS API route tree and no longer branches on
#       NEXT_PUBLIC_API_MODE.
#   (c) generate_mcp_tools() emits implementation.endpoint = "/api/data/<endpoint>"
#       and implementation.producer metadata.
#   (d) generate_self_mcp() emits implementation.endpoint = "/api/mcp/<tool>"
#       for each dataimago-own tool.
#   (e) generate_api_scaffolding() refuses to write into a directory that
#       looks like the template's NextJS API route tree.
#
# Shared fixture: a minimal synthetic R package written to a tempdir.
# ============================================================================

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
    "Title: Fixture package for Phase 2e generator tests",
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


# ============================================================================
# (a) export_static_api() file layout and naming
# ============================================================================

test_that("export_static_api() writes discover.json + openapi.json at the root", {
  parent <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(parent)
  out <- withr::local_tempdir()

  # NOTE: the call may fail if `fixtpkg::hello` is not installed; we only
  # assert the file *shapes* that don't depend on execution success.
  suppressWarnings(try(
    export_static_api(
      pkg_path = pkg_dir,
      output_dir = out,
      verbose = FALSE
    ),
    silent = TRUE
  ))

  expect_true(fs::file_exists(fs::path(out, "discover.json")),
              info = "Phase 2e requires discover.json at the root")
  expect_true(fs::file_exists(fs::path(out, "openapi.json")),
              info = "Phase 2e requires openapi.json at the root")
  expect_false(fs::file_exists(fs::path(out, "manifest.json")),
               info = "legacy manifest.json must not be emitted alongside discover.json")
  expect_false(fs::dir_exists(fs::path(out, "discover")),
               info = "legacy discover/ directory must not be emitted")
})


test_that("discover.json carries the Phase-2e manifest shape", {
  parent <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(parent)
  out <- withr::local_tempdir()
  suppressWarnings(try(
    export_static_api(pkg_path = pkg_dir, output_dir = out, verbose = FALSE),
    silent = TRUE
  ))

  manifest <- jsonlite::fromJSON(
    fs::path(out, "discover.json"),
    simplifyDataFrame = FALSE
  )

  expect_equal(manifest$package_name, "fixtpkg")
  expect_equal(manifest$version, "1.2.3")
  expect_equal(manifest$openapi_url, "/api/openapi.json")
  expect_true(is.list(manifest$endpoints))
  expect_gt(length(manifest$endpoints), 0L)

  names_of <- vapply(manifest$endpoints, function(e) e$name, character(1))
  expect_true("hello" %in% names_of)
  hello <- manifest$endpoints[[which(names_of == "hello")]]
  expect_equal(hello$path, "/hello")
  expect_equal(hello$method, "GET")
  expect_true(any(vapply(hello$params, function(p) p$name == "language",
                         logical(1))))
})


test_that("combo_to_filename() emits values-only filenames matching the driver", {
  expect_equal(combo_to_filename(list()), "default.json")
  expect_equal(combo_to_filename(list(language = "English")),
               "english.json")
  expect_equal(combo_to_filename(list(a = "Foo Bar", b = "baz")),
               "foo_bar_baz.json")
  expect_equal(combo_to_filename(list(a = "A/B", b = "C?D")),
               "a_b_c_d.json")
  # Empty values are dropped, per the driver contract.
  expect_equal(combo_to_filename(list(a = "", b = "keep")),
               "keep.json")
})


# ============================================================================
# (b) generate_shared_utils() emits the single-path client
# ============================================================================

test_that("generated api-client.ts is single-path and calls /api/data/", {
  parent <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(parent)
  out <- withr::local_tempdir()

  generate_shared_utils(
    pkg_path = pkg_dir,
    output_dir = out,
    verbose = FALSE
  )

  client_path <- fs::path(out, "api-client.ts")
  expect_true(fs::file_exists(client_path))
  client_src <- paste(readLines(client_path, warn = FALSE), collapse = "\n")

  expect_match(client_src, "/api/data/", fixed = TRUE,
               info = "client must target the NextJS route tree")
  expect_match(client_src, "/api/discover", fixed = TRUE)
  expect_match(client_src, "/api/openapi.json", fixed = TRUE)
  expect_false(grepl("NEXT_PUBLIC_API_MODE", client_src, fixed = TRUE),
               info = "Phase 2e client must not branch on NEXT_PUBLIC_API_MODE")
  expect_false(grepl("staticRequest", client_src, fixed = TRUE),
               info = "dual-mode staticRequest method is removed")
  expect_false(grepl("liveRequest", client_src, fixed = TRUE),
               info = "dual-mode liveRequest method is removed")
})


test_that("generated types.ts marks ApiMode/ApiConfig as deprecated", {
  parent <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(parent)
  out <- withr::local_tempdir()

  generate_shared_utils(
    pkg_path = pkg_dir,
    output_dir = out,
    verbose = FALSE
  )

  types_src <- paste(readLines(fs::path(out, "types.ts"), warn = FALSE),
                     collapse = "\n")
  # Both kept, both deprecated.
  expect_match(types_src, "export type ApiMode", fixed = TRUE)
  expect_match(types_src, "@deprecated", fixed = TRUE)
})


# ============================================================================
# (c) generate_mcp_tools() carries endpoint + producer metadata
# ============================================================================

test_that("MCP tools reference /api/data/<endpoint> and a producer hint", {
  parent <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(parent)
  out <- withr::local_tempfile(fileext = ".json")

  generate_mcp_tools(
    pkg_path = pkg_dir,
    output_path = out,
    include_api_tools = TRUE,
    verbose = FALSE
  )

  schema <- jsonlite::fromJSON(out, simplifyDataFrame = FALSE)
  tool_names <- vapply(schema$tools, function(t) t$name, character(1))
  hello_idx <- which(tool_names == "fixtpkg_hello")
  expect_length(hello_idx, 1L)
  hello_tool <- schema$tools[[hello_idx]]

  expect_equal(hello_tool$implementation$type, "nextjs_api")
  expect_equal(hello_tool$implementation$endpoint, "/api/data/hello")
  expect_equal(hello_tool$implementation$method, "GET")
  expect_equal(hello_tool$implementation$producer, "default")
  expect_equal(hello_tool$implementation$r_function, "hello")
  expect_equal(hello_tool$implementation$r_package, "fixtpkg")

  # API-start tool carries producer = "live"
  api_start_idx <- which(tool_names == "fixtpkg_api_start")
  expect_length(api_start_idx, 1L)
  expect_equal(schema$tools[[api_start_idx]]$implementation$producer, "live")
})


# ============================================================================
# (d) generate_self_mcp() emits /api/mcp/<tool> endpoints
# ============================================================================

test_that("self-MCP tools reference /api/mcp/<tool> endpoints", {
  out <- withr::local_tempfile(fileext = ".json")

  generate_self_mcp(output_path = out, verbose = FALSE)

  schema <- jsonlite::fromJSON(out, simplifyDataFrame = FALSE)
  by_name <- setNames(schema$tools, vapply(schema$tools, function(t) t$name,
                                           character(1)))

  for (tool in c("dataimago_scaffold", "dataimago_build", "dataimago_status")) {
    expect_true(tool %in% names(by_name), info = paste("missing tool:", tool))
    impl <- by_name[[tool]]$implementation
    expect_equal(impl$endpoint, paste0("/api/mcp/", tool))
    expect_equal(impl$producer, "default")
    expect_equal(impl$type, "nextjs_mcp")
  }
})


# ============================================================================
# (e) generate_api_scaffolding() refuses the template API tree
# ============================================================================

test_that("generate_api_scaffolding() refuses to write into src/app/api/**", {
  parent <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(parent)
  forbidden <- fs::path(withr::local_tempdir(), "apps", "template", "src", "app", "api")

  expect_error(
    generate_api_scaffolding(
      pkg_path = pkg_dir,
      output_dir = forbidden,
      verbose = FALSE
    ),
    regexp = "src/app/api"
  )
})


test_that("generate_api_scaffolding() still writes into a normal R/ directory", {
  parent <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(parent)
  out <- fs::path(withr::local_tempdir(), "project", "R")

  result <- generate_api_scaffolding(
    pkg_path = pkg_dir,
    output_dir = out,
    verbose = FALSE
  )

  expect_true(fs::file_exists(fs::path(out, "api.R")))
  expect_true("hello" %in% result$endpoints_generated)
})
