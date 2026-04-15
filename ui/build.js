#!/usr/bin/env node
/**
 * dataimago Design System Build Script - Two-Stage Architecture
 * 
 * This optimized build script implements a two-stage build process:
 * 1. Stage 1: Universal build (no PurgeCSS) → submodule/dist/ 
 * 2. Stage 2: Optimized build (with PurgeCSS) → consumer/dist/
 * 
 * Key benefits:
 * - Maintains source of truth in dataimago-design submodule
 * - Generates both universal and website-optimized assets
 * - Eliminates duplicate build logic
 * - Supports idempotent builds
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const config = {
  // Local paths
  distDir: path.join(__dirname, 'dist'),
  
  // Source repository paths (git submodule)
  sourceRepo: path.join(__dirname, 'src', 'dataimago-design'),
  sourceDistDir: path.join(__dirname, 'src', 'dataimago-design', 'dist'),
  
  // Distribution channels in consumer repo
  distributionChannels: [
    {
      name: 'CDN Assets (inst/quarto-assets/)',
      path: path.join(__dirname, '..', 'inst', 'quarto-assets'),
      files: ['tokens.css', 'tokens.scss', 'dataimago.css', 'dataimago.min.css', 'website-theme.css', 'website-theme.min.css', 'dataimago-light.scss', 'dataimago-dark.scss']
    },
    {
      name: 'Website Assets (ui/www/assets/css/)',
      path: path.join(__dirname, 'www', 'assets', 'css'),
      files: 'all' // Copy all CSS/SCSS files
    },
    {
      name: 'Quarto Extension (ui/www/_extensions/dataimago/ai-native/assets/css/)',
      path: path.join(__dirname, 'www', '_extensions', 'dataimago', 'ai-native', 'assets', 'css'),
      files: 'all'
    },
    {
      name: 'Docs Assets (docs/assets/css/)',
      path: path.join(__dirname, '..', 'docs', 'assets', 'css'),
      files: ['tokens.css', 'dataimago.css', 'dataimago.min.css', 'documentation.css', 'landing.css']
    }
  ],
  
  // SVG Icon distribution channels
  iconChannels: [
    {
      name: 'Website Icons (ui/www/assets/img/)',
      path: path.join(__dirname, 'www', 'assets', 'img')
    },
    {
      name: 'Extension Icons (ui/www/_extensions/dataimago/ai-native/assets/img/)',
      path: path.join(__dirname, 'www', '_extensions', 'dataimago', 'ai-native', 'assets', 'img')
    },
    {
      name: 'Docs Icons (docs/assets/img/)',
      path: path.join(__dirname, '..', 'docs', 'assets', 'img')
    }
  ]
};

console.log('🚀 dataimago: Two-stage build process starting...');

// Step 1: Ensure source repository exists
if (!fs.existsSync(config.sourceRepo)) {
  console.error('❌ Source repository not found at:', config.sourceRepo);
  console.log('💡 Make sure the git submodule is initialized:');
  console.log('   git submodule update --init --recursive');
  process.exit(1);
}

// Step 2: Execute two-stage build in source repository
console.log('🛠️  Building design system in source repository...');
try {
  // Change to source directory
  process.chdir(config.sourceRepo);
  
  // Install dependencies if needed
  if (!fs.existsSync(path.join(config.sourceRepo, 'node_modules'))) {
    console.log('📦 Installing source repository dependencies...');
    execSync('pnpm install', { stdio: 'inherit' });
  }
  
  // Check if build-core.mjs exists for two-stage build
  const buildCorePath = path.join('tools', 'build-core.mjs');
  if (fs.existsSync(buildCorePath)) {
    // Use the two-stage build process (preferred method)
    console.log('🔧 Using two-stage build process...');
    const consumerDistPath = path.resolve(__dirname, 'dist');
    console.log(`🎯 Running two-stage build: consumer dist → ${consumerDistPath}`);
    execSync(`node -e "import('./tools/build-core.mjs').then(m => m.buildTwoStage('${consumerDistPath}'))"`, { stdio: 'inherit' });
  } else {
    // Fallback: Use legacy build script
    console.log('🔧 Using legacy build script...');
    const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    if (packageJson.scripts && packageJson.scripts.build) {
      execSync('pnpm build', { stdio: 'inherit' });
    } else {
      throw new Error('No build script available in source repository');
    }
  }
  
  // Change back to consumer directory
  process.chdir(path.join(__dirname));
  
  console.log('✅ Source repository build completed');
} catch (error) {
  console.error('❌ Source repository build failed:', error.message);
  process.exit(1);
}

// Step 3: Verify build outputs
console.log('📁 Verifying build outputs...');

// Verify source dist (universal assets)
if (!fs.existsSync(config.sourceDistDir)) {
  console.error('❌ Source dist directory not found:', config.sourceDistDir);
  process.exit(1);
}

// Verify consumer dist (optimized assets)
if (!fs.existsSync(config.distDir)) {
  console.error('❌ Consumer dist directory not found:', config.distDir);
  console.error('This suggests the two-stage build process failed');
  process.exit(1);
}

const sourceAssets = fs.readdirSync(config.sourceDistDir);
const consumerAssets = fs.readdirSync(config.distDir);

console.log(`📊 Source dist: ${sourceAssets.length} universal assets`);
console.log(`📊 Consumer dist: ${consumerAssets.length} optimized assets`);

// Utility function for recursive copying
function copyRecursive(src, dest) {
  const stats = fs.statSync(src);
  
  if (stats.isDirectory()) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    
    const items = fs.readdirSync(src);
    items.forEach(item => {
      copyRecursive(path.join(src, item), path.join(dest, item));
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

// Step 4: Distribute assets to all channels
console.log('📦 Distributing assets to consumer repository locations...');

config.distributionChannels.forEach(channel => {
  // Ensure target directory exists
  if (!fs.existsSync(channel.path)) {
    fs.mkdirSync(channel.path, { recursive: true });
  }
  
  let copiedCount = 0;
  
  if (channel.files === 'all') {
    // Copy all CSS/SCSS files from consumer dist (optimized)
    const allFiles = fs.readdirSync(config.distDir);
    
    allFiles.forEach(file => {
      const srcPath = path.join(config.distDir, file);
      const destPath = path.join(channel.path, file);
      const stats = fs.statSync(srcPath);
      
      if (stats.isDirectory()) {
        // Handle directories (like js/)
        if (file === 'js' && channel.name.includes('css')) {
          // Don't copy JS to CSS directories
          return;
        }
        copyRecursive(srcPath, destPath);
        copiedCount++;
      } else if (file.endsWith('.css') || file.endsWith('.scss') || file.endsWith('.map')) {
        fs.copyFileSync(srcPath, destPath);
        copiedCount++;
      }
    });
  } else {
    // Copy specific files from consumer dist (optimized)
    channel.files.forEach(file => {
      const srcPath = path.join(config.distDir, file);
      const destPath = path.join(channel.path, file);
      
      if (fs.existsSync(srcPath)) {
        fs.copyFileSync(srcPath, destPath);
        copiedCount++;
      }
    });
  }
  
  console.log(`   ✓ ${channel.name} (${copiedCount} assets)`);
});

// Step 4.5: Distribute SVG icon assets
console.log('🎨 Distributing SVG icons to consumer repository locations...');

const iconsSourceDir = path.join(config.distDir, 'icons');
if (fs.existsSync(iconsSourceDir)) {
  config.iconChannels.forEach(channel => {
    // Ensure target directory exists
    if (!fs.existsSync(channel.path)) {
      fs.mkdirSync(channel.path, { recursive: true });
    }
    
    let copiedCount = 0;
    
    // Copy SVG icons from dist/icons/ to target, flattening structure for web use
    function copyIconsFlat(src, dest) {
      const items = fs.readdirSync(src);
      items.forEach(item => {
        const srcPath = path.join(src, item);
        const stats = fs.statSync(srcPath);
        if (stats.isDirectory()) {
          copyIconsFlat(srcPath, dest); // Recurse but keep flat structure
        } else if (item.endsWith('.svg')) {
          fs.copyFileSync(srcPath, path.join(dest, item));
          copiedCount++;
        }
      });
    }
    
    copyIconsFlat(iconsSourceDir, channel.path);
    console.log(`   ✓ ${channel.name} (${copiedCount} SVG icons)`);
  });
} else {
  console.log('⚠️  No icons found in dist/ - SVG assets may not have been built');
}

// Step 5: Handle JavaScript assets separately
const jsChannels = [
  {
    name: 'Website JS (ui/www/assets/js/)',
    path: path.join(__dirname, 'www', 'assets', 'js')
  },
  {
    name: 'Extension JS (ui/www/_extensions/dataimago/ai-native/assets/js/)',
    path: path.join(__dirname, 'www', '_extensions', 'dataimago', 'ai-native', 'assets', 'js')
  },
  {
    name: 'Docs JS (docs/assets/js/)',
    path: path.join(__dirname, '..', 'docs', 'assets', 'js')
  }
];

const jsSourceDir = path.join(config.distDir, 'js');
if (fs.existsSync(jsSourceDir)) {
  jsChannels.forEach(channel => {
    if (!fs.existsSync(channel.path)) {
      fs.mkdirSync(channel.path, { recursive: true });
    }
    
    copyRecursive(jsSourceDir, channel.path);
    
    // Count JS files for reporting
    function countJSFiles(dir) {
      let count = 0;
      const items = fs.readdirSync(dir);
      items.forEach(item => {
        const itemPath = path.join(dir, item);
        const stats = fs.statSync(itemPath);
        if (stats.isDirectory()) {
          count += countJSFiles(itemPath);
        } else if (item.endsWith('.js')) {
          count++;
        }
      });
      return count;
    }
    
    const jsCount = countJSFiles(channel.path);
    console.log(`   ✓ ${channel.name} (${jsCount} JS files)`);
  });
}

// Step 6: Build Summary
console.log('📊 Two-Stage Build Summary:');

// Show source assets (universal)
console.log('🌍 Universal Assets (submodule/dist/):');
sourceAssets.forEach(file => {
  const filePath = path.join(config.sourceDistDir, file);
  const stats = fs.statSync(filePath);
  
  if (stats.isFile() && file.endsWith('.css')) {
    const sizeKB = Math.round(stats.size / 1024 * 100) / 100;
    console.log(`   📦 ${file} (${sizeKB} KB)`);
  }
});

// Show consumer assets (optimized)
console.log('🎯 Optimized Assets (consumer/dist/):');
consumerAssets.forEach(file => {
  const filePath = path.join(config.distDir, file);
  const stats = fs.statSync(filePath);
  
  if (stats.isFile() && file.endsWith('.css')) {
    const sizeKB = Math.round(stats.size / 1024 * 100) / 100;
    console.log(`   ⚡ ${file} (${sizeKB} KB)`);
  } else if (stats.isDirectory()) {
    const dirFiles = fs.readdirSync(filePath).length;
    console.log(`   📁 ${file}/ (${dirFiles} files)`);
  }
});

// Step 7: Verify critical assets exist
const criticalAssets = [
  'tokens.css',
  'dataimago.css',
  'dataimago.min.css',
  'dataimago-light.scss',
  'dataimago-dark.scss',
  'website-theme.css',
  'website-theme.min.css',
  'manifest.json'
];

console.log('🔍 Verifying critical assets...');
const missingAssets = criticalAssets.filter(asset => !fs.existsSync(path.join(config.distDir, asset)));

if (missingAssets.length > 0) {
  console.warn('⚠️  Missing critical assets:', missingAssets.join(', '));
} else {
  console.log('✅ All critical assets present');
}

// Step 8: Git submodule status (optional)
try {
  const submoduleStatus = execSync('git submodule status', { 
    encoding: 'utf8', 
    cwd: path.join(__dirname, '..') 
  });
  console.log('📋 Submodule status:', submoduleStatus.trim());
} catch (error) {
  // Ignore git errors - not critical for build
}

console.log('\n🎉 Two-stage dataimago design system build complete!');
console.log('📈 Architecture Benefits:');
console.log('   🌍 Universal assets: Available for external distribution');
console.log('   ⚡ Optimized assets: PurgeCSS applied for website performance');
console.log('   🎯 Single source of truth: Maintained in dataimago-design');
console.log('   🔄 Idempotent builds: Consistent results across environments');
console.log('🛡️  Ethical AI design system ready for deployment!');