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
