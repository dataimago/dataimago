test_that("bootstrap_wiki creates wiki directory structure", {
  tmp <- withr::local_tempdir()

  result <- bootstrap_wiki(
    project_path = tmp,
    project_name = "test-project",
    source_pkg = NULL,
    verbose = FALSE
  )

  expect_true(result$success)
  expect_true(fs::dir_exists(fs::path(tmp, "wiki")))
  expect_true(fs::dir_exists(fs::path(tmp, "wiki", "sources")))
  expect_true(fs::dir_exists(fs::path(tmp, "wiki", "patterns")))
  expect_true(fs::dir_exists(fs::path(tmp, "wiki", "decisions")))
  expect_true(fs::dir_exists(fs::path(tmp, "wiki", "analyses")))
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
