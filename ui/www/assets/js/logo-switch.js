// dataimago logo-switch.js
// Theme-aware logo hover effects and navbar brand URL switching

var defaultLogoSrc = '/assets/img/ai_monogram.svg';
var defaultLogoHref = 'https://dataimago.github.io/dataimago/';
var hoverLogoHref = 'https://dataimago.ai';

function getCurrentTheme() {
  var dataTheme = document.documentElement.getAttribute('data-bs-theme');
  if (dataTheme === 'dark') return 'dark';

  var lightSheets = document.querySelectorAll('link.quarto-color-scheme:not(.quarto-color-alternate)');
  var allLightDisabled = true;
  for (var i = 0; i < lightSheets.length; i++) {
    if (!lightSheets[i].disabled) { allLightDisabled = false; break; }
  }
  var darkSheets = document.querySelectorAll('link.quarto-color-scheme.quarto-color-alternate');
  var anyDarkEnabled = false;
  for (var j = 0; j < darkSheets.length; j++) {
    if (!darkSheets[j].disabled) { anyDarkEnabled = true; break; }
  }
  if (allLightDisabled && anyDarkEnabled) return 'dark';
  if (document.body.classList.contains('quarto-dark')) return 'dark';
  return 'light';
}

function setupNavbarBrandHover() {
  var navbarLogo = document.querySelector('.navbar-logo');
  var navbarBrand = navbarLogo ? navbarLogo.closest('a') : document.querySelector('.navbar-brand');
  if (!navbarBrand) return;

  navbarBrand.addEventListener('mouseover', function() {
    navbarBrand.href = hoverLogoHref;
    if (navbarLogo) navbarLogo.classList.add('logo-hover');
  });
  navbarBrand.addEventListener('mouseout', function() {
    navbarBrand.href = defaultLogoHref;
    if (navbarLogo) navbarLogo.classList.remove('logo-hover');
  });
}

function setupFooterLogoHover() {
  var footerLogos = document.querySelectorAll('.footer-ai-monogram-logo');
  footerLogos.forEach(function(logo) {
    logo.addEventListener('mouseover', function() { logo.classList.add('logo-hover'); });
    logo.addEventListener('mouseout', function() { logo.classList.remove('logo-hover'); });
  });
}

function initLogoSwitch() {
  setupNavbarBrandHover();
  setupFooterLogoHover();
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initLogoSwitch);
} else {
  initLogoSwitch();
}

var themeObserver = new MutationObserver(function(mutations) {
  mutations.forEach(function(mutation) {
    if (mutation.type === 'attributes' &&
        (mutation.attributeName === 'data-bs-theme' || mutation.attributeName === 'class')) {
      setTimeout(initLogoSwitch, 100);
    }
  });
});
themeObserver.observe(document.documentElement, { attributes: true });
themeObserver.observe(document.body, { attributes: true });

document.querySelectorAll('link.quarto-color-scheme').forEach(function(sheet) {
  new MutationObserver(function() { setTimeout(initLogoSwitch, 100); })
    .observe(sheet, { attributes: true, attributeFilter: ['disabled'] });
});
