# ============================================================================
# test-knowledge-layer.R
# ----------------------------------------------------------------------------
# Verifies the AI-native R-package knowledge layer:
#   - bootstrap_wiki() is domain-type-aware (framework / research / explorer)
#     and seeds pages with the seeded-vs-curated frontmatter
#   - generate_knowledge_md() renders the domain-type KNOWLEDGE template
#   - ai(spec_path) with a knowledge block scaffolds wiki/ + raw/ + KNOWLEDGE.md
# Uses make_fixture_pkg() from helper-fixtures.R + withr::local_tempdir().
# ============================================================================

test_that("bootstrap_wiki creates framework-type subdirs + raw/", {
  tmp <- withr::local_tempdir()
  bootstrap_wiki(project_path = tmp, project_name = "demo", domain_type = "framework", verbose = FALSE)

  for (sd in c("principles", "patterns", "decisions", "connections", "personas", "analyses")) {
    expect_true(fs::dir_exists(fs::path(tmp, "wiki", sd)), info = sd)
  }
  for (rd in c("papers", "conversations", "data", "references")) {
    expect_true(fs::dir_exists(fs::path(tmp, "raw", rd)), info = rd)
  }
})

test_that("bootstrap_wiki creates research-type subdirs", {
  tmp <- withr::local_tempdir()
  bootstrap_wiki(project_path = tmp, project_name = "demo", domain_type = "research", verbose = FALSE)

  for (sd in c("sources", "theories", "methods", "findings", "arguments")) {
    expect_true(fs::dir_exists(fs::path(tmp, "wiki", sd)), info = sd)
  }
  expect_false(fs::dir_exists(fs::path(tmp, "wiki", "principles")))
})

test_that("seeded wiki pages carry the seeded-vs-curated frontmatter", {
  tmp <- withr::local_tempdir()
  bootstrap_wiki(project_path = tmp, project_name = "demo", domain_type = "framework", verbose = FALSE)

  idx <- readLines(fs::path(tmp, "wiki", "index.md"))
  expect_true(any(grepl("^curated: false$", idx)))
  expect_true(any(grepl("^generator: dataimago-rpkg$", idx)))
  expect_true(any(grepl("^generator_version:", idx)))
})

test_that("generate_knowledge_md renders the framework template with no leftover tokens", {
  tmp <- withr::local_tempdir()
  generate_knowledge_md(
    project_path = tmp, project_name = "SGPc", domain_type = "framework",
    domain_name = "Copula Growth Methodology", source_pkg = NULL, verbose = FALSE
  )

  km <- fs::path(tmp, "KNOWLEDGE.md")
  expect_true(fs::file_exists(km))
  txt <- paste(readLines(km), collapse = "\n")
  expect_match(txt, "SGPc")
  expect_match(txt, "Copula Growth Methodology")
  expect_false(grepl("\\{\\{", txt)) # no unrendered mustache tokens
})

test_that("generate_knowledge_md preserves existing KNOWLEDGE.md by default", {
  tmp <- withr::local_tempdir()
  km <- fs::path(tmp, "KNOWLEDGE.md")
  writeLines(c(
    "---",
    "title: Curated Manual",
    "curated: true",
    "---",
    "",
    "# Curated domain manual",
    "",
    "Do not overwrite this content."
  ), km)

  res <- generate_knowledge_md(
    project_path = tmp, project_name = "SGPc", domain_type = "framework",
    domain_name = "Copula Growth Methodology", source_pkg = NULL, verbose = FALSE
  )

  txt <- paste(readLines(km), collapse = "\n")
  expect_match(txt, "Do not overwrite this content", fixed = TRUE)
  expect_true(isTRUE(res$skipped))
})

test_that("ai(spec_path) with a knowledge block scaffolds wiki/ + raw/ + KNOWLEDGE.md", {
  tmp <- withr::local_tempdir()
  make_fixture_pkg(fs::path(tmp, "packages", "r-packages"), "fixtpkg")
  spec <- list(
    apiVersion = "dataimago.ai/v1alpha1",
    kind = "ProjectSpec",
    metadata = list(name = "demo"),
    source = list(
      case = "retrofit",
      rPackage = list(name = "fixtpkg", submodulePath = "packages/r-packages/fixtpkg")
    ),
    features = list(mcpTools = FALSE, apiScaffolding = FALSE),
    knowledge = list(domainType = "framework", domainName = "Demo Methodology"),
    generator = list(outputDir = ".")
  )
  spec_path <- fs::path(tmp, "dataimago-spec.yaml")
  yaml::write_yaml(spec, spec_path)

  res <- suppressWarnings(ai(spec_path = spec_path, verbose = FALSE))

  expect_true("bootstrap_wiki" %in% res$generators_run)
  expect_true("generate_knowledge_md" %in% res$generators_run)
  expect_true(fs::dir_exists(fs::path(tmp, "wiki", "principles")))
  expect_true(fs::file_exists(fs::path(tmp, "KNOWLEDGE.md")))
})
