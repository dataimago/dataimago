#!/usr/bin/env node
/**
 * Optimized dataimago Design System Build Script for Consumer Repository
 * 
 * This streamlined build script leverages the source repository's build process
 * and focuses on asset distribution rather than duplication of build logic.
 * 
 * Key improvements:
 * 1. Triggers build in source repository (dataimago-design submodule)
 * 2. Copies assets from source dist/ to local dist/
 * 3. Distributes assets to all required locations in consumer repo
 * 4. Eliminates 1000+ lines of duplicate build logic
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
      files: ['tokens.css', 'dataimago.css', 'dataimago.min.css', 'website-theme.css', 'dataimago-light.scss', 'dataimago-dark.scss']
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
  ]
};

console.log('🚀 dataimago: Optimized build process starting...');

// Step 1: Ensure source repository exists
if (!fs.existsSync(config.sourceRepo)) {
  console.error('❌ Source repository not found at:', config.sourceRepo);
  console.log('💡 Make sure the git submodule is initialized:');
  console.log('   git submodule update --init --recursive');
  process.exit(1);
}

// Step 2: Trigger build in source repository
console.log('🛠️  Building design system in source repository...');
try {
  // Change to source directory
  process.chdir(config.sourceRepo);
  
  // Install dependencies if needed
  if (!fs.existsSync(path.join(config.sourceRepo, 'node_modules'))) {
    console.log('📦 Installing source repository dependencies...');
    execSync('pnpm install', { stdio: 'inherit' });
  }
  
  // Check if the new build script exists
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  if (packageJson.scripts && packageJson.scripts.build) {
    // Use the new build script if available
    console.log('🔧 Using source repository build script...');
    execSync('pnpm build', { stdio: 'inherit' });
  } else {
    // Fallback: Use the build tools directly (for older submodule versions)
    console.log('🔧 Using build tools directly (legacy submodule)...');
    
    // Check if build-core.mjs exists
    const buildCorePath = path.join('tools', 'build-core.mjs');
    if (fs.existsSync(buildCorePath)) {
      // Use the modular build tools
      execSync('node -e "import(\'./tools/build-core.mjs\').then(m => { m.processTokens(); m.compileDesignSystem(); m.compileWebsiteTheme(); m.processJS(); m.writeManifest(); })"', { stdio: 'inherit' });
    } else {
      // Ultimate fallback: Use the consumer repo's build logic for the submodule
      console.log('⚠️  Source repository lacks build tools, falling back to consumer build logic...');
      process.chdir(path.join(__dirname));
      
      // Use a simplified version of the original build logic
      const { execSync } = require('child_process');
      const tokensDir = path.join(config.sourceRepo, 'src', 'tokens');
      const stylesDir = path.join(config.sourceRepo, 'src', 'styles');
      const sourceDistDir = config.sourceDistDir;
      
      // Ensure dist directory exists
      if (!fs.existsSync(sourceDistDir)) {
        fs.mkdirSync(sourceDistDir, { recursive: true });
      }
      
      // Process tokens manually
      console.log('📋 Processing design tokens...');
      const tokenFiles = ['colors.json', 'theme-colors.json', 'frequent.json', 'effects.json', 'components.json', 'typography.json'];
      let cssContent = ':root {\n';
      let lightThemeContent = ':root, [data-bs-theme="light"] {\n';
      let darkThemeContent = '[data-bs-theme="dark"] {\n';
      let mediaQueryContent = '@media (prefers-color-scheme: dark) {\n  :root {\n';
      
      function processTokenGroup(obj, prefix = '') {
        Object.keys(obj).forEach(key => {
          const value = obj[key];
          if (value && typeof value === 'object') {
            if (value.light && value.dark) {
              const varName = `--${prefix}${key}`.replace(/\./g, '-');
              lightThemeContent += `  ${varName}: ${value.light};\n`;
              darkThemeContent += `  ${varName}: ${value.dark};\n`;
              mediaQueryContent += `    ${varName}: ${value.dark};\n`;
            } else if (value.value) {
              const varName = `--${prefix}${key}`.replace(/\./g, '-');
              cssContent += `  ${varName}: ${value.value};\n`;
            } else if (!value.description) {
              processTokenGroup(value, `${prefix}${key}-`);
            }
          }
        });
      }
      
      tokenFiles.forEach(filename => {
        const filepath = path.join(tokensDir, filename);
        if (fs.existsSync(filepath)) {
          const tokenData = JSON.parse(fs.readFileSync(filepath, 'utf8'));
          processTokenGroup(tokenData);
        }
      });
      
      cssContent += '}\n\n';
      lightThemeContent += '}\n\n';
      darkThemeContent += '}\n\n';
      mediaQueryContent += '  }\n}\n\n';
      
      const finalCss = cssContent + lightThemeContent + darkThemeContent + mediaQueryContent;
      fs.writeFileSync(path.join(sourceDistDir, 'tokens.css'), finalCss);
      fs.writeFileSync(path.join(sourceDistDir, 'tokens.scss'), finalCss);
      
      // Generate basic Quarto themes
      console.log('🎨 Generating Quarto theme files...');
      const lightTheme = `// Dataimago Light Theme - Fallback
/*-- scss:defaults --*/
$body-bg: rgb(237, 237, 235) !default;
$body-color: rgb(20, 20, 16) !default;
$headings-color: rgb(20, 20, 16) !default;
$link-color: #7c7c7c !default;
/*-- scss:rules --*/
.navbar-logo { max-height: 36px; }
:root { --logo-default-fill: #7c7c7c; --logo-hover-fill: rgb(20, 20, 16); }`;
      
      const darkTheme = `// Dataimago Dark Theme - Fallback
/*-- scss:defaults --*/
$body-bg: rgb(20, 20, 16) !default;
$body-color: rgb(237, 237, 235) !default;
$headings-color: rgb(237, 237, 235) !default;
$link-color: #83838f !default;
/*-- scss:rules --*/
.navbar-logo { max-height: 36px; }
:root { --logo-default-fill: #83838f; --logo-hover-fill: rgb(237, 237, 235); }`;
      
      fs.writeFileSync(path.join(sourceDistDir, 'dataimago-light.scss'), lightTheme);
      fs.writeFileSync(path.join(sourceDistDir, 'dataimago-dark.scss'), darkTheme);
      
      // Copy JavaScript files if they exist
      const jsSourceDir = path.join(config.sourceRepo, 'src', 'js');
      const jsDistDir = path.join(sourceDistDir, 'js');
      if (fs.existsSync(jsSourceDir)) {
        console.log('📜 Copying JavaScript files...');
        function copyRecursive(src, dest) {
          const stats = fs.statSync(src);
          if (stats.isDirectory()) {
            if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
            fs.readdirSync(src).forEach(item => {
              copyRecursive(path.join(src, item), path.join(dest, item));
            });
          } else {
            fs.copyFileSync(src, dest);
          }
        }
        copyRecursive(jsSourceDir, jsDistDir);
      }
      
      // Create a basic manifest
      const manifest = {
        name: 'dataimago Design System',
        version: '0.0.1',
        buildTime: new Date().toISOString(),
        assets: {
          'tokens.css': 'Design tokens',
          'dataimago-light.scss': 'Light theme',
          'dataimago-dark.scss': 'Dark theme'
        }
      };
      fs.writeFileSync(path.join(sourceDistDir, 'manifest.json'), JSON.stringify(manifest, null, 2));
      
      console.log('✅ Fallback build completed');
      return;
    }
  }
  
  // Change back to consumer directory
  process.chdir(path.join(__dirname));
  
  console.log('✅ Source repository build completed');
} catch (error) {
  console.error('❌ Source repository build failed:', error.message);
  process.exit(1);
}

// Step 3: Verify source assets were generated
if (!fs.existsSync(config.sourceDistDir)) {
  console.error('❌ Source dist directory not found:', config.sourceDistDir);
  process.exit(1);
}

const sourceAssets = fs.readdirSync(config.sourceDistDir);
console.log(`📊 Found ${sourceAssets.length} assets in source repository`);

// Step 4: Create local dist directory and copy assets
console.log('📁 Setting up local distribution directory...');
if (!fs.existsSync(config.distDir)) {
  fs.mkdirSync(config.distDir, { recursive: true });
}

// Copy all assets from source to local dist
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

console.log('📋 Copying assets from source repository...');
copyRecursive(config.sourceDistDir, config.distDir);

// Step 5: Distribute assets to all channels
console.log('📦 Distributing assets to consumer repository locations...');

config.distributionChannels.forEach(channel => {
  // Ensure target directory exists
  if (!fs.existsSync(channel.path)) {
    fs.mkdirSync(channel.path, { recursive: true });
  }
  
  let copiedCount = 0;
  
  if (channel.files === 'all') {
    // Copy all CSS/SCSS files and JS directory
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
    // Copy specific files
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

// Step 6: Handle JavaScript assets separately
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

// Step 7: Generate build summary
console.log('📊 Build Summary:');
const finalAssets = fs.readdirSync(config.distDir);
finalAssets.forEach(file => {
  const filePath = path.join(config.distDir, file);
  const stats = fs.statSync(filePath);
  
  if (stats.isFile()) {
    const sizeKB = Math.round(stats.size / 1024 * 100) / 100;
    console.log(`   ✓ ${file} (${sizeKB} KB)`);
  } else if (stats.isDirectory()) {
    const dirFiles = fs.readdirSync(filePath).length;
    console.log(`   ✓ ${file}/ (${dirFiles} files)`);
  }
});

// Step 8: Verify critical assets exist
const criticalAssets = [
  'tokens.css',
  'dataimago.css',
  'dataimago.min.css',
  'dataimago-light.scss',
  'dataimago-dark.scss',
  'website-theme.css',
  'tailwind-preset.js',
  'manifest.json'
];

console.log('🔍 Verifying critical assets...');
const missingAssets = criticalAssets.filter(asset => !fs.existsSync(path.join(config.distDir, asset)));

if (missingAssets.length > 0) {
  console.warn('⚠️  Missing critical assets:', missingAssets.join(', '));
} else {
  console.log('✅ All critical assets present');
}

// Step 9: Update git submodule reference (optional)
try {
  const submoduleStatus = execSync('git submodule status', { 
    encoding: 'utf8', 
    cwd: path.join(__dirname, '..') 
  });
  console.log('📋 Submodule status:', submoduleStatus.trim());
} catch (error) {
  // Ignore git errors - not critical for build
}

console.log('🎉 Optimized dataimago design system build complete!');
console.log('📈 Build improvements:');
console.log('   - Eliminated 1000+ lines of duplicate build logic');
console.log('   - Single source of truth maintained in dataimago-design');
console.log('   - Faster builds through asset copying vs regeneration');
console.log('   - Automatic sync with source repository updates');
console.log('🛡️  Ethical AI design system ready for deployment!');
