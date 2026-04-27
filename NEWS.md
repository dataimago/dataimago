# dataimago 0.0-5.0

## Package-Channel Migration + R API Cleanup (2026-04-27)

This release ships the `0.0-4.x` package-channel transition end-to-end. The
`ui/src/dataimago-design/` git submodule has been retired and `dataimago-rpkg`
now consumes the design system as three published packages on a **single
public-npm registry**, matching the posture already adopted by the sibling
`dataimago-design` and `dataimago-ai` repos:

- `@dataimago/tokens` — canonical JSON tokens + `tokens.{css,scss}`
- `@dataimago/css` — compiled `dataimago.{css,min.css}` + Tailwind preset
- `@dataimago/ui` — React component bundle (optional)

No auth token is required for read access. The interim
`@dataimago-ui/components` scope on GitHub Packages — referenced in the
0.0-4.x WIP but never actually published — has been folded into
`@dataimago/ui` on public npm. See the *Scope migration* subsection below.

### Changed

* **`ui/build.js`** — rewritten to consume `node_modules/@dataimago/*` instead
  of running a two-stage submodule build. It assembles `ui/dist/`, synthesizes
  `dataimago-{light,dark}.scss` and `website-theme.{css,min.css}` locally from
  the installed tokens, and fans assets out to `inst/quarto-assets/`,
  `ui/www/assets/css/`, `ui/www/_extensions/dataimago/ai-native/assets/css/`,
  and `docs/assets/css/` — preserving every filename the R side depends on.
* **`ui/package.json`** — declares `@dataimago/tokens`, `@dataimago/css`,
  and `@dataimago/ui` (all `^0.1.0-alpha.1`) as dependencies; removes the
  legacy Style-Dictionary / Sass / PostCSS toolchain that lived here
  previously.
* **`ui/README.md`** — rewritten to document the new package-channel build
  pipeline and the prototype-in-consumer loop.
* **`CLAUDE.md`** — session-start protocol, directory guide, build flow, and
  submodule workflow sections rewritten to describe the package channel.

### Added

* **`ui/.npmrc`** — pins the `@dataimago` scope to public npm. Single
  registry, single auth posture (`always-auth=true`); no token required
  for read access. Tracked via a `!ui/.npmrc` exception in `.gitignore`
  so consumers cloning the repo pick it up directly.
* **`tools/design-link.mjs`** + **`pnpm design:{link,unlink,status}`** in
  `ui/` — link `@dataimago/*` to a local `dataimago-design` checkout via
  pnpm `overrides` for iterative prototyping.
* **`tools/check-no-link-overrides.mjs`** +
  **`.github/workflows/design-link-guard.yml`** — enforce the ADR's
  prototype-in-consumer contract symmetrically with `dataimago-ai`. The
  workflow runs on every pull request and push to `main` and fails the
  build if `ui/package.json` still contains `link:` or `file:` overrides
  for any `@dataimago/*` package. See
  `dataimago-design/wiki/patterns/prototype-in-consumer.md` for the
  governance rationale and the companion local-dev loop.

### Removed

* `ui/src/dataimago-design/` git submodule and associated `.gitmodules`
  entry.
* Legacy `ui/build-legacy.js`-style two-stage build invocation (delegated
  upstream to `dataimago-design`'s own monorepo build).
* `GITHUB_PACKAGES_TOKEN` plumbing across `.github/workflows/`, `ui/.npmrc`,
  README/CLAUDE/inst documentation, and `ui/build.js` header comments. The
  package channel is single-registry public npm; consumers and CI no
  longer set this secret.

### Scope migration — `@dataimago-ui/components` → `@dataimago/ui`

The 0.0-4.x WIP referenced an `@dataimago-ui/components` package on
GitHub Packages, but that scope was **never actually published** — the
design + ai stack consolidated to `@dataimago/ui` on public npm before
the rpkg-side migration shipped. This release folds the rename in so
`cd ui && pnpm install` resolves cleanly:

* All three packages now resolve from a single registry (public npm) at
  `^0.1.0-alpha.1`, matching what `dataimago-design`'s `release.yml`
  publishes and what `dataimago-ai/apps/platform` consumes.
* Renamed across `ui/package.json`, `ui/build.js` (path constants,
  `requirePkg` calls, Stage 3 console banner, manifest sources),
  `tools/check-no-link-overrides.mjs`, `tools/design-link.mjs`, and
  `.github/workflows/ai-context.yml`.
* All package and roxygen documentation (`README.md`, `CLAUDE.md`,
  `ui/README.md`, `ui/www/README.md`, `ui/www/design_system.qmd`,
  `inst/dataimago/{ARCHITECTURE,HISTORICAL_ROADMAP}.md`,
  `inst/quarto-assets/README{,-latex}.md`, `R/dataimago-package.R`,
  `R/design_system.R`) was updated to the unified scope.
* Ignore-pattern files (`.gitignore`, `.Rbuildignore`, `.repomixignore`)
  were updated, including a `!ui/.npmrc` exception so the npmrc tracks
  in-repo.

### Breaking changes (R API)

Alongside the submodule retirement, this release removes the in-package
scaffolders and related workflow pieces that assumed a co-located
`ui/src/dataimago-design/` source tree. Downstream consumers calling any
of the symbols below need to migrate before upgrading.

* **`create_ui_workspace()` — removed.** No longer exported. Consumer
  repos must bootstrap their own `ui/` directory manually by copying the
  reference `ui/package.json`, `ui/.npmrc`, and `ui/build.js` from this
  package and running `cd ui && pnpm install && pnpm build`. Full steps in
  `dataimago-design/wiki/patterns/new-consumer-checklist.md`.
* **`build_design_framework()` — removed.** The entire `R/build_framework.R`
  file was deleted. The framework is now assembled upstream in the
  `dataimago-design` monorepo and shipped via `@dataimago/tokens`,
  `@dataimago/css`, and `@dataimago/ui` on public npm. Use
  `pnpm update @dataimago/tokens @dataimago/css @dataimago/ui` in `ui/`
  followed by `build_design_system()` to refresh consumer assets.
* **`scaffold_full_quarto_site()`, `scaffold_ethics_pages()`,
  `scaffold_js_assets()`, `load_quarto_template()`,
  `render_quarto_template()`, `build_quarto_template_vars()`,
  `scaffold_content_directories()`, `scaffold_utility_pages()` — removed.**
  These internal helpers generated a Quarto site scaffold from assets
  inside the submodule; they have no package-channel equivalent. Use the
  documented `create_quarto_documentation(template = "dataimago")`
  baseline and hand-author any additional pages in the consumer's own
  Quarto project. The `scaffold_full_site` and `include_ethics`
  parameters of `create_quarto_documentation()` were removed accordingly.
* **`ai(mode = "local")` — removed.** `ai()` no longer supports a local
  pipeline. Calling it with `mode = "local"` now throws an explanatory
  `stop()` pointing to `mode = "remote"` (the recommended path, which
  requires `DATAIMAGO_API_KEY`) or to the manual
  `new-consumer-checklist.md`. `ai_remote()` likewise no longer falls
  back to the local pipeline when the platform API is unreachable — it
  errors with the HTTP failure so consumers see the problem.
* **`build_design_system()` Step 5 (LaTeX distribution) — removed.** The
  automatic copy of `dataimago.sty` out of the submodule into
  `inst/quarto-assets/`, `ui/www/_extensions/.../latex/`,
  `ui/www/assets/latex/`, and `docs/assets/latex/` has been removed. A
  future `@dataimago/latex` npm package will restore the packaged
  channel; in the interim, consumers that need PDF styling should copy
  `inst/quarto-assets/dataimago.sty` into their project by hand. See
  `inst/quarto-assets/README-latex.md` for the transitional workflow.
* **`generate_ethical_ci()` CI template — `submodules: recursive` dropped.**
  The actions/checkout step emitted for downstream CI no longer requests
  recursive submodule checkout. Downstream consumers that were relying on
  the template to pull `dataimago-design` as a submodule must switch to
  the package-channel install (`pnpm install` from public npm; no token
  required).
* **Workflow secrets — `SUBMODULE_PAT` no longer read.** All six
  `.github/workflows/*.yml` files in this package were cleaned up
  (`ai-context.yml`, `R-CMD-check.yml`, `netlify-deploy.yml`,
  `quarto-deploy.yml`, `release-cdn.yml`, `test-suite.yml`): the
  `submodules: recursive` and `token: ${{ secrets.SUBMODULE_PAT || github.token }}`
  inputs were removed from `actions/checkout`, and the `rm -rf
  ui/src/dataimago-design/node_modules` cleanup step was removed from
  `R-CMD-check.yml`. Fork maintainers can retire the `SUBMODULE_PAT`
  repository secret.
* **Generated docs refreshed.** `NAMESPACE` no longer exports the removed
  functions; the corresponding `.Rd` files under `man/`
  (`build_design_framework.Rd`, `create_ui_workspace.Rd`,
  `scaffold_full_quarto_site.Rd`, `scaffold_ethics_pages.Rd`,
  `scaffold_js_assets.Rd`, `load_quarto_template.Rd`,
  `render_quarto_template.Rd`, `build_quarto_template_vars.Rd`,
  `scaffold_content_directories.Rd`, `scaffold_utility_pages.Rd`) were
  deleted. `docs/` was re-rendered and `dataimago-repomix.{md,xml}` was
  regenerated.

### Migration summary

| If you were calling…                   | Do this instead                                                                                             |
|----------------------------------------|-------------------------------------------------------------------------------------------------------------|
| `create_ui_workspace()`                | Copy `ui/package.json` + `ui/.npmrc` + `ui/build.js`, then `cd ui && pnpm install`                          |
| `build_design_framework()`             | `pnpm update @dataimago/*` in `ui/`, then `build_design_system()`                                           |
| `scaffold_full_quarto_site()` & kin    | `create_quarto_documentation(template = "dataimago")`, author extras by hand                                |
| `create_quarto_documentation(scaffold_full_site = TRUE, include_ethics = TRUE)` | Drop both arguments — they were removed                                               |
| `ai(mode = "local")`                   | `ai(mode = "remote")` with `DATAIMAGO_API_KEY` set, or bootstrap by hand via `new-consumer-checklist.md`    |
| `ai_remote()` with no API key / reachable API | Provide `DATAIMAGO_API_KEY` and confirm the platform endpoint; no silent fallback remains          |
| `build_design_system()` LaTeX step     | Manually copy `inst/quarto-assets/dataimago.sty` into the consumer until `@dataimago/latex` ships           |
| `generate_ethical_ci()` emitted CI     | Regenerate CI from the updated template; drop `SUBMODULE_PAT` from repo secrets                             |

### Context

This release is the rpkg-side companion to the `dataimago-design` Option B
refactor (see `dataimago-design/wiki/decisions/publish-packages.md`) and the
`dataimago-ai` platform adoption landed the same week. The bidirectional
flow is now: prototype in a consumer repo against a `design:link`-ed
checkout, push changes into `dataimago-design`, cut a Changesets release,
and bump the consumers — instead of committing submodule-pointer bumps.

---

# dataimago 0.0-3.1

## Phase 2e.d — Generator Alignment with NextJS Canonical Backend (2026-04-17)

This release aligns the rpkg generators with the Phase 2e architectural landing in `dataimago-ai`: the NextJS API route tree is now the canonical public data surface, and `@dataimago/shared-utils` selects a `ProducerDriver` (static / live / composite / database) at runtime. The rpkg generators no longer emit dual-mode `axios` clients; they emit a single NextJS-calling client whose server-side behavior is governed by `DATAIMAGO_PRODUCER`.

### Changed

* **`export_static_api()`** — emits JSON fixtures under `public/api/*.json` shaped for the NextJS `/api/data/[endpoint]/[[...params]]` route's `StaticProducerDriver` (served only when `DATAIMAGO_PRODUCER=static`). No longer the runtime producer itself.
* **`generate_shared_utils()`** — emits the new single-path `DataimagoApiClient` (always NextJS-calling), the `ProducerDriver` TypeScript interface, and the `resolveProducerDriver()` selector. `axios` is no longer generated as a dependency.
* **`generate_api_scaffolding()`** — emits the `/api/discover`, `/api/data/[endpoint]/[[...params]]`, `/api/wiki/[...path]`, and `/api/scheduled/[task]` route handlers with shared `_lib/` helpers for `ApiError`, `RequestContext`, and parameter whitelist validation.
* **`generate_mcp()` / `generate_self_mcp()`** — MCP endpoint descriptors reframed as a documentation and runtime-intent surface; actual MCP invocation runtime (`/api/mcp/[tool]`) is deferred to Phase 5. Descriptors carry `producer`, `endpoint`, and `params` so the downstream runtime can resolve them without re-parsing.

### Added

* **`generate_ai_context()`** — refreshed to index the current package layout (`inst/dataimago/`, `R/` file list, submodule-aware repomix scope) and to exclude historical Kruger redesign notes (now archived in `ui/src/dataimago-design/raw/references/kruger-redesign/`).
* Package-root `CLAUDE.md` with accurate file system standards (`inst/dataimago/` contents, 15-file `R/` tree, correct document locations for AI agents).
* Linter-clean quote style across `build_components.R`, `generate_api.R`, `generate_mcp.R`, and `generate_self_mcp.R` (double quotes only, per `lintr` `quotes_linter`).

### Documentation

* `inst/dataimago/IMPLEMENTATION_ROADMAP.md` renamed to `HISTORICAL_ROADMAP.md` with a "HISTORICAL / SUPERSEDED" header pointing to the current roadmap in `ui/src/dataimago-design/wiki/analyses/development-roadmap.md`.
* `.repomixignore` rewritten to exclude `ui/src/dataimago-design/raw/`, `dataimago.Rcheck/`, `*-repomix.md`/`.xml`, and `ui/src/dataimago-design/dist/`, shrinking generated AI context from 26.8 MB to 3.4 MB.
* Non-ASCII em dash in `R/generate_types.R` replaced with `--` to silence R CMD check.

### Context

The Phase 2e.d generator alignment is the rpkg-side companion to the atomic `dataimago-ai` PR landed 2026-04-17. See `ui/src/dataimago-design/wiki/log.md` entries for the same date and `ui/src/dataimago-design/wiki/patterns/producer-driver-pattern.md` for the runtime contract.

---

# dataimago 0.0-0.1

## Initial Release — Foundation & Documentation Generation

### Package Infrastructure

* Initial R package structure created from philosophical foundation documents
* Core foundation documents organized in `inst/dataimago/01_Foundations/`
* Manifesto content included in `inst/dataimago/02_Manifesto/`
* Application architecture blueprints in `inst/dataimago/03_Application_Architecture/`
* Essential design assets in `inst/dataimago/04_dataimago_Content/`
* Curated content delivery via selective `.Rbuildignore` patterns
* MIT licensing with proper attribution

### Documentation Generation

* **NEW**: `create_quarto_documentation()` function for ethical AI documentation
* **NEW**: Rd2md integration for .Rd to .qmd conversion with philosophical context
* **NEW**: Automated YAML frontmatter generation with package metadata
* **NEW**: Ethical context injection via `post_process_md_to_qmd()`
* **NEW**: dataimago branding and visual identity integration
* **NEW**: Foundation document cross-referencing in technical documentation

### AI Agent Integration

* **NEW**: Comprehensive roxygen2 documentation optimized for MCP compatibility
* **NEW**: `inst/CLAUDE.md` — Persistent AI context for agent interactions
* **NEW**: `inst/AGENT_INDEX.md` — AI agent coordination and capability registry
* **NEW**: Structured metadata for machine-readable ethical annotations
* **NEW**: Package-level documentation (`dataimago-package.R`) for AI understanding

### Website Generation

* **NEW**: Complete Quarto website structure in `quarto_website/`
* **NEW**: Custom dataimago SCSS theming with ethical AI styling
* **NEW**: Automated asset management (PNG logos, visual frameworks)
* **NEW**: Website rendering to `docs/` directory for GitHub Pages
* **NEW**: Navigation structure linking technical and philosophical content

### Documentation Standards

* Enhanced README.md with comprehensive package overview
* MCP tool integration examples and JSON schema specifications
* Philosophical context embedded in all technical documentation
* Code-as-philosophy commitments documented throughout
* Consistent parameter naming and return value structures

### Development Workflow

* Roxygen2-based documentation generation with ethical annotations
* Automated website building via Quarto rendering
* Content curation ensuring clean package distribution
* Version control integration with philosophical evolution tracking

## Philosophy in Practice

This release embodies dataimago's core principle: instead of embedding culture in AI, we **embed AI in culture** for emancipatory ends. Every function includes philosophical context, connecting computational tools to their ethical foundations and societal purposes.
