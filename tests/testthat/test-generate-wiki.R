test_that("bootstrap_wiki creates the framework-type wiki structure by default", {
  tmp <- withr::local_tempdir()

  result <- bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  expect_true(result$success)
  expect_true(fs::dir_exists(fs::path(tmp, "wiki")))
  # Default domain_type is "framework" (see wiki_subdirs_for()).
  for (sd in c("principles", "patterns", "decisions", "connections", "personas", "analyses")) {
    expect_true(fs::dir_exists(fs::path(tmp, "wiki", sd)), info = sd)
  }
})

test_that("bootstrap_wiki creates raw/ directories (Karpathy 3-layer)", {
  tmp <- withr::local_tempdir()

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  expect_true(fs::dir_exists(fs::path(tmp, "raw")))
  expect_true(fs::dir_exists(fs::path(tmp, "raw", "papers")))
  expect_true(fs::dir_exists(fs::path(tmp, "raw", "conversations")))
  expect_true(fs::dir_exists(fs::path(tmp, "raw", "data")))
  expect_true(fs::dir_exists(fs::path(tmp, "raw", "references")))

  expect_true(fs::file_exists(fs::path(tmp, "raw", "papers", ".gitkeep")))
  expect_true(fs::file_exists(fs::path(tmp, "raw", "conversations", ".gitkeep")))
  expect_true(fs::file_exists(fs::path(tmp, "raw", "data", ".gitkeep")))
  expect_true(fs::file_exists(fs::path(tmp, "raw", "references", ".gitkeep")))
})

test_that("bootstrap_wiki creates required wiki pages", {
  tmp <- withr::local_tempdir()

  result <- bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  expect_true(fs::file_exists(fs::path(tmp, "wiki", "index.md")))
  expect_true(fs::file_exists(fs::path(tmp, "wiki", "glossary.md")))
  expect_true(fs::file_exists(fs::path(tmp, "wiki", "log.md")))
  expect_true(fs::file_exists(fs::path(tmp, "wiki", "overview.md")))

  expect_true("wiki/index.md" %in% result$files_created)
  expect_true("wiki/glossary.md" %in% result$files_created)
  expect_true("wiki/log.md" %in% result$files_created)
  expect_true("wiki/overview.md" %in% result$files_created)
})

test_that("bootstrap_wiki wiki pages have YAML frontmatter", {
  tmp <- withr::local_tempdir()

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  index_content <- readLines(fs::path(tmp, "wiki", "index.md"))
  expect_equal(index_content[1], "---")
  expect_true(any(grepl("^title:", index_content)))

  glossary_content <- readLines(fs::path(tmp, "wiki", "glossary.md"))
  expect_equal(glossary_content[1], "---")
})

test_that("bootstrap_wiki is idempotent on directories", {
  tmp <- withr::local_tempdir()

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )
  result2 <- bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  expect_true(result2$success)
})

test_that("bootstrap_wiki preserves curated root pages on rerun", {
  tmp <- withr::local_tempdir()

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  index_path <- fs::path(tmp, "wiki", "index.md")
  writeLines(c(
    "---",
    "title: Curated Index",
    "type: index",
    "curated: true",
    "---",
    "",
    "# Curated index",
    "",
    "Human-authored content."
  ), index_path)

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  index_content <- paste(readLines(index_path), collapse = "\n")
  expect_match(index_content, "Human-authored content", fixed = TRUE)
  expect_false(grepl("This wiki was bootstrapped by dataimago", index_content, fixed = TRUE))
})

test_that("bootstrap_wiki treats pages without curated frontmatter as protected", {
  tmp <- withr::local_tempdir()

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  overview_path <- fs::path(tmp, "wiki", "overview.md")
  writeLines(c(
    "# Manually authored overview",
    "",
    "No generator frontmatter here."
  ), overview_path)

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  overview_content <- paste(readLines(overview_path), collapse = "\n")
  expect_match(overview_content, "No generator frontmatter here", fixed = TRUE)
})

test_that("bootstrap_wiki appends to existing log instead of truncating", {
  tmp <- withr::local_tempdir()

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  log_path <- fs::path(tmp, "wiki", "log.md")
  writeLines(c(
    "---",
    "title: Activity Log",
    "type: log",
    "curated: true",
    "---",
    "",
    "# Wiki Activity Log",
    "",
    "Existing curated entry."
  ), log_path)

  bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  log_content <- paste(readLines(log_path), collapse = "\n")
  expect_match(log_content, "Existing curated entry", fixed = TRUE)
  expect_match(log_content, "bootstrap | Wiki initialized by dataimago", fixed = TRUE)
})
