// Legacy PNG logo paths (for navbar/footer)
const greyLogo = '/assets/img/ai_monogram_supreme_bg_BW.png';
const lightModeColorLogo = '/assets/img/ai_monogram_supreme_bg_BLACK_WHITE.png';  // Black bg, white AI
const darkModeColorLogo = '/assets/img/ai_monogram_supreme_bg_WHITE_BLACK.png';   // White bg, black AI

// New SVG hex logo paths (for homepage and future use)
const svgLogos = {
  light: {
    default: '/assets/img/package_hex_logo_grey-light.svg',
    hover: '/assets/img/package_hex_logo_dark-light.svg'
  },
  dark: {
    default: '/assets/img/package_hex_logo_grey-dark.svg', 
    hover: '/assets/img/package_hex_logo_light-dark.svg'
  }
};

// URL configurations
const defaultLogoHref = 'https://dataimago.github.io/HelloWorld/';  // Default URL for logo/title
const hoverLogoHref = 'https://dataimago.ai';  // URL when hovering over logo

// Function to detect current theme mode
function getCurrentTheme() {
  // Method 1: Check HTML data attribute (most reliable)
  const dataTheme = document.documentElement.getAttribute('data-bs-theme');
  if (dataTheme === 'dark') {
    return 'dark';
  }
  
  // Method 2: Check if dark stylesheets are active
  const lightStylesheets = document.querySelectorAll('link.quarto-color-scheme:not(.quarto-color-alternate)');
  const darkStylesheets = document.querySelectorAll('link.quarto-color-scheme.quarto-color-alternate');
  
  // Check if light stylesheets are disabled (meaning dark mode is active)
  let lightDisabled = true;
  for (const sheet of lightStylesheets) {
    if (!sheet.disabled) {
      lightDisabled = false;
      break;
    }
  }
  
  // Check if dark stylesheets are enabled
  let darkEnabled = false;
  for (const sheet of darkStylesheets) {
    if (!sheet.disabled) {
      darkEnabled = true;
      break;
    }
  }
  
  // If light is disabled and dark is enabled, we're in dark mode
  if (lightDisabled && darkEnabled) {
    return 'dark';
  }
  
  // Method 3: Check for Bootstrap dark mode class
  const hasQuartoDark = document.body.classList.contains('quarto-dark');
  if (hasQuartoDark) {
    return 'dark';
  }
  
  return 'light';
}

// Function to get the appropriate color logo based on theme
function getColorLogo() {
  return getCurrentTheme() === 'dark' ? darkModeColorLogo : lightModeColorLogo;
}

// Select logo elements
let navbarLogo = document.querySelector('.navbar-logo');
let navbarBrandLink = null;  // Will store the navbar brand anchor element
let footerLogo = document.querySelector('.footer-img-icon');

// Function to set navbar logo hover effects
function setNavbarLogoHoverEffect() {
  if (!navbarLogo) {
    navbarLogo = document.querySelector('.navbar-logo');
    if (!navbarLogo) {
      return;
    }
  }
  
  // Find the navbar brand link (parent anchor element)
  navbarBrandLink = navbarLogo.closest('a');
  if (!navbarBrandLink) {
    // Fallback: look for .navbar-brand class
    navbarBrandLink = document.querySelector('.navbar-brand');
  }
  
  // Don't add individual logo event listeners - will be handled by navbar brand hover
}

// Function to set footer logo hover effects  
function setFooterLogoHoverEffect() {
  if (!footerLogo) {
    footerLogo = document.querySelector('.footer-img-icon');
    if (!footerLogo) {
      return;
    }
  }
  
  // Remove existing event listeners by cloning the element
  const newFooterLogo = footerLogo.cloneNode(true);
  footerLogo.parentNode.replaceChild(newFooterLogo, footerLogo);
  footerLogo = newFooterLogo; // Update our reference
  
  // Add new event listeners
  footerLogo.addEventListener('mouseover', () => {
    const logoToUse = getColorLogo();
    footerLogo.src = logoToUse;
  });
  
  footerLogo.addEventListener('mouseout', () => {
    footerLogo.src = greyLogo;
  });
}

// Function to set navbar brand text hover effects (for consistency)
function setNavbarBrandHoverEffect() {
  if (!navbarBrandLink) {
    navbarBrandLink = document.querySelector('.navbar-brand');
    if (!navbarBrandLink) {
      return;
    }
  }
  
  // Remove existing event listeners by cloning the element
  const newNavbarBrandLink = navbarBrandLink.cloneNode(true);
  navbarBrandLink.parentNode.replaceChild(newNavbarBrandLink, navbarBrandLink);
  navbarBrandLink = newNavbarBrandLink; // Update our reference
  
  // Update navbarLogo reference if it's a child of the cloned element
  const logoInBrand = navbarBrandLink.querySelector('.navbar-logo');
  if (logoInBrand) {
    navbarLogo = logoInBrand;
  }
  
  // Add hover effects to the entire navbar brand area
  navbarBrandLink.addEventListener('mouseover', () => {
    // Change logo to colored version when hovering over brand area
    if (navbarLogo) {
      const logoToUse = getColorLogo();
      navbarLogo.src = logoToUse;
    }
    
    // Switch href
    navbarBrandLink.href = hoverLogoHref;
  });
  
  navbarBrandLink.addEventListener('mouseout', () => {
    // Restore grey logo when leaving brand area
    if (navbarLogo) {
      navbarLogo.src = greyLogo;
    }
    
    // Restore original href
    navbarBrandLink.href = defaultLogoHref;
  });
}

// SVG Logo Management Functions
function getSVGLogos() {
  const theme = getCurrentTheme();
  return svgLogos[theme] || svgLogos.light;
}

function setHomepageHexLogoEffects() {
  const hexLogos = document.querySelectorAll('.dataimago-hex-logo');
  
  hexLogos.forEach(logo => {
    // Remove existing event listeners by cloning
    const newLogo = logo.cloneNode(true);
    logo.parentNode.replaceChild(newLogo, logo);
    
    const currentSVGLogos = getSVGLogos();
    
    // Set initial state
    newLogo.src = currentSVGLogos.default;
    
    // Add hover effects
    newLogo.addEventListener('mouseover', () => {
      const currentThemeLogos = getSVGLogos();
      newLogo.src = currentThemeLogos.hover;
    });
    
    newLogo.addEventListener('mouseout', () => {
      const currentThemeLogos = getSVGLogos();
      newLogo.src = currentThemeLogos.default;
    });
  });
}

function updateSVGLogosForTheme() {
  const hexLogos = document.querySelectorAll('.dataimago-hex-logo');
  const currentSVGLogos = getSVGLogos();
  
  hexLogos.forEach(logo => {
    // Update to appropriate default state for current theme
    if (logo.src.includes('grey-') || logo.src.includes('hover')) {
      logo.src = currentSVGLogos.default;
    }
  });
}

// Function to set all logo hover effects
function setLogoHoverEffect() {
  setNavbarLogoHoverEffect();
  setNavbarBrandHoverEffect();
  setFooterLogoHoverEffect();
  setHomepageHexLogoEffects();
}

// Initialize logo hover effects
setLogoHoverEffect();

// Function to handle theme changes
function handleThemeChange() {
  // Small delay to allow theme switch to complete
  setTimeout(() => {
    updateSVGLogosForTheme();
    setLogoHoverEffect();
  }, 100);
}

// Listen for theme toggle clicks
document.addEventListener('click', (e) => {
  if (e.target.closest('.quarto-color-scheme-toggle')) {
    handleThemeChange();
  }
});

// Listen for changes to the document's data-bs-theme attribute
const observer = new MutationObserver((mutations) => {
  mutations.forEach((mutation) => {
    if (mutation.type === 'attributes' && 
        (mutation.attributeName === 'data-bs-theme' || mutation.attributeName === 'class')) {
      handleThemeChange();
    }
  });
});

// Start observing the document element and body for theme changes
observer.observe(document.documentElement, { attributes: true });
observer.observe(document.body, { attributes: true });

// Also listen for stylesheet changes as a fallback
const stylesheetObserver = new MutationObserver((mutations) => {
  mutations.forEach((mutation) => {
    if (mutation.type === 'attributes' && 
        mutation.attributeName === 'disabled' && 
        mutation.target.classList.contains('quarto-color-scheme')) {
      handleThemeChange();
    }
  });
});

// Start observing stylesheet changes
document.querySelectorAll('link.quarto-color-scheme').forEach((stylesheet) => {
  stylesheetObserver.observe(stylesheet, { attributes: true });
});

// Theme-aware logo transitions initialized
// URL switching functionality added: navbar-brand href switches to https://dataimago.ai on hover