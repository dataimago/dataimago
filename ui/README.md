# dataimago-rpkg UI assets

[![Package Manager](https://img.shields.io/badge/package%20manager-pnpm-orange.svg)](https://pnpm.io/)
[![Design system](https://img.shields.io/badge/%40dataimago%2Fdesign--system-Option%20B%20channels-blue.svg)](../../../dataimago-design/wiki/decisions/publish-packages.md)
[![R controlled](https://img.shields.io/badge/Controlled%20by-R%20Functions-red.svg)](../R/design_system.R)

This directory is a thin **consumer** of the `dataimago-design` system. It no
longer vendors SCSS, tokens, or Style Dictionary — all of that now lives in
published packages (see
[`publish-packages` ADR](../../../dataimago-design/wiki/decisions/publish-packages.md)
and [`consuming-the-design-system` onboarding](../../../dataimago-design/wiki/onboarding/consuming-the-design-system.md)).

## What runs here

`build.js` performs a four-stage copy/derive pipeline:

1. **Stage 1 — Pull** pre-built artifacts out of `node_modules/@dataimago/*`
   into `ui/dist/`:
   - `@dataimago/tokens` → `tokens.css`, `tokens.scss`
   - `@dataimago/css`    → `dataimago.css`, `dataimago.min.css`, `tailwind-preset.js`
2. **Stage 2 — Derive** Quarto theme files (`dataimago-light.scss`,
   `dataimago-dark.scss`) and the `website-theme.css` / `website-theme.min.css`
   aliases locally from the installed tokens. These filenames are contractual:
   `R/design_system.R` and `inst/quarto-assets/` assume them.
3. **Stage 3 — Copy** the optional `@dataimago-ui/components` ESM+CJS bundle
   into `ui/dist/js/dataimago-ui/` if the package is installed.
4. **Stage 4 — Distribute** `ui/dist/` into the four consumer channels that
   the R package exposes:
   - `inst/quarto-assets/`   — CDN distribution (jsDelivr)
   - `ui/www/assets/css/`    — local website preview
   - `ui/www/_extensions/dataimago/ai-native/assets/css/` — Quarto extension
   - `docs/assets/css/`      — rendered docs site
5. A final smoke check refuses to proceed unless every contractual file is
   present.

A `manifest.json` capturing the installed package versions and the dist file
list is written alongside the CSS so the R side can cite provenance.

## Prerequisites

- **pnpm** (this `ui/` directory is not a pnpm workspace root; it has its own
  lockfile so R-side tooling can install assets deterministically).
- `.npmrc` in this directory maps `@dataimago/*` to public npm and
  `@dataimago-ui/*` to GitHub Packages. Set `GITHUB_PACKAGES_TOKEN` (with at
  least `read:packages`) before `pnpm install`.

```bash
export GITHUB_PACKAGES_TOKEN=<github PAT with read:packages>
pnpm install
pnpm build
```

## Prototyping against a local dataimago-design checkout

The release loop (ship packages → bump here) is deliberate. For fast
iteration, drop into "prototype-in-consumer" mode:

```bash
export DATAIMAGO_DESIGN_PATH=/abs/path/to/dataimago-design
pnpm design:link    # writes link: overrides into ui/package.json + reinstalls
pnpm build          # now rebuilds against the local design checkout
pnpm design:unlink  # restore registry versions before committing / CI
```

`design:link` wraps `../tools/design-link.mjs`, which edits
`ui/package.json`'s `pnpm.overrides`. **Those overrides must never land on
`main`** — the rpkg CI (and the parallel guard in `dataimago-ai`) fails any
branch that tries to merge a `link:` or `file:` override for a `@dataimago/*`
package. See `wiki/patterns/prototype-in-consumer.md` in `dataimago-design`
for the end-to-end workflow.

## R-side contract

R functions in `R/design_system.R`, `R/asset_sync.R`, and
`R/build_framework.R` assume these filenames exist in `ui/dist/` and in
`inst/quarto-assets/` after a successful `pnpm build`:

- `tokens.css`, `tokens.scss`
- `dataimago.css`, `dataimago.min.css`
- `dataimago-light.scss`, `dataimago-dark.scss`
- `website-theme.css`, `website-theme.min.css`
- `manifest.json`

If you add new assets, teach `build.js` to write them, update the critical
asset smoke check, and then teach the R consumers — in that order. Breaking
this contract will silently 404 the Quarto + CDN distribution.

## Related docs

- `dataimago-design` — [`consuming-the-design-system`](../../../dataimago-design/wiki/onboarding/consuming-the-design-system.md)
- `dataimago-design` — [`publish-packages` ADR](../../../dataimago-design/wiki/decisions/publish-packages.md)
- `dataimago-ai` — `ARCHITECTURE.md` §"Consuming `dataimago-design` — two channels"
