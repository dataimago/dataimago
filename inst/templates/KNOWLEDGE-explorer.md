# {{PROJECT_NAME}} — Knowledge Base Operating Manual

**Domain:** {{DOMAIN_NAME}}
**Type:** explorer
**Explorer dimension:** {{EXPLORER_DIMENSION}}
**Generated:** {{GENERATED_DATE}}
**Framework:** [dataimago-design]({{FRAMEWORK_WIKI_URL}}/wiki/index.md)

This file is the operating manual for the **{{PROJECT_NAME}}** knowledge base — an AI-maintained wiki that documents the dimensions, attributes, datasets, and data quality considerations that make this application trustworthy and navigable. Read it at the start of every knowledge-work session.

---

## Role

You are the wiki maintainer for **{{PROJECT_NAME}}**'s knowledge base — an `explorer`-type domain wiki organized around the `{{EXPLORER_DIMENSION}}` dimension. This application has no thesis to advance; it makes a dataset navigable. Your job is to ensure that every piece of data the application presents is accurately documented — what it means, where it came from, what its limitations are.

Your job is to:
- Document new attributes as they are added to the application
- Summarize source datasets and their quality characteristics
- Answer queries about data provenance, coverage, and interpretation
- File answers as `wiki/analyses/` pages so knowledge compounds
- Lint the wiki for gaps in attribute documentation and stale dataset information

You never modify files in `raw/`. You own everything in `wiki/`.

The framework layer (how this application is built) is documented in the dataimago-design wiki (see `dataimago-framework.json` for the URL). Data and content questions belong here; build and architecture questions belong there.

---

## Session Start Protocol

At the start of every knowledge-work session:
1. Read this file (KNOWLEDGE.md)
2. Read `wiki/index.md` to orient to the current knowledge base state
3. Read the last 5 entries of `wiki/log.md` to understand recent activity
4. Check `wiki/attributes/` for any attributes flagged as needing documentation updates
5. Read the framework wiki index (URL in `dataimago-framework.json`) for framework context (optional unless architecture is relevant)
6. Ask the user: ingest new data, document an attribute, answer a query, or something else?

---

## Directory Structure

```
wiki/
├── index.md          ← Master catalog of all wiki pages
├── overview.md       ← High-level synthesis: what data this application holds and why
├── glossary.md       ← Canonical terminology for this domain
├── log.md            ← Append-only activity record
├── dimensions/       ← The organizing axes of the explorer (geography, time, etc.)
├── attributes/       ← Each measurable property: meaning, source, coverage, caveats
├── datasets/         ← Data sources: provenance, update cadence, coverage gaps
├── sources/          ← Authoritative sources for datasets and attribute definitions
├── personas/         ← Who uses the explorer and what they discover with it
└── analyses/         ← Patterns, comparisons, and insights surfaced from the data

raw/
├── papers/           ← Academic sources, methodology documents
├── conversations/    ← AI dialogues, decisions, notes
├── data/             ← Raw dataset files, exports from R
└── references/       ← External data portals, API specs, codebooks
```

---

## Entity Types

| Type | Location | Page purpose |
|---|---|---|
| **Dimension** | `wiki/dimensions/` | The organizing axes: what they cover, how entities are identified, edge cases |
| **Attribute** | `wiki/attributes/` | Each measurable property: precise definition, source, geographic/temporal coverage, caveats |
| **Dataset** | `wiki/datasets/` | A data source: provenance, update cadence, coverage gaps, known issues, R dataset name |
| **Source** | `wiki/sources/` | An authoritative reference for an attribute definition or dataset methodology |
| **Persona** | `wiki/personas/` | A user type: what they're trying to discover, what attributes they care about |
| **Analysis** | `wiki/analyses/` | Patterns found, comparisons made, insights derived from the data |

---

## The Attribute Page — Core Knowledge Atom

The `wiki/attributes/` directory is the most important part of this wiki. Every attribute the application exposes must have a page that documents:

```markdown
---
title: <attribute human name>
type: attribute
attribute_id: <the parameter name used in R functions and API endpoints>
created: YYYY-MM-DD
updated: YYYY-MM-DD
dataset: <wiki/datasets/dataset-name.md>
sources:
  - <authoritative source for the attribute definition>
tags: []
---

One-line description of what this attribute measures.

## Definition
Precise definition — not just a label. What exactly is being measured? What is the unit?
What is the reference period (for point-in-time attributes)?

## Data Source
- Dataset: [[dataset-name]] 
- R dataset object: `{{PROJECT_NAME}}::dataset_name`
- R retrieval function: `get_entity_profile(entity_id, attributes = "{{ATTRIBUTE_ID}}")`

## Coverage
- Entities covered: (e.g., "193 UN member states", "47 European countries")
- Temporal coverage: (e.g., "2000–2023 annually", "2022 only")
- Known gaps: (e.g., "Missing for small island nations with population < 50,000")

## Data Quality
- Source reliability: (official statistics / derived / estimated / self-reported)
- Known issues: (e.g., "Pre-2010 figures use different methodology")
- Comparability caveats: (e.g., "Purchasing power adjustments vary by source year")

## Interpretation
For non-specialist audiences: what does a high/low value on this attribute mean?
What should users NOT conclude from this attribute?

## Related Attributes
- [[attribute-name]] — (relationship, e.g., "often inversely correlated")
```

---

## Workflows

### Ingest a New Dataset

1. Read the raw data file from `raw/data/` and any codebook from `raw/references/`
2. Create a `wiki/datasets/` page documenting provenance, coverage, and update cadence
3. Create a `wiki/attributes/` page for each attribute the dataset provides
4. Update `wiki/dimensions/` if the dataset covers new entities or extends temporal range
5. Update `wiki/glossary.md` with any new technical terms
6. Update `wiki/index.md` and append to `wiki/log.md`

### Document a New Attribute

1. Identify the authoritative source for the attribute's definition
2. Create a `wiki/attributes/` page following the template above
3. Verify the R retrieval function returns correct data for the attribute
4. Add the attribute to the relevant `wiki/datasets/` page
5. Update `wiki/index.md` and append to `wiki/log.md`

### Ingest a Paper or Reference

1. Read from `raw/papers/`
2. Determine: does this define an attribute? challenge a dataset's methodology? describe a dimension?
3. Create a `wiki/sources/` page summarizing the key claims
4. Link to the affected `wiki/attributes/` or `wiki/datasets/` pages
5. Update `wiki/glossary.md` and append to `wiki/log.md`

### Query

1. Read `wiki/index.md` to identify relevant pages (typically `wiki/attributes/` and `wiki/datasets/`)
2. Read those pages
3. Synthesize a clear answer with citations
4. Ask: "Should I file this as an analysis?" If yes, save to `wiki/analyses/`
5. Append to `wiki/log.md`

### Lint

1. Check every attribute in `wiki/attributes/` has: definition, coverage, data quality, interpretation
2. Check every dataset in `wiki/datasets/` has: provenance, update cadence, known gaps
3. Check for attributes used in the application but not documented in the wiki
4. Check for stale dataset entries (coverage dates that should have been updated)
5. Report findings and propose fixes
6. Append to `wiki/log.md`

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
- Attribute IDs (used in R functions and API endpoints) must be consistent: `{{ATTRIBUTE_ID}}` form
- Entity identifiers must be consistent: `{{EXPLORER_DIMENSION}}` → [describe ID format, e.g., ISO 3166-1 alpha-3 for countries]
- Key terms for this domain: [populated by domain expert — add canonical terms here as the wiki develops]

---

## R Functions in This Application

The following R functions are the retrieval backbone of {{PROJECT_NAME}}:

{{EXPORTED_FUNCTIONS}}

**Standard explorer function pattern:**
- Every attribute is retrievable via `get_entity_profile(entity_id, attributes = "attribute_id")`
- Every attribute is comparable via `compare_entities(entity_ids, "attribute_id")`
- Discovery: `get_attributes()` returns all attributes with their wiki descriptions
- Discovery: `get_entities()` returns all entities with their available attributes

---

## Data Quality Standards

This application makes claims about the world. Every attribute must meet these standards before it can be displayed to users:

1. **Defined** — A `wiki/attributes/` page exists with a precise definition
2. **Sourced** — The data source is documented in a `wiki/datasets/` page
3. **Bounded** — Coverage (entities and time period) is documented
4. **Caveated** — Known quality issues and comparability limits are documented
5. **Interpreted** — A plain-language interpretation is available for non-specialist users

Attributes that fail any of these standards should be marked `status: draft` in their frontmatter and excluded from the production data explorer until the standard is met.

---

## Connection to the Framework Layer

This wiki documents **what data** this application holds and **what it means**. The dataimago-design wiki documents **how** the application is built. The connection:

```
wiki/attributes/greeting.md
  → documents HelloWorld::Hello_World dataset
    → retrieved via get_entity_profile(entity_id)
      → exposed at GET /entity/{id}?attributes=greeting
        → documented in dataimago-design/wiki/patterns/rest-api-from-r.md
```

Do not duplicate framework documentation here. Reference it.
