# Bugbot review rules

Review the PR diff for changed-code correctness, security, regressions, missing
or weakened test coverage, schema/contract compatibility, and changed code that
undermines an explicit Tapestry Test or sensor contract. Report concrete,
actionable defects; do not turn style preferences or speculative redesigns into
findings.

## Repository contracts

- Check R behavior, conditions, roxygen documentation, exports, examples, and
  tests together when a public function changes.
- `ProjectSpec` authority lives in `@dataimago/spec`; the committed R-side JSON
  Schema is a derived, byte-gated bridge and must not drift or become canonical.
- Check generated TypeScript types, clients, API/MCP surfaces, and their
  downstream imports for compatible names and shapes.
- Generation and retrofit behavior must remain non-destructive: never overwrite
  user-authored source-package files or remove user control.
- Generated documentation, schemas, TypeScript, and build output are derived
  artifacts, not sources of truth.

## Alignment concern format

When a changed line conflicts with an explicit Tapestry or sensor contract,
title the finding `Alignment concern: <dimension_slug>` and include:

- `Dimension:` one of `foundation_traceability`,
  `emancipatory_usefulness`, `ai_in_culture_fit`,
  `democratic_revisability`, `dignity_accessibility_equity`, or
  `anti_domination_human_capability`
- `Location:` changed file and line
- `Contract/evidence:` the concrete R API, roxygen contract, schema, generated
  surface, test, rubric clause, or sensor evidence contradicted by the change
- `Impact:` the specific regression or risk
- `Corrective action:` the smallest verifiable repair

An Alignment concern is PR-level review feedback only. It is never a Tapestry
score or release decision.

## Boundaries

- Review the PR diff. Read unchanged code only when narrowly necessary to verify
  a contract used by a changed line.
- Do not assign Tapestry scores, decide `promote`/`hold`/`pause`, or approve,
  merge, publish, or deploy.
- Do not inspect or reproduce secrets. Do not read denied/private data or
  unpublished manuscript content. If a diff appears to expose a credential,
  report the exposure without quoting the value.
- Do not treat generated artifacts, alignment evidence, or a model proposal as
  authority over canonical R/spec sources or a human final review.

This file sets review instructions only. Bugbot effort and any available model
selection are team/UI configuration, not repository-rule settings. Bugbot is
the fast PR layer; the model-pinned Cloud Agent is the slow release-proposal
layer, and a human maintainer retains final authority. See the canonical
[Alignment Review Harness](https://github.com/dataimago/dataimago-design/blob/main/wiki/patterns/alignment-review-harness.md).
