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
R package as an analytic engine for {{DOMAIN_NAME}}.

## What This Package Is

{{PACKAGE_TITLE}}

{{PACKAGE_DESCRIPTION}}

## When To Use

- Use for read-only analytic tasks grounded in the package's exported functions.
- Use when the user asks for help interpreting {{DOMAIN_NAME}} outputs.
- Use before invoking generated MCP tools so the agent understands the domain
  vocabulary, caveats, and safe workflow.

## When Not To Use

- Do not use with private data unless the user confirms the local environment is
  approved for that data.
- Do not call internal helpers unless a package maintainer explicitly promotes
  them to the public API.
- Do not treat prototype outputs as production estimates.

## Safety Rules

- Default to read-only behavior.
- Respect private data boundaries.
- Prefer exported functions and generated tools.
- Report limitations and prototype status alongside results.

## Exported Functions

{{EXPORTED_FUNCTIONS}}

## Project Caveats

{{WIKI_CAUTIONS}}

## Related Artifacts

- `workflows.md` (in this skill) describes canonical task flows.
- `examples.md` (in this skill) links user intents to package calls.
- `KNOWLEDGE.md` explains how to maintain the domain wiki.
- `wiki/` contains curated domain memory and interpretation rules.
- `public/api/mcp-schema.json` contains callable tools when MCP generation is
  enabled.
