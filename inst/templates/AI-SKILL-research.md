---
name: {{SKILL_NAME}}
description: "{{{SKILL_DESCRIPTION}}}"
metadata:
  curated: false
  generator: dataimago-rpkg
  generator_version: {{GENERATOR_VERSION}}
---

# {{PROJECT_NAME}} AI Skill

Use this skill when an AI agent needs to understand or use the {{PACKAGE_NAME}}
R package as a research analytic engine for {{DOMAIN_NAME}}.

## What This Package Is

{{PACKAGE_TITLE}}

{{PACKAGE_DESCRIPTION}}

## When To Use

- Use for read-only analytic tasks tied to the research question or evidence
  base.
- Use when the user asks for help connecting package outputs to claims,
  findings, or limitations.
- Use before invoking generated MCP tools so the agent understands the research
  vocabulary and evidentiary boundaries.

## When Not To Use

- Do not use private or embargoed research data without explicit approval.
- Do not convert exploratory or prototype outputs into settled findings.
- Do not call internal helpers unless they are promoted to the public API.

## Safety Rules

- Default to read-only behavior.
- Preserve the distinction between evidence, interpretation, and speculation.
- Report uncertainty and scope limits with every result.

## Exported Functions

{{EXPORTED_FUNCTIONS}}

## Project Caveats

{{WIKI_CAUTIONS}}

## Related Artifacts

- `workflows.md` (in this skill) describes canonical task flows.
- `examples.md` (in this skill) links user intents to package calls.
- `KNOWLEDGE.md` explains how to maintain the research wiki.
- `wiki/` contains source summaries, analyses, and interpretation rules.
- `public/api/mcp-schema.json` contains callable tools when MCP generation is
  enabled.
