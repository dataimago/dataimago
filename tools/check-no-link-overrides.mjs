#!/usr/bin/env node
/**
 * check-no-link-overrides.mjs
 *
 * Fail if `ui/package.json` ships `@dataimago/*` with `link:` or `file:`
 * overrides in `pnpm.overrides`. Those overrides are part of the
 * prototype-in-consumer loop (see `wiki/patterns/prototype-in-consumer.md`
 * in dataimago-design) and must never merge to `main`.
 *
 * Intended invocations:
 *   - CI (dataimago-rpkg/dataimago/.github/workflows/design-link-guard.yml)
 *   - Local dev: `node tools/check-no-link-overrides.mjs` from the rpkg root.
 *
 * This script is the symmetric partner of
 * dataimago-ai/tools/check-no-link-overrides.mjs (same contract, different
 * target package.json path).
 */
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const uiPackageJsonPath = resolve(__dirname, '..', 'ui', 'package.json');

if (!existsSync(uiPackageJsonPath)) {
  console.error(`❌ Expected ui/package.json at ${uiPackageJsonPath} — file not found.`);
  console.error('   Run this script from dataimago-rpkg/dataimago/ or via the CI workflow.');
  process.exit(2);
}

let pkg;
try {
  pkg = JSON.parse(readFileSync(uiPackageJsonPath, 'utf8'));
} catch (err) {
  console.error(`❌ Could not parse ${uiPackageJsonPath}: ${err.message}`);
  process.exit(2);
}

const overrides = pkg?.pnpm?.overrides ?? {};
const watchedPackages = [
  '@dataimago/tokens',
  '@dataimago/css',
  '@dataimago/ui',
];

const offending = watchedPackages
  .map((name) => [name, overrides[name]])
  .filter(([, value]) =>
    typeof value === 'string' &&
    (value.startsWith('link:') || value.startsWith('file:')),
  );

if (offending.length > 0) {
  console.error('❌ Local-link overrides detected in ui/package.json:');
  for (const [name, value] of offending) {
    console.error(`   ${name} → ${value}`);
  }
  console.error('');
  console.error('`link:` / `file:` overrides are development-only (see');
  console.error('`wiki/patterns/prototype-in-consumer.md` in dataimago-design).');
  console.error('Run `pnpm design:unlink` in ui/ before merging to main.');
  process.exit(1);
}

console.log('✅ No @dataimago/* link:/file: overrides on this branch.');
