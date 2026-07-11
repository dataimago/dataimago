# `inst/schemas/`

JSON Schemas for the dataimago project spec (`dataimago-spec.yaml`).

## `dataimago-spec.v1alpha1.schema.json`

The `dataimago.ai/v1alpha1` project-spec schema. **Generated, not hand-authored** —
the authoritative Zod source is **`@dataimago/spec`** in
`dataimago-ai/packages/spec`. See the
`spec-to-artifact-bridge` ADR in `dataimago-design/wiki/decisions/`.

When `jsonvalidate` is installed, `ai(spec_path)` validates against this bundled
schema before running the lightweight structural checks in R (`validate_spec()`
in `R/ai_spec.R`). If the schema engine is unavailable, validation warns and
continues with the structural checks.

**Note:** the Zod schema's `.superRefine()` cross-field rule (`source.rPackage`
is null iff `source.case == "no-r"`) does **not** survive translation to JSON
Schema — `validate_spec()` re-checks it in R.

### Regenerating (cross-repo step)

From a **dataimago-ai** checkout, build the package and run its built
`dataimago-spec-json-schema` bin, pointing it at this R package:

```bash
pnpm --filter @dataimago/spec build
node packages/spec/dist/bin/generate-json-schema.js \
  --kind ProjectSpec \
  <path-to-dataimago-rpkg>/inst/schemas/dataimago-spec.v1alpha1.schema.json
```

then commit the updated file here. The version-stamped filename tracks the spec's
`apiVersion` (`v1alpha1` → `v1beta1` → `v1`).

The `ProjectSpec Bridge` CI workflow is the drift gate. It runs the published
package pinned by `DATAIMAGO_SPEC_PACKAGE` (currently
`@dataimago/spec@0.1.0-alpha.0`) from the public npm registry and uses
`--kind ProjectSpec --check` to require byte identity with the committed schema.
