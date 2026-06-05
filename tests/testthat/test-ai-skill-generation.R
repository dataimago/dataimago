test_that("generate_ai_skill writes a real Claude skill under .claude/skills/<slug>/", {
  tmp <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(tmp, "fixtpkg")
  project_dir <- withr::local_tempdir()

  res <- generate_ai_skill(
    project_path = project_dir,
    project_name = "Fixture App",
    domain_type = "framework",
    domain_name = "Fixture Methodology",
    source_pkg = pkg_dir,
    verbose = FALSE
  )

  # Slug derives from the source package name.
  expect_setequal(
    res$files_created,
    c(
      ".claude/skills/fixtpkg/SKILL.md",
      ".claude/skills/fixtpkg/workflows.md",
      ".claude/skills/fixtpkg/examples.md"
    )
  )
  skill_path <- fs::path(project_dir, ".claude", "skills", "fixtpkg", "SKILL.md")
  expect_true(fs::file_exists(skill_path))
  expect_true(fs::file_exists(fs::path(project_dir, ".claude", "skills", "fixtpkg", "workflows.md")))
  expect_true(fs::file_exists(fs::path(project_dir, ".claude", "skills", "fixtpkg", "examples.md")))

  skill <- paste(readLines(skill_path), collapse = "\n")
  # Real skill frontmatter (drives auto-discovery + auto-invocation).
  expect_match(skill, "(?m)^name: fixtpkg$", perl = TRUE)
  expect_match(skill, "(?m)^description: .+", perl = TRUE)
  # Generator metadata moved under `metadata:` (indented).
  expect_match(skill, "(?m)^  curated: false$", perl = TRUE)
  # Body content preserved.
  expect_match(skill, "Fixture Methodology", fixed = TRUE)
  expect_match(skill, "hello\\(\\)")
  expect_match(skill, "read-only", ignore.case = TRUE)
  expect_match(skill, "private data", ignore.case = TRUE)
})

test_that("the generated description is a single non-empty line within the length limit", {
  tmp <- withr::local_tempdir()
  pkg_dir <- make_fixture_pkg(tmp, "fixtpkg")
  project_dir <- withr::local_tempdir()

  generate_ai_skill(
    project_path = project_dir,
    project_name = "Fixture App",
    domain_type = "framework",
    source_pkg = pkg_dir,
    verbose = FALSE
  )

  lines <- readLines(fs::path(project_dir, ".claude", "skills", "fixtpkg", "SKILL.md"))
  desc <- grep("^description: ", lines, value = TRUE)
  expect_length(desc, 1L)
  body <- sub("^description: ", "", desc)
  expect_gt(nchar(body), 0L)
  expect_lte(nchar(body), 1024L)
})

test_that("generate_ai_skill writes ^\\.claude$ into .Rbuildignore when the project is an R package", {
  project_dir <- withr::local_tempdir()
  writeLines(
    c("Package: someproj", "Title: A package", "Version: 0.0.1"),
    fs::path(project_dir, "DESCRIPTION")
  )

  generate_ai_skill(
    project_path = project_dir,
    project_name = "someproj",
    domain_type = "framework",
    source_pkg = NULL,
    verbose = FALSE
  )

  buildignore <- readLines(fs::path(project_dir, ".Rbuildignore"))
  expect_true(any(grepl("^\\^\\\\\\.claude\\$$", buildignore)))
})

test_that("generate_ai_skill preserves a curated SKILL.md by default", {
  project_dir <- withr::local_tempdir()
  skill_dir <- fs::path(project_dir, ".claude", "skills", "fixture-app")
  fs::dir_create(skill_dir, recurse = TRUE)
  skill_path <- fs::path(skill_dir, "SKILL.md")
  writeLines(
    c(
      "---",
      "name: fixture-app",
      "description: human-authored",
      "metadata:",
      "  curated: true",
      "---",
      "",
      "# Curated Skill",
      "",
      "Keep this human-authored guidance."
    ),
    skill_path
  )

  res <- generate_ai_skill(
    project_path = project_dir,
    project_name = "Fixture App",
    domain_type = "framework",
    domain_name = "Fixture Methodology",
    source_pkg = NULL,
    verbose = FALSE
  )

  skill <- paste(readLines(skill_path), collapse = "\n")
  expect_match(skill, "Keep this human-authored guidance", fixed = TRUE)
  expect_false(".claude/skills/fixture-app/SKILL.md" %in% res$files_created)
})

test_that("generate_ai_skill can bootstrap over existing generated files", {
  project_dir <- withr::local_tempdir()
  skill_dir <- fs::path(project_dir, ".claude", "skills", "fixture-app")
  fs::dir_create(skill_dir, recurse = TRUE)
  writeLines(
    c(
      "---",
      "name: fixture-app",
      "description: old",
      "metadata:",
      "  curated: false",
      "---",
      "",
      "Old content."
    ),
    fs::path(skill_dir, "SKILL.md")
  )

  generate_ai_skill(
    project_path = project_dir,
    project_name = "Fixture App",
    domain_type = "framework",
    domain_name = "Fixture Methodology",
    source_pkg = NULL,
    overwrite = TRUE,
    verbose = FALSE
  )

  skill <- paste(readLines(fs::path(skill_dir, "SKILL.md")), collapse = "\n")
  expect_match(skill, "name: fixture-app", fixed = TRUE)
  expect_false(grepl("Old content", skill, fixed = TRUE))
})
