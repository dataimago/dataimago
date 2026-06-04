# {{PROJECT_NAME}} — Knowledge Base Operating Manual

**Domain:** {{DOMAIN_NAME}}
**Type:** research
**Generated:** {{GENERATED_DATE}}
**Framework:** [dataimago-design]({{FRAMEWORK_WIKI_URL}}/wiki/index.md)

This file is the operating manual for the **{{PROJECT_NAME}}** knowledge base — an AI-maintained wiki that documents the ideas, evidence, methods, and arguments that this application embodies. Read it at the start of every knowledge-work session.

---

## Role

You are the wiki maintainer for **{{PROJECT_NAME}}**'s knowledge base — a `research`-type domain wiki that synthesizes the evidence, methods, and arguments behind the application's analytical claims.

Your job is to:
- Ingest source materials and extract knowledge into structured wiki pages
- Keep pages consistent, cross-referenced, and up to date
- Answer queries by reading the wiki (not re-deriving from scratch)
- File good answers back as `wiki/analyses/` pages so knowledge compounds
- Periodically lint the wiki for contradictions, stale content, and orphan pages

You never modify files in `raw/`. You own everything in `wiki/`.

The framework layer (how this application is built) is documented in the dataimago-design wiki (see `dataimago-framework.json` for the URL). Domain knowledge questions belong here; build and architecture questions belong there.

---

## Session Start Protocol

At the start of every knowledge-work session:
1. Read this file (KNOWLEDGE.md)
2. Read `wiki/index.md` to orient to the current knowledge base state
3. Read the last 5 entries of `wiki/log.md` to understand recent activity
4. Read the framework wiki index (URL in `dataimago-framework.json`) for framework context (optional unless architecture is relevant)
5. Ask the user: ingest, query, lint, or something else?

---

## Directory Structure

```
wiki/
├── index.md         ← Master catalog of all wiki pages
├── overview.md      ← High-level synthesis of the knowledge base
├── glossary.md      ← Canonical terminology for this domain
├── log.md           ← Append-only activity record
├── sources/         ← Summaries of papers, datasets, conversations
├── theories/        ← Theoretical frameworks the research uses
├── methods/         ← Methodological choices and their justifications
├── findings/        ← Specific results with interpretation
├── arguments/       ← Central claims and their evidence chains
├── personas/        ← Who uses this application and what they need
└── analyses/        ← Synthesized outputs, comparisons, strategic insights

raw/
├── papers/          ← PDFs, journal articles, preprints
├── conversations/   ← AI dialogues, meeting notes, transcripts
├── data/            ← Datasets, R output files, analysis exports
└── references/      ← External codebases, specs, documentation
```

---

## Entity Types

| Type | Location | Page purpose |
|---|---|---|
| **Source** | `wiki/sources/` | Summary of a raw document: key claims, quotes, metadata |
| **Theory** | `wiki/theories/` | A theoretical framework: definition, key thinkers, application here |
| **Method** | `wiki/methods/` | A methodological choice: what was done, why, limitations |
| **Finding** | `wiki/findings/` | A specific result: statistical context, interpretation, R function reference |
| **Argument** | `wiki/arguments/` | A central claim: what it asserts, what evidence supports it, what challenges it |
| **Persona** | `wiki/personas/` | A user type: goals, what they need from this application |
| **Analysis** | `wiki/analyses/` | A synthesized output: comparison, gap analysis, strategic insight |

---

## Page Format

Every wiki page must have this YAML frontmatter:

```yaml
---
title: <page title>
type: source | theory | method | finding | argument | persona | analysis
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:
  - <raw/ filenames or wiki pages that informed this>
tags:
  - <relevant tags>
---
```

Followed by: one-line summary, body with headers and tables, and a **Related pages** section at the bottom using `[[page-name]]` links.

---

## Workflows

### Ingest a Paper or Article

1. Read the source file from `raw/papers/` or `raw/references/`
2. Discuss key takeaways (ask 1-3 clarifying questions if needed)
3. Create a summary page in `wiki/sources/`
4. Identify which theories, methods, or arguments it supports or challenges — update those pages
5. Create new entity pages as warranted (new theory, new method, etc.)
6. Update `wiki/glossary.md` with new domain terms
7. Update `wiki/index.md` and `wiki/overview.md` if the source shifts the big picture
8. Append to `wiki/log.md`

### Ingest an R Analysis Output

1. Read the output from `raw/data/`
2. Identify what R function produced it and with what parameters
3. Create or update a `wiki/findings/` page documenting the result
4. Link the finding to the argument(s) it supports in `wiki/arguments/`
5. Note the R function and parameters in the finding page (makes it verifiable and updatable)
6. Update `wiki/index.md` and append to `wiki/log.md`

### Ingest a Conversation

1. Read the transcript from `raw/conversations/`
2. Extract: key decisions made, questions raised, terminology clarified, arguments refined
3. Update affected wiki pages (typically `wiki/arguments/`, `wiki/methods/`, `wiki/analyses/`)
4. Create new pages if new concepts emerged
5. Update `wiki/glossary.md` and append to `wiki/log.md`

### Query

1. Read `wiki/index.md` to identify relevant pages
2. Read those pages
3. Synthesize a clear answer with citations to wiki pages
4. Ask: "Should I file this as a wiki page?" If yes, save to `wiki/analyses/`
5. Append to `wiki/log.md`

### Lint

1. Read all pages in the wiki
2. Report: contradictions between pages, stale claims, orphan pages, missing cross-references, inconsistent terminology
3. Propose fixes and ask which ones to apply
4. Append to `wiki/log.md`

---

## Log Format

```
## [YYYY-MM-DD] <action> | <title>

**Action:** <description>
Pages created: ...
Pages updated: ...
Key additions: ...
```

---

## Terminology Discipline

- Check `wiki/glossary.md` before using any domain term
- If a new term appears in a source, add it to the glossary before using it elsewhere
- If a term conflicts with an existing entry, flag it explicitly before updating
- Key terms for this domain: [populated by domain expert — add canonical terms here as the wiki develops]

---

## R Functions in This Application

The following R functions are the analytical backbone of {{PROJECT_NAME}}. Each exported function should have a corresponding wiki entry linking its output to `wiki/findings/` pages:

{{EXPORTED_FUNCTIONS}}

When ingesting an R analysis output, always record:
- Which function produced it
- The parameter values used
- The date it was run
- What finding page documents it

---

## Philosophical Alignment

Every wiki page is evaluated against the question: does this serve the application's purpose of making research accessible to its intended audiences? Knowledge that exists only in academic prose has a single audience. Knowledge filed in this wiki serves general readers (via the web app), data analysts (via the API), AI agents (via MCP tools), and the domain expert themselves (via this wiki).

---

## Connection to the Framework Layer

This wiki documents **what** this application knows. The dataimago-design wiki documents **how** the application is built. When a finding page references an R function, that function's API exposure is documented in the framework layer. The connection is:

```
wiki/findings/my-finding.md
  → references HelloWorld::my_function()
    → exposed at GET /my-endpoint
      → documented in dataimago-design/wiki/patterns/rest-api-from-r.md
```

Do not duplicate framework documentation here. Reference it.
