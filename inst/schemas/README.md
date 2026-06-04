# `inst/schemas/`

JSON Schemas for the dataimago project spec (`dataimago-spec.yaml`).

## `dataimago-spec.v1alpha1.schema.json`

The `dataimago.ai/v1alpha1` project-spec schema. **Generated, not hand-authored** —
the source of truth is the Zod schema in **dissertation-ai**
(`apps/hub/src/lib/spec/schema.ts`). See the
`spec-to-artifact-bridge` ADR in `dataimago-design/wiki/decisions/`.

This release carries the schema for **reference/documentation**. `ai(spec_path)`
validates specs with lightweight structural checks in R (`validate_spec()` in
`R/ai_spec.R`), not against this file. A later chunk may add full JSON-Schema
validation (e.g. via `jsonvalidate`) against it.

**Note:** the Zod schema's `.superRefine()` cross-field rule (`source.rPackage`
is null iff `source.case == "no-r"`) does **not** survive translation to JSON
Schema — `validate_spec()` re-checks it in R.

### Regenerating (cross-repo step)

From a **dissertation-ai** checkout:

```bash
pnpm --filter @dataimago/dissertation-hub generate-spec-schema \
  <path-to-dataimago>/inst/schemas/dataimago-spec.v1alpha1.schema.json
```

then commit the updated file here. The version-stamped filename tracks the spec's
`apiVersion` (`v1alpha1` → `v1beta1` → `v1`).
