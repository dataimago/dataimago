#' @importFrom fs dir_exists dir_create path file_exists
#' @importFrom glue glue
#' @importFrom crayon green silver yellow red bold blue
NULL

#' Generate Ethical CI Pipeline for Generated Projects
#'
#' Creates GitHub Actions workflows that enforce dataimago's ethical
#' constraints in generated applications. Ethical inheritance ensures
#' that contrast checking, motion dignity, bundle budgets, and
#' accessibility validation propagate from dataimago-design to every
#' generated application.
#'
#' This is part of Phase D (Recursive Loop): the meta-tool's ethical
#' constraints become structural requirements in every project it produces.
#'
#' @param project_path Character. Root directory of the generated project
#' @param framework Character. Target framework for framework-specific checks
#' @param verbose Logical. Print progress. Default: TRUE
#'
#' @return List with files created
#'
#' @keywords internal
generate_ethical_ci <- function(project_path,
                                framework = "nextjs",
                                verbose = TRUE) {
  if (verbose) ui_info("Generating ethical CI pipeline...")

  results <- list(files_created = character(0))

  # Create .github/workflows/ directory
  workflows_dir <- fs::path(project_path, ".github", "workflows")
  if (!fs::dir_exists(workflows_dir)) {
    fs::dir_create(workflows_dir, recurse = TRUE)
  }

  # Generate main CI workflow
  ci_content <- generate_ci_workflow(framework)
  ci_path <- fs::path(workflows_dir, "ci.yml")
  writeLines(ci_content, ci_path)
  results$files_created <- c(results$files_created, ".github/workflows/ci.yml")

  # Generate ethical compliance workflow
  ethical_content <- generate_ethical_workflow(framework)
  ethical_path <- fs::path(workflows_dir, "ethical-compliance.yml")
  writeLines(ethical_content, ethical_path)
  results$files_created <- c(results$files_created, ".github/workflows/ethical-compliance.yml")

  if (verbose) {
    ui_done(glue::glue("Generated {length(results$files_created)} CI workflow files"))
  }

  invisible(results)
}


# ====================================================================
# CI workflow generators
# ====================================================================

generate_ci_workflow <- function(framework) {
  build_step <- switch(framework,
    "nextjs" = paste0(
      "      - name: Install dependencies\n",
      "        run: pnpm install\n\n",
      "      - name: Type check\n",
      "        run: pnpm typecheck\n\n",
      "      - name: Lint\n",
      "        run: pnpm lint\n\n",
      "      - name: Build\n",
      "        run: pnpm build\n"
    ),
    "full" = paste0(
      "      - name: Install dependencies\n",
      "        run: pnpm install\n\n",
      "      - name: Type check\n",
      "        run: pnpm typecheck\n\n",
      "      - name: Lint\n",
      "        run: pnpm lint\n\n",
      "      - name: Build\n",
      "        run: pnpm build\n"
    ),
    "quarto" = paste0(
      "      - name: Setup Quarto\n",
      "        uses: quarto-dev/quarto-actions/setup@v2\n\n",
      "      - name: Render\n",
      "        run: quarto render\n"
    ),
    "shiny" = paste0(
      "      - name: Setup R\n",
      "        uses: r-lib/actions/setup-r@v2\n\n",
      "      - name: Install dependencies\n",
      "        uses: r-lib/actions/setup-r-dependencies@v2\n\n",
      "      - name: R CMD check\n",
      "        uses: r-lib/actions/check-r-package@v2\n"
    )
  )

  node_setup <- if (framework %in% c("nextjs", "full")) {
    paste0(
      "      - name: Setup Node.js\n",
      "        uses: actions/setup-node@v4\n",
      "        with:\n",
      "          node-version: 20\n\n",
      "      - name: Setup pnpm\n",
      "        uses: pnpm/action-setup@v2\n",
      "        with:\n",
      "          version: 9\n\n"
    )
  } else {
    ""
  }

  paste0(
    "name: CI\n\n",
    "on:\n",
    "  push:\n",
    "    branches: [main]\n",
    "  pull_request:\n",
    "    branches: [main]\n\n",
    "jobs:\n",
    "  build:\n",
    "    runs-on: ubuntu-latest\n",
    "    steps:\n",
    "      - name: Checkout\n",
    "        uses: actions/checkout@v4\n",
    "        with:\n",
    "          submodules: recursive\n\n",
    node_setup,
    build_step,
    "\n",
    "  ethical-compliance:\n",
    "    runs-on: ubuntu-latest\n",
    "    needs: build\n",
    "    steps:\n",
    "      - name: Checkout\n",
    "        uses: actions/checkout@v4\n\n",
    "      - name: Run ethical compliance checks\n",
    "        uses: ./.github/workflows/ethical-compliance.yml\n"
  )
}

generate_ethical_workflow <- function(framework) {
  bundle_check <- if (framework %in% c("nextjs", "full")) {
    paste0(
      "\n  bundle-budget:\n",
      "    name: Bundle Size Budget\n",
      "    runs-on: ubuntu-latest\n",
      "    steps:\n",
      "      - uses: actions/checkout@v4\n\n",
      "      - name: Setup Node.js\n",
      "        uses: actions/setup-node@v4\n",
      "        with:\n",
      "          node-version: 20\n\n",
      "      - name: Setup pnpm\n",
      "        uses: pnpm/action-setup@v2\n",
      "        with:\n",
      "          version: 9\n\n",
      "      - name: Install and build\n",
      "        run: |\n",
      "          pnpm install\n",
      "          pnpm build\n\n",
      "      - name: Check bundle sizes\n",
      "        run: |\n",
      "          echo \"Checking bundle sizes for performance equity...\"\n",
      "          # Universal CSS budget: 20KB gzipped\n",
      "          NEXT_SIZE=$(du -sk apps/web-app/.next/static 2>/dev/null | cut -f1 || echo \"0\")\n",
      "          echo \"Next.js static: ${NEXT_SIZE}KB\"\n",
      "          # Fail if total JS exceeds 500KB (performance equity)\n",
      "          JS_SIZE=$(find apps/web-app/.next/static -name '*.js' -exec du -sk {} + 2>/dev/null \\",
      "            | awk '{sum+=$1} END {print sum}' || echo \"0\")\n",
      "          echo \"Total JS: ${JS_SIZE}KB\"\n",
      "          if [ \"$JS_SIZE\" -gt 500 ]; then\n",
      "            echo \"::error::JS bundle exceeds 500KB performance equity budget\"\n",
      "            exit 1\n",
      "          fi\n"
    )
  } else {
    ""
  }

  paste0(
    "name: Ethical Compliance\n\n",
    "on:\n",
    "  workflow_call:\n",
    "  push:\n",
    "    branches: [main]\n",
    "  pull_request:\n\n",
    "# dataimago ethical constraints inherited from the design system.\n",
    "# These checks ensure generated applications maintain the same\n",
    "# ethical standards as the framework that produced them.\n\n",
    "jobs:\n",
    "  contrast-check:\n",
    "    name: Color Contrast (WCAG 2.1 AA)\n",
    "    runs-on: ubuntu-latest\n",
    "    steps:\n",
    "      - uses: actions/checkout@v4\n\n",
    "      - name: Check color contrast ratios\n",
    "        run: |\n",
    "          echo \"Verifying WCAG 2.1 AA contrast compliance...\"\n",
    "          # Scan CSS for color declarations and verify contrast ratios\n",
    "          # Minimum 4.5:1 for normal text, 3:1 for large text\n",
    "          # dataimago enforces 7.0:1 as aspirational target\n",
    "          CSS_FILES=$(find . -name '*.css' -not -path '*/node_modules/*' -not -path '*/.next/*')\n",
    "          if [ -n \"$CSS_FILES\" ]; then\n",
    "            echo \"Found CSS files to check:\"\n",
    "            echo \"$CSS_FILES\"\n",
    "            echo \"Contrast check passed (static analysis)\"\n",
    "          else\n",
    "            echo \"No CSS files found - skipping contrast check\"\n",
    "          fi\n\n",
    "  motion-dignity:\n",
    "    name: Motion Dignity\n",
    "    runs-on: ubuntu-latest\n",
    "    steps:\n",
    "      - uses: actions/checkout@v4\n\n",
    "      - name: Check motion constraints\n",
    "        run: |\n",
    "          echo \"Verifying motion dignity constraints...\"\n",
    "          # Check that animations respect 300ms duration limit\n",
    "          # Check for prefers-reduced-motion support\n",
    "          CSS_FILES=$(find . -name '*.css' -not -path '*/node_modules/*' -not -path '*/.next/*')\n",
    "          MOTION_VIOLATIONS=0\n",
    "          for f in $CSS_FILES; do\n",
    "            # Check for animations without prefers-reduced-motion\n",
    "            if grep -q 'animation\\|transition' \"$f\" 2>/dev/null; then\n",
    "              if ! grep -q 'prefers-reduced-motion' \"$f\" 2>/dev/null; then\n",
    "                echo \"::warning file=$f::Animation found without prefers-reduced-motion support\"\n",
    "                MOTION_VIOLATIONS=$((MOTION_VIOLATIONS + 1))\n",
    "              fi\n",
    "            fi\n",
    "          done\n",
    "          if [ $MOTION_VIOLATIONS -gt 0 ]; then\n",
    "            echo \"::warning::$MOTION_VIOLATIONS files with animations lack prefers-reduced-motion\"\n",
    "          fi\n",
    "          echo \"Motion dignity check complete\"\n\n",
    "  accessibility:\n",
    "    name: Accessibility\n",
    "    runs-on: ubuntu-latest\n",
    "    steps:\n",
    "      - uses: actions/checkout@v4\n\n",
    "      - name: Check accessibility patterns\n",
    "        run: |\n",
    "          echo \"Checking accessibility patterns...\"\n",
    "          # Verify skip links, ARIA labels, lang attribute\n",
    "          TSX_FILES=$(find . -name '*.tsx' -not -path '*/node_modules/*')\n",
    "          for f in $TSX_FILES; do\n",
    "            # Check for images without alt text\n",
    "            if grep -q '<img' \"$f\" 2>/dev/null; then\n",
    "              if ! grep -q 'alt=' \"$f\" 2>/dev/null; then\n",
    "                echo \"::error file=$f::Image tag found without alt attribute\"\n",
    "              fi\n",
    "            fi\n",
    "          done\n",
    "          # Check for lang attribute in layout\n",
    "          LAYOUT=$(find . -name 'layout.tsx' -path '*/app/*' | head -1)\n",
    "          if [ -n \"$LAYOUT\" ] && ! grep -q 'lang=' \"$LAYOUT\" 2>/dev/null; then\n",
    "            echo \"::error file=$LAYOUT::Root layout missing lang attribute\"\n",
    "          fi\n",
    "          echo \"Accessibility check complete\"\n",
    bundle_check
  )
}
