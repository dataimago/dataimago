---
title: "CLAUDE.md: R Package Context for dataimago"
description: "A technical and philosophical companion for the creation of the R-based foundation of the dataimago ecosystem."
version: "0.0-0.1"
author: "dataimago AI + Human Co-Creation"
---

## 🎯 Purpose

This file defines the design context, architectural principles, and ethical underpinnings for developing the `dataimago` R package. The package is the seed of a wider vision: an emancipatory AI-aligned performance management system built on flow-based analytics. It is not just a library of functions — it is the philosophical and computational *core* of a future system spanning APIs, machine interfaces, and planetary-scale performance infrastructures.

The `dataimago` R package aims to:
- House the foundational **documents**, **data**, and **conceptual primitives** of the company;
- Provide **computational tools** and **models** aligned with flow-based thinking and critical theory;
- Serve as a backend module to future **Next.js web platforms** and **AI-integrated agents**;
- Establish **semantic interoperability** with downstream technologies via structured metadata and thoughtful design;
- Model "code-as-philosophy": embedding emancipatory logic, naming conventions, and intentional structure into every design decision.

---

## 📚 Package Structure & Conventions

### 1. **Documents-as-Data**
All canonical company documents (e.g., vision statements, design charters, methodological primers, philosophical essays) are stored within `inst/dataimago/` with complete organizational structure preserved.

- Use `tibble::tibble()` to structure metadata: title, author, version, source, ethical tag.
- Raw `.md`, `.qmd`, or `.txt` files are stored and exposed via package-access functions (e.g., `get_foundation_document("mission")`).
- Vignettes should describe the relationship between R objects and the company’s long-term vision.

### 2. **Function Naming & Design**
All function names should reflect **modularity**, **clarity**, and **semantically rich purpose**. Examples:

**Currently Implemented:**
- `create_quarto_documentation()` - Generate ethical AI documentation
- `parse_description_file()` - Extract package metadata with philosophical context
- `update_dataimago_assets()` - Manage visual identity across platforms

**Future Functions:**
- `flowMatrix()` for flow-based transition logic
- `docEmbed()` for generating embeddings from internal philosophical texts
- `get_foundation_document()` for programmatic access to core documents

Avoid opaque abbreviations unless canonized (e.g., `sgp` is acceptable). All exported functions must:
- Be documented with `roxygen2`, including philosophical context where relevant.
- Include usage examples that clarify *why* a function exists, not just *how*.

### 3. **Data Philosophy**
This package treats data as socially constructed, ethically weighted, and interpretively rich.

- Use `labelled::labelled()` or metadata YAMLs to embed interpretive context into datasets.
- Where appropriate, include **data dictionaries** that connect variables to social/political meaning.
- Avoid flattening interpretive nuance — especially in anything that touches student, community, or public data.

### 4. **File System Standards**
```
dataimago/
├── R/                      # Core functions (documentation_utils.R, etc.)
├── man/                    # Generated .Rd files  
├── data/                   # Structured datasets (if any)
├── inst/
│   ├── dataimago/          # Complete foundation documents
│   │   ├── 01_Foundations/ # Mission, vision, philosophy
│   │   ├── 02_Manifesto/   # Critical theory content
│   │   ├── 03_Application_Architecture/
│   │   └── 04_dataimago_Content/ # Design assets
│   ├── CLAUDE.md           # AI agent context
│   └── AGENT_INDEX.md      # Agent coordination
├── quarto_website/         # Website source
├── docs/                   # Rendered website (output-dir)
├── vignettes/
├── tests/
├── DESCRIPTION
├── NAMESPACE
├── .Rbuildignore          # Curated content exclusions
```

---

## 🧠 Interoperability Targets

The R package is explicitly designed for export into larger systems. This includes:

### A. Web-based Interfaces (Next.js)
- Output formats should be JSON- and YAML-compatible where appropriate.
- HTML rendering via `quarto::quarto_render()` or `rmarkdown::render()` must be integrated into pipelines.

### B. API Readiness
- Plan functions that are callable via `plumber` APIs (e.g., `GET /generate/flow-matrix`).
- Export structured JSON schemas where possible using `jsonlite::toJSON()`.

### C. Embedding for AI Agents
- Package includes `inst/CLAUDE.md` for persistent AI context
- `inst/AGENT_INDEX.md` coordinates multiple AI interactions
- Foundation documents provide philosophical grounding for AI reasoning
- Generated documentation includes machine-readable ethical annotations
- All outputs structured for LLM consumption with `<!-- AI Context: -->` comments

---

## 📝 Documentation Philosophy

### Automated Documentation Generation
The package includes `create_quarto_documentation()` which:
- Converts .Rd files to .qmd with philosophical context
- Adds ethical AI annotations to every function
- Links technical documentation to foundation documents
- Generates complete websites with dataimago branding

### Documentation Standards
- Every function gets ethical context via `post_process_md_to_qmd()`
- Foundation documents are automatically cross-referenced
- YAML frontmatter includes package version and dataimago branding
- Custom CSS classes for philosophical content (.ethical-note, .foundation-quote)

---

## 🔢 Versioning Philosophy

dataimago uses semantic versioning with a twist: `x.x-x.x` format
- Reflects the iterative, dialectical nature of development
- Major version changes represent philosophical evolution
- Minor versions represent technical implementation improvements
- Build versions track ethical refinements and context updates

---

## 🌱 Code-as-Philosophy Commitments

This R package is an instantiation of critical theory in code:

- **Hermeneutic Transparency**: All modeling assumptions and transformations are documented and interpretable.
- **Positivistic Rigor**: Empirical operations are robust, efficient, and replicable.
- **Ethical Reflexivity**: Tools include commentary and affordances for users to interrogate their own usage.
- **Iterative Design**: Each commit is a dialectical step in reconciling present limitations with future aspirations.

---

## ✅ Quality Assurance & Ethics

### Testing Philosophy
- Unit tests for technical functionality (`testthat`)
- Integration tests for documentation generation
- Philosophical consistency tests (do outputs align with values?)
- Build verification ensures curated content delivery

### Ethical Checkpoints
- Every function includes ethical context
- Documentation generation respects philosophical foundations  
- Asset management preserves visual identity integrity
- Version control tracks both technical and ethical evolution

---

## 📐 Development Workflow

1. **Use `usethis` to scaffold** development properly ✅ 
2. **Use `testthat`** from the start ✅
3. **Use `quarto` for documentation** ✅ (via `create_quarto_documentation()`)
4. **Use `Rd2md` for .Rd conversion** ✅ 
5. **Use `.Rbuildignore` for content curation** ✅
6. **Version control via GitHub** with automated website deployment to `/docs`
7. **Roxygen2 for function documentation** with ethical annotations

---

## 🚀 Current Implementation Status

### Phase 1: Foundation ✅ COMPLETE
- Package structure and metadata
- Foundation document organization in `inst/dataimago/`
- Content curation via `.Rbuildignore`
- MIT licensing and proper attribution

### Phase 2: Documentation Generation ✅ COMPLETE  
- `create_quarto_documentation()` function
- Rd2md integration for .Rd → .qmd conversion
- Philosophical context injection
- Complete Quarto website generation with dataimago branding

### Phase 3: Foundation Access Functions 🔄 PLANNED
- `get_foundation_document()` - Programmatic access to philosophical content
- `create_dataimago_app()` - Generate application skeletons
- `bootstrap_emancipatory_framework()` - Initialize projects with ethical foundations

---

## 🔭 Looking Ahead

This package is not just for R users — it is a **semantic core** for downstream AI and machine-based systems. Its integrity, clarity, and composability will determine the quality of every future artifact, insight, or alignment effort that builds on top of it.

Every function you write here will one day be called by an AI, reasoning about how to improve schools, policies, or systems. Design accordingly.

---

## 🌀 Contact

If you're not sure whether something belongs here, ask: “Would this object help an AI understand, improve, or operationalize emancipatory thinking?”

If yes, it belongs.
