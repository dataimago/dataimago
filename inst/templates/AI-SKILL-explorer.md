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
R package as an exploratory analytic engine for {{DOMAIN_NAME}}.

## What This Package Is

{{PACKAGE_TITLE}}

{{PACKAGE_DESCRIPTION}}

## When To Use

- Use for read-only exploration of approved attributes, dimensions, or datasets.
- Use when the user asks for help navigating available analyses or interpreting
  explorer outputs.
- Use before invoking generated MCP tools so the agent understands the available
  dimensions and privacy boundaries.

## When Not To Use

- Do not use private datasets without explicit approval.
- Do not infer causal or normative claims from exploratory outputs alone.
- Do not call internal helpers unless they are promoted to the public API.

## Safety Rules

- Default to read-only behavior.
- Respect dataset access and redistribution constraints.
- State what the exploration can and cannot support.

## Exported Functions

{{EXPORTED_FUNCTIONS}}

## Project Caveats

{{WIKI_CAUTIONS}}

## Related Artifacts

- `workflows.md` (in this skill) describes canonical task flows.
- `examples.md` (in this skill) links user intents to package calls.
- `KNOWLEDGE.md` explains how to maintain the explorer wiki.
- `wiki/` contains dimension definitions and interpretation rules.
- `public/api/mcp-schema.json` contains callable tools when MCP generation is
  enabled.
