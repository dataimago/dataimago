#!/usr/bin/env node
/**
 * dataimago-rpkg UI build script — package-channel edition.
 *
 * Consumes the design system from three installed packages instead of the
 * retired `ui/src/dataimago-design` git submodule + two-stage build:
 *
 *   - @dataimago/tokens → canonical token JSON, tokens.css, tokens.scss
 *   - @dataimago/css    → dataimago.css, dataimago.min.css, tailwind-preset
 *   - @dataimago/ui     → React component bundle (ESM + CJS)
 *
 * All three packages ship from public npm under the unified `@dataimago/*`
 * scope, matching the registry posture of `dataimago-ai`.
 *
 * Output file names are preserved bit-for-bit where the R side expects them
 * (inst/quarto-assets/, docs/assets/, etc.) so that `dataimago::` exports
 * and Shiny UI helpers continue to resolve the same paths after the
 * submodule removal. Any artifact not yet shipped by a package (for
 * example, Quarto dataimago-{light,dark}.scss) is derived locally from the
 * installed tokens.
 *
 * Prerequisites:
 *   1. `pnpm install` has been run in `ui/` so node_modules/@dataimago/* are
 *      present. `.npmrc` pins the `@dataimago` scope to public npm; no
 *      auth token is needed for read access.
 *   2. To prototype design-system changes without republishing, run
 *      `DATAIMAGO_DESIGN_PATH=... node tools/design-link.mjs link`
 *      at the repo root, then re-run this script.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const uiDir = __dirname;
const rpkgRoot = path.join(uiDir, '..');
const distDir = path.join(uiDir, 'dist');
const nodeModulesDir = path.join(uiDir, 'node_modules');

const packages = {
  tokens:     path.join(nodeModulesDir, '@dataimago', 'tokens'),
  css:        path.join(nodeModulesDir, '@dataimago', 'css'),
  components: path.join(nodeModulesDir, '@dataimago', 'ui'),
};

function requirePkg(name, absPath, { required = true } = {}) {
  if (!fs.existsSync(absPath)) {
    const msg = `❌ Missing design package: ${name} at ${absPath}`;
    if (required) {
      console.error(msg);
      console.error('   Run `pnpm install` in ui/ first. See ui/README.md.');
      process.exit(1);
    }
    console.warn('⚠️  Optional package not installed:', name);
    return false;
  }
  return true;
}

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function copyFile(src, dest) {
  ensureDir(path.dirname(dest));
  fs.copyFileSync(src, dest);
}

function copyRecursive(src, dest) {
  const stats = fs.statSync(src);
  if (stats.isDirectory()) {
    ensureDir(dest);
    for (const item of fs.readdirSync(src)) {
      copyRecursive(path.join(src, item), path.join(dest, item));
    }
  } else {
    copyFile(src, dest);
  }
}

function copyIfExists(src, dest) {
  if (fs.existsSync(src)) {
    copyFile(src, dest);
    return true;
  }
  return false;
}

console.log('🚀 dataimago-rpkg UI build — consuming @dataimago packages from node_modules');

requirePkg('@dataimago/tokens', packages.tokens);
requirePkg('@dataimago/css',    packages.css);
requirePkg('@dataimago/ui',     packages.components, { required: false });

ensureDir(distDir);

// ─── Stage 1: tokens + CSS → dist/ ─────────────────────────────────────────
console.log('📦 Stage 1: assembling dist/ from installed packages');

const cssDist = path.join(packages.css, 'dist');
const tokensDist = path.join(packages.tokens, 'dist');

const cssArtifacts = [
  ['tokens.css',         path.join(tokensDist, 'tokens.css')],
  ['tokens.scss',        path.join(tokensDist, 'tokens.scss')],
  ['dataimago.css',      path.join(cssDist,    'dataimago.css')],
  ['dataimago.min.css',  path.join(cssDist,    'dataimago.min.css')],
  ['tailwind-preset.js', path.join(cssDist,    'tailwind-preset.js')],
];

for (const [destName, src] of cssArtifacts) {
  if (copyIfExists(src, path.join(distDir, destName))) {
    console.log('   ✓', destName);
  } else {
    console.warn('   ⚠️  missing in package:', destName, '←', src);
  }
}

// ─── Stage 2: derived Quarto + website-theme artifacts ─────────────────────
//
// The R side still expects `dataimago-light.scss`, `dataimago-dark.scss`,
// `website-theme.css`, and `website-theme.min.css`. These are not yet
// emitted by any package — we synthesize them here from the installed
// tokens. When the design packages start shipping them directly, these
// branches become simple copies.
console.log('🪶 Stage 2: deriving Quarto themes + website-theme aliases');

const tokensIndex = require(path.join(packages.tokens, 'dist', 'index.cjs'));
const palette = tokensIndex?.palette ?? {};

function shade(scale, step, fallback) {
  const v = palette?.[scale]?.[String(step)];
  return typeof v === 'string' ? v : fallback;
}

const lightScss = [
  '/*-- scss:defaults --*/',
  `$body-bg: ${shade('cream', 100, '#fdf9f2')};`,
  `$body-color: ${shade('ink', 900, '#0c0a09')};`,
  `$link-color: ${shade('copper', 500, '#d46820')};`,
  `$primary: ${shade('accent', 500, '#b54a27')};`,
  `$code-color: ${shade('copper', 700, '#913d15')};`,
  '',
].join('\n');

const darkScss = [
  '/*-- scss:defaults --*/',
  `$body-bg: ${shade('ink', 900, '#0c0a09')};`,
  `$body-color: ${shade('cream', 100, '#fdf9f2')};`,
  `$link-color: ${shade('copper', 400, '#ea8441')};`,
  `$primary: ${shade('accent', 500, '#b54a27')};`,
  `$code-color: ${shade('copper', 300, '#f0a467')};`,
  '',
].join('\n');

fs.writeFileSync(path.join(distDir, 'dataimago-light.scss'), lightScss);
fs.writeFileSync(path.join(distDir, 'dataimago-dark.scss'),  darkScss);
console.log('   ✓ dataimago-light.scss');
console.log('   ✓ dataimago-dark.scss');

if (fs.existsSync(path.join(distDir, 'dataimago.css'))) {
  fs.copyFileSync(
    path.join(distDir, 'dataimago.css'),
    path.join(distDir, 'website-theme.css'),
  );
  console.log('   ✓ website-theme.css (aliased to dataimago.css)');
}
if (fs.existsSync(path.join(distDir, 'dataimago.min.css'))) {
  fs.copyFileSync(
    path.join(distDir, 'dataimago.min.css'),
    path.join(distDir, 'website-theme.min.css'),
  );
  console.log('   ✓ website-theme.min.css (aliased to dataimago.min.css)');
}

// ─── Stage 3: component JS bundle (optional) ───────────────────────────────
console.log('🧩 Stage 3: @dataimago/ui bundle');

const componentsJsDir = path.join(distDir, 'js', 'dataimago-ui');
if (fs.existsSync(packages.components)) {
  const componentsDist = path.join(packages.components, 'dist');
  if (fs.existsSync(componentsDist)) {
    copyRecursive(componentsDist, componentsJsDir);
    console.log('   ✓ dist/js/dataimago-ui/ populated');
  } else {
    console.warn('   ⚠️  @dataimago/ui has no dist/ — skipping JS copy');
  }
} else {
  console.log('   (skipped — @dataimago/ui not installed)');
}

// ─── Stage 4: manifest.json (stable shape; R side parses this) ─────────────
const manifest = {
  name: '@dataimago/design-system',
  builtAt: new Date().toISOString(),
  builtBy: 'ui/build.js (package-channel)',
  sources: {
    '@dataimago/tokens': readPkgVersion(packages.tokens),
    '@dataimago/css':    readPkgVersion(packages.css),
    '@dataimago/ui':     readPkgVersion(packages.components),
  },
  artifacts: fs.readdirSync(distDir).sort(),
};
fs.writeFileSync(
  path.join(distDir, 'manifest.json'),
  JSON.stringify(manifest, null, 2) + '\n',
);
console.log('📝 manifest.json written');

function readPkgVersion(pkgDir) {
  const pkgJson = path.join(pkgDir, 'package.json');
  if (!fs.existsSync(pkgJson)) return null;
  try {
    return JSON.parse(fs.readFileSync(pkgJson, 'utf8')).version ?? null;
  } catch {
    return null;
  }
}

// ─── Stage 5: distribute assets to consumer channels ───────────────────────
// The channel layout mirrors what the R exports in `inst/quarto-assets/`
// and the Shiny UI helpers in `ui/www/` expect. File names are preserved.
console.log('📦 Stage 5: fanning assets out to consumer channels');

const cssChannels = [
  {
    name: 'CDN assets (inst/quarto-assets/)',
    path: path.join(rpkgRoot, 'inst', 'quarto-assets'),
    files: [
      'tokens.css', 'tokens.scss',
      'dataimago.css', 'dataimago.min.css',
      'website-theme.css', 'website-theme.min.css',
      'dataimago-light.scss', 'dataimago-dark.scss',
    ],
  },
  {
    name: 'Website CSS (ui/www/assets/css/)',
    path: path.join(uiDir, 'www', 'assets', 'css'),
    files: 'all',
  },
  {
    name: 'Quarto extension (ui/www/_extensions/dataimago/ai-native/assets/css/)',
    path: path.join(uiDir, 'www', '_extensions', 'dataimago', 'ai-native', 'assets', 'css'),
    files: 'all',
  },
  {
    name: 'Docs CSS (docs/assets/css/)',
    path: path.join(rpkgRoot, 'docs', 'assets', 'css'),
    files: ['tokens.css', 'dataimago.css', 'dataimago.min.css'],
  },
];

for (const channel of cssChannels) {
  ensureDir(channel.path);
  let copied = 0;

  const distFiles = fs.readdirSync(distDir);
  const files = channel.files === 'all'
    ? distFiles.filter((f) => /\.(css|scss|map)$/.test(f))
    : channel.files;

  for (const file of files) {
    const src = path.join(distDir, file);
    if (fs.existsSync(src)) {
      copyFile(src, path.join(channel.path, file));
      copied += 1;
    }
  }
  console.log(`   ✓ ${channel.name} (${copied} assets)`);
}

// JS channels — fan out the components bundle under a stable subdir.
if (fs.existsSync(componentsJsDir)) {
  const jsChannels = [
    path.join(uiDir, 'www', 'assets', 'js', 'dataimago-ui'),
    path.join(uiDir, 'www', '_extensions', 'dataimago', 'ai-native', 'assets', 'js', 'dataimago-ui'),
    path.join(rpkgRoot, 'docs', 'assets', 'js', 'dataimago-ui'),
  ];
  for (const dest of jsChannels) {
    ensureDir(dest);
    copyRecursive(componentsJsDir, dest);
    console.log(`   ✓ ${path.relative(rpkgRoot, dest)}`);
  }
}

// ─── Stage 6: critical-asset smoke check ───────────────────────────────────
const critical = [
  'tokens.css',
  'dataimago.css',
  'dataimago.min.css',
  'dataimago-light.scss',
  'dataimago-dark.scss',
  'website-theme.css',
  'website-theme.min.css',
  'manifest.json',
];
const missing = critical.filter((f) => !fs.existsSync(path.join(distDir, f)));
if (missing.length > 0) {
  console.error('❌ Missing critical assets:', missing.join(', '));
  process.exit(1);
}
console.log('✅ All critical assets present in', path.relative(rpkgRoot, distDir));
console.log('\n🎉 UI build complete.');
