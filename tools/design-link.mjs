#!/usr/bin/env node
/**
 * tools/design-link.mjs — switch the three @dataimago design packages
 * consumed by `ui/` to a local checkout of `dataimago-design`.
 *
 * Usage (run from the repo root or from ui/ via `pnpm design:link`):
 *   DATAIMAGO_DESIGN_PATH=/abs/path/to/dataimago-design \
 *     node tools/design-link.mjs link
 *   node tools/design-link.mjs unlink
 *   node tools/design-link.mjs status
 *
 * What it does:
 *   - Writes a `pnpm.overrides` block into `ui/package.json` mapping
 *     @dataimago/tokens, @dataimago/css, @dataimago-ui/components to
 *     `link:<DATAIMAGO_DESIGN_PATH>/packages/{tokens,css,components}`.
 *   - Runs `pnpm install` inside `ui/` so the link targets take effect.
 *   - `unlink` strips the overrides and reinstalls against registry
 *     versions.
 *
 * Contract: `link:` / `file:` overrides are development-only. Consumer
 * CI must refuse them on `main` (mirrors the dataimago-ai design-link
 * guard). See wiki/patterns/prototype-in-consumer.md.
 */
import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const uiDir = path.join(repoRoot, 'ui');
const pkgJsonPath = path.join(uiDir, 'package.json');

const PACKAGES = {
  '@dataimago/tokens': 'packages/tokens',
  '@dataimago/css': 'packages/css',
  '@dataimago-ui/components': 'packages/components',
};

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function writeJson(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
}

function runInUi(cmd) {
  execSync(cmd, { cwd: uiDir, stdio: 'inherit' });
}

function link() {
  const designPath = process.env.DATAIMAGO_DESIGN_PATH;
  if (!designPath) {
    console.error('❌ DATAIMAGO_DESIGN_PATH is not set.');
    console.error('   Point it at your local dataimago-design checkout, e.g.:');
    console.error('   DATAIMAGO_DESIGN_PATH=/Users/you/GitHub/dataimago-design pnpm design:link');
    process.exit(1);
  }
  const abs = path.resolve(designPath);
  if (!fs.existsSync(abs)) {
    console.error(`❌ DATAIMAGO_DESIGN_PATH does not exist: ${abs}`);
    process.exit(1);
  }
  for (const [name, rel] of Object.entries(PACKAGES)) {
    const target = path.join(abs, rel);
    if (!fs.existsSync(target)) {
      console.error(`❌ Missing ${name} source at ${target}.`);
      process.exit(1);
    }
  }

  const pkg = readJson(pkgJsonPath);
  pkg.pnpm = pkg.pnpm ?? {};
  pkg.pnpm.overrides = pkg.pnpm.overrides ?? {};
  for (const [name, rel] of Object.entries(PACKAGES)) {
    pkg.pnpm.overrides[name] = `link:${path.join(abs, rel)}`;
  }
  writeJson(pkgJsonPath, pkg);

  console.log('🔗 Linked @dataimago/* packages in ui/package.json to:', abs);
  console.log('\n📦 Running `pnpm install` in ui/ to apply overrides…\n');
  runInUi('pnpm install');
  console.log('\n✅ Done. Run `pnpm design:unlink` (from ui/) to switch back.');
}

function unlink() {
  const pkg = readJson(pkgJsonPath);
  const overrides = pkg?.pnpm?.overrides;
  if (!overrides) {
    console.log('No pnpm.overrides in ui/package.json; nothing to unlink.');
    return;
  }
  let removed = 0;
  for (const name of Object.keys(PACKAGES)) {
    if (overrides[name] && String(overrides[name]).startsWith('link:')) {
      delete overrides[name];
      removed += 1;
    }
  }
  if (removed === 0) {
    console.log('No @dataimago/* link: overrides found; nothing to unlink.');
    return;
  }
  if (Object.keys(overrides).length === 0) {
    delete pkg.pnpm.overrides;
    if (Object.keys(pkg.pnpm).length === 0) delete pkg.pnpm;
  }
  writeJson(pkgJsonPath, pkg);
  console.log(`🔓 Removed ${removed} @dataimago/* link: override(s) from ui/package.json.`);
  console.log('\n📦 Running `pnpm install` in ui/ to restore registry versions…\n');
  runInUi('pnpm install');
}

function status() {
  const pkg = readJson(pkgJsonPath);
  const overrides = pkg?.pnpm?.overrides ?? {};
  const linked = Object.entries(overrides)
    .filter(([name, spec]) =>
      PACKAGES[name] && typeof spec === 'string' && spec.startsWith('link:'),
    );
  if (linked.length === 0) {
    console.log('🟢 Unlinked. ui/ consumes @dataimago/* from the registry.');
    return;
  }
  console.log('🔗 Linked overrides in ui/package.json:');
  for (const [name, spec] of linked) console.log(`   ${name} → ${spec}`);
}

const cmd = process.argv[2];
switch (cmd) {
  case 'link':   link(); break;
  case 'unlink': unlink(); break;
  case 'status': status(); break;
  default:
    console.error('Usage: node tools/design-link.mjs {link|unlink|status}');
    process.exit(1);
}
