# ============================================================================
# test-store-manifest.R
# ----------------------------------------------------------------------------
# export_static_api() emits `store.manifest.json` (schema `dataimago.store.v1`),
# the contract read by `loadStoreManifest()` in @dataimago/shared-utils/store.
#
# The manifest is what turns a directory of JSON into a *store*: it answers
# provenance (which build produced this), integrity (per-artifact sha256), and
# disclosure (classification). The reader refuses to serve any file the manifest
# does not list, and verifies the hash before returning bytes -- so these
# assertions are the writer's half of that contract.
#
# The hashes are recomputed here from the bytes on disk rather than trusted, and
# the params-array assertion reads the raw JSON, because `fromJSON()` would hide
# exactly the auto_unbox bug it exists to catch.
# ============================================================================

# `make_fixture_pkg()` lives in tests/testthat/helper-fixtures.R.

export_fixture <- function(out, ...) {
  parent <- withr::local_tempdir()
  # `make_fixture_pkg()` is defined in helper-fixtures.R, which testthat sources
  # before every test file. lintr analyses this file in isolation and cannot see it.
  pkg_dir <- make_fixture_pkg(parent) # nolint: object_usage_linter.
  suppressWarnings(try(
    export_static_api(pkg_path = pkg_dir, output_dir = out, verbose = FALSE, ...),
    silent = TRUE
  ))
  invisible(out)
}

read_manifest <- function(out) {
  jsonlite::fromJSON(
    fs::path(out, "store.manifest.json"),
    simplifyVector = FALSE
  )
}


test_that("export_static_api() writes a dataimago.store.v1 manifest at the root", {
  out <- withr::local_tempdir()
  export_fixture(out)

  expect_true(fs::file_exists(fs::path(out, "store.manifest.json")))

  m <- read_manifest(out)
  expect_identical(m$schema_version, "dataimago.store.v1")
  expect_identical(m$store$kind, "static")
  expect_identical(m$store$id, "fixtpkg")
  expect_identical(m$store$domain_schema, "fixtpkg") # defaults to the store id
  expect_true(is.character(m$provenance$built_at))
})


test_that("domain_schema is overridable", {
  out <- withr::local_tempdir()
  export_fixture(out, domain_schema = "dissertation")
  expect_identical(read_manifest(out)$store$domain_schema, "dissertation")
})


test_that("every artifact's sha256 matches the bytes actually on disk", {
  out <- withr::local_tempdir()
  export_fixture(out)
  m <- read_manifest(out)

  expect_gt(length(m$artifacts), 0)

  for (a in m$artifacts) {
    full <- fs::path(out, a$path)
    expect_true(fs::file_exists(full), info = paste("listed but missing:", a$path))
    # Recomputed, not copied from the writer: `writeLines()` appends a newline,
    # so a manifest that hashed the JSON string instead of the file would pass
    # every other assertion here and fail in production.
    expect_identical(
      a$sha256,
      digest::digest(full, algo = "sha256", file = TRUE),
      info = paste("sha256 mismatch for", a$path)
    )
  }
})


test_that("discover.json and openapi.json are listed as metadata", {
  out <- withr::local_tempdir()
  export_fixture(out)
  m <- read_manifest(out)

  by_path <- vapply(m$artifacts, function(a) a$path, character(1))
  classes <- vapply(m$artifacts, function(a) a$classification, character(1))

  expect_true("discover.json" %in% by_path)
  expect_true("openapi.json" %in% by_path)
  expect_identical(classes[by_path == "discover.json"], "metadata")
  expect_identical(classes[by_path == "openapi.json"], "metadata")
})


test_that("no artifact is ever classified restricted, and endpoint payloads are aggregate", {
  out <- withr::local_tempdir()
  export_fixture(out)
  m <- read_manifest(out)

  classes <- vapply(m$artifacts, function(a) a$classification, character(1))
  paths <- vapply(m$artifacts, function(a) a$path, character(1))

  # Invariant 7: restricted never crosses the store boundary. This writer
  # cannot even express it.
  expect_false(any(classes == "restricted"))
  expect_true(all(classes %in% c("aggregate", "metadata")))

  endpoint_files <- grepl("/", paths, fixed = TRUE)
  if (any(endpoint_files)) {
    expect_true(all(classes[endpoint_files] == "aggregate"))
  }
})


test_that("a stale file from a previous export is not listed, and so is unreachable", {
  out <- withr::local_tempdir()
  export_fixture(out)

  # Simulate an artifact left behind by an earlier build.
  writeLines('{"stale":true}', fs::path(out, "leftover.json"))
  export_fixture(out)

  m <- read_manifest(out)
  paths <- vapply(m$artifacts, function(a) a$path, character(1))

  expect_true(fs::file_exists(fs::path(out, "leftover.json")))
  expect_false("leftover.json" %in% paths)
})


test_that("capabilities are closed by default", {
  out <- withr::local_tempdir()
  export_fixture(out)
  caps <- read_manifest(out)$capabilities

  # A static JSON store has no SQL engine. rawSql is opt-in everywhere, and
  # un-optable here.
  expect_false(caps$rawSql)
  expect_identical(caps$maxRows, 5000L)
  expect_true(is.list(caps$namedQueries))
})


test_that("disclosure never offers restricted", {
  out <- withr::local_tempdir()
  export_fixture(out)
  d <- read_manifest(out)$disclosure

  expect_setequal(unlist(d$api), c("aggregate", "metadata"))
  expect_setequal(unlist(d$mcp), c("aggregate", "metadata"))
})


test_that("namedQueries params is a JSON array even when there is one param", {
  out <- withr::local_tempdir()
  export_fixture(out)

  # Read the raw text. `fromJSON()` would happily turn "year" into a length-1
  # character vector and hide the auto_unbox bug this guards against: jsonlite
  # unboxes `c("year")` into the bare string `"year"` unless it is a list.
  raw <- paste(readLines(fs::path(out, "store.manifest.json"), warn = FALSE), collapse = "\n")
  expect_false(
    grepl('"params"\\s*:\\s*"', raw),
    info = "params must always be an array, never a bare string"
  )

  m <- read_manifest(out)
  for (q in m$capabilities$namedQueries) {
    expect_true(is.list(q$params))
  }
})


# ============================================================================
# Provenance: the repository that owns the data, not dataimago's own
# ============================================================================

test_that("outside a git repository, git_sha is null and dirty is conservatively true", {
  out <- withr::local_tempdir() # a tempdir is not inside a git repo
  export_fixture(out)
  prov <- read_manifest(out)$provenance

  # There is no honest answer, so we do not invent one. Integrity (sha256)
  # still holds; provenance does not.
  expect_null(prov$git_sha)
  expect_true(prov$dirty)
  expect_true(nzchar(prov$built_at))
})


test_that("inside a git repository, git_sha names the commit that owns the data", {
  skip_if(!nzchar(Sys.which("git")), "git not available")

  repo <- withr::local_tempdir()
  out <- fs::path(repo, "public", "api")
  fs::dir_create(out, recurse = TRUE)

  # shQuote every argument: system2() does no quoting of its own.
  git <- function(...) {
    system2("git", c("-C", shQuote(repo), vapply(list(...), shQuote, character(1))),
      stdout = TRUE, stderr = FALSE
    )
  }
  git("init", "--quiet")
  git("config", "user.email", "test@example.com")
  git("config", "user.name", "Test")
  writeLines("seed", fs::path(repo, "README.md"))
  git("add", "README.md")
  git("commit", "--quiet", "-m", "seed")

  head_sha <- git("rev-parse", "HEAD")[1]
  export_fixture(out)
  prov <- read_manifest(out)$provenance

  expect_identical(prov$git_sha, head_sha)
  # The export just wrote untracked files into the tree, so it is dirty --
  # and the manifest says so rather than claiming a clean build.
  expect_true(prov$dirty)
})


test_that("a clean git tree is reported clean", {
  skip_if(!nzchar(Sys.which("git")), "git not available")

  repo <- withr::local_tempdir()
  out <- fs::path(repo, "public", "api")
  fs::dir_create(out, recurse = TRUE)

  # shQuote every argument: system2() does no quoting of its own.
  git <- function(...) {
    system2("git", c("-C", shQuote(repo), vapply(list(...), shQuote, character(1))),
      stdout = TRUE, stderr = FALSE
    )
  }
  git("init", "--quiet")
  git("config", "user.email", "test@example.com")
  git("config", "user.name", "Test")
  writeLines("seed", fs::path(repo, "README.md"))
  git("add", "README.md")
  git("commit", "--quiet", "-m", "seed")

  # Ignore everything the export writes, so the tree stays clean while it runs.
  writeLines("public/", fs::path(repo, ".gitignore"))
  git("add", ".gitignore")
  git("commit", "--quiet", "-m", "ignore output")

  export_fixture(out)
  expect_false(read_manifest(out)$provenance$dirty)
})


test_that("provenance survives a project path containing a space", {
  skip_if(!nzchar(Sys.which("git")), "git not available")

  # `~/My Project/` is an ordinary place to keep a project, and system2() pastes
  # its arguments into a shell command without quoting them. Unquoted, `git -C`
  # sees two paths and every store built there silently loses its provenance.
  parent <- withr::local_tempdir()
  repo <- fs::path(parent, "My Project")
  out <- fs::path(repo, "public", "api")
  fs::dir_create(out, recurse = TRUE)

  git <- function(...) {
    system2("git", c("-C", shQuote(repo), vapply(list(...), shQuote, character(1))),
      stdout = TRUE, stderr = FALSE
    )
  }
  git("init", "--quiet")
  git("config", "user.email", "test@example.com")
  git("config", "user.name", "Test")
  writeLines("seed", fs::path(repo, "README.md"))
  git("add", "README.md")
  git("commit", "--quiet", "-m", "seed")

  export_fixture(out)
  expect_identical(read_manifest(out)$provenance$git_sha, git("rev-parse", "HEAD")[1])
})
