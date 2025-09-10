/**
 * svg-handler.js - dataimago Design System
 * Built: 2025-09-09T17:35:53.380Z
 * Source: ui/src/js/svg-handler.js
 */
/**
 * dataimago SVG Handler
 * Unified SVG loading, theming, and interaction management
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    useLocalPaths: false, // Set to true for local development
    cdnBase: 'https://cdn.jsdelivr.net/gh/dataimago/dataimago-rpkg@main/dataimago/inst/quarto-assets/',
    localBase: '/assets/',
    transitionDuration: 300,
    debugMode: false
  };

  // SVG asset paths
  const svgAssets = {
    navbar: {
      light: {
        default: 'ai_monogram_grey-light.svg',
        hover: 'ai_monogram_dark-light.svg'
      },
      dark: {
        default: 'ai_monogram_grey-dark.svg',
        hover: 'ai_monogram_light-dark.svg'
      }
    },
    hexLogo: {
      light: {
        default: 'package_hex_logo_grey-light.svg',
        hover: 'package_hex_logo_dark-light.svg'
      },
      dark: {
        default: 'package_hex_logo_grey-dark.svg',
        hover: 'package_hex_logo_light-dark.svg'
      }
    }
  };

  // Utility functions
  const utils = {
    getBasePath: () => config.useLocalPaths ? config.localBase : config.cdnBase,
    
    getCurrentTheme: () => {
      const htmlTheme = document.documentElement.getAttribute('data-bs-theme');
      const bodyClasses = document.body.classList;
      
      if (htmlTheme === 'dark' || bodyClasses.contains('quarto-dark')) return 'dark';
      if (htmlTheme === 'light' || bodyClasses.contains('quarto-light')) return 'light';
      
      // Fallback to media query
      return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    },
    
    log: (message, data = null) => {
      if (config.debugMode) {
        console.log(`[SVG Handler] ${message}`, data || '');
      }
    },
    
    loadSVG: async (url) => {
      try {
        const response = await fetch(url);
        if (!response.ok) throw new Error(`Failed to load SVG: ${response.status}`);
        return await response.text();
      } catch (error) {
        utils.log('Error loading SVG:', error);
        return null;
      }
    },
    
    injectSVG: (container, svgContent) => {
      if (!container || !svgContent) return false;
      
      // Clear existing content
      container.innerHTML = '';
      
      // Create temporary div to parse SVG
      const temp = document.createElement('div');
      temp.innerHTML = svgContent;
      
      // Get the SVG element
      const svg = temp.querySelector('svg');
      if (!svg) return false;
      
      // Add classes for styling
      svg.classList.add('theme-svg');
      
      // Append to container
      container.appendChild(svg);
      
      return true;
    }
  };

  // SVG Manager class
  class SVGManager {
    constructor() {
      this.currentTheme = utils.getCurrentTheme();
      this.svgCache = new Map();
      this.initialized = false;
    }

    async init() {
      if (this.initialized) return;
      
      utils.log('Initializing SVG Manager');
      
      // Initialize all SVG elements
      await this.initNavbarLogo();
      await this.initHexLogos();
      await this.initFooterLogos();
      
      // Set up event listeners
      this.setupEventListeners();
      
      // Set up theme observer
      this.setupThemeObserver();
      
      this.initialized = true;
      utils.log('SVG Manager initialized');
    }

    async initNavbarLogo() {
      const navbarLogo = document.querySelector('.navbar-logo, .navbar-brand-logo');
      if (!navbarLogo) return;
      
      const theme = this.currentTheme;
      const svgPath = `${utils.getBasePath()}${svgAssets.navbar[theme].default}`;
      
      // Check if it's already an img tag or needs SVG injection
      if (navbarLogo.tagName === 'IMG') {
        navbarLogo.src = svgPath;
        this.setupLogoHover(navbarLogo, 'navbar');
      } else {
        const svgContent = await this.getCachedSVG(svgPath);
        if (svgContent) {
          utils.injectSVG(navbarLogo, svgContent);
          this.setupLogoHover(navbarLogo, 'navbar');
        }
      }
    }

    async initHexLogos() {
      const hexLogos = document.querySelectorAll('.hex-logo-container, .di-hex-logo');
      
      for (const container of hexLogos) {
        const theme = this.currentTheme;
        const svgPath = `${utils.getBasePath()}${svgAssets.hexLogo[theme].default}`;
        
        if (container.tagName === 'IMG') {
          container.src = svgPath;
          this.setupLogoHover(container, 'hexLogo');
        } else {
          const svgContent = await this.getCachedSVG(svgPath);
          if (svgContent) {
            utils.injectSVG(container, svgContent);
            this.setupLogoHover(container, 'hexLogo');
          }
        }
      }
    }

    async initFooterLogos() {
      const footerLogos = document.querySelectorAll('.footer-quarto-logo');
      
      for (const logo of footerLogos) {
        // Footer logos typically have inline SVG, just add interaction classes
        const svg = logo.querySelector('svg');
        if (svg) {
          svg.classList.add('theme-svg', 'svg-interactive');
        }
      }
    }

    setupLogoHover(element, type) {
      if (!element) return;
      
      let isHovering = false;
      const theme = this.currentTheme;
      
      element.addEventListener('mouseenter', async () => {
        isHovering = true;
        element.classList.add('transitioning');
        
        const hoverPath = `${utils.getBasePath()}${svgAssets[type][theme].hover}`;
        
        if (element.tagName === 'IMG') {
          element.src = hoverPath;
        } else {
          const svgContent = await this.getCachedSVG(hoverPath);
          if (svgContent && isHovering) {
            utils.injectSVG(element, svgContent);
          }
        }
        
        setTimeout(() => element.classList.remove('transitioning'), config.transitionDuration);
      });
      
      element.addEventListener('mouseleave', async () => {
        isHovering = false;
        element.classList.add('transitioning');
        
        const defaultPath = `${utils.getBasePath()}${svgAssets[type][theme].default}`;
        
        if (element.tagName === 'IMG') {
          element.src = defaultPath;
        } else {
          const svgContent = await this.getCachedSVG(defaultPath);
          if (svgContent && !isHovering) {
            utils.injectSVG(element, svgContent);
          }
        }
        
        setTimeout(() => element.classList.remove('transitioning'), config.transitionDuration);
      });
    }

    async getCachedSVG(url) {
      if (this.svgCache.has(url)) {
        return this.svgCache.get(url);
      }
      
      const svgContent = await utils.loadSVG(url);
      if (svgContent) {
        this.svgCache.set(url, svgContent);
      }
      
      return svgContent;
    }

    setupEventListeners() {
      // Handle scroll for navbar logo shrinking
      let lastScrollTop = 0;
      
      window.addEventListener('scroll', () => {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        const navbar = document.querySelector('.navbar');
        const navbarLogo = document.querySelector('.navbar-logo');
        
        if (scrollTop > 50) {
          navbar?.classList.add('shrink');
          navbarLogo?.classList.add('shrink');
        } else {
          navbar?.classList.remove('shrink');
          navbarLogo?.classList.remove('shrink');
        }
        
        lastScrollTop = scrollTop;
      });
    }

    setupThemeObserver() {
      // Watch for theme changes
      const observer = new MutationObserver(async (mutations) => {
        for (const mutation of mutations) {
          if (mutation.attributeName === 'data-bs-theme' || 
              mutation.attributeName === 'class') {
            const newTheme = utils.getCurrentTheme();
            
            if (newTheme !== this.currentTheme) {
              utils.log('Theme changed:', `${this.currentTheme} → ${newTheme}`);
              this.currentTheme = newTheme;
              
              // Reinitialize all SVGs with new theme
              await this.initNavbarLogo();
              await this.initHexLogos();
            }
          }
        }
      });
      
      // Observe html element for data-bs-theme changes
      observer.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ['data-bs-theme']
      });
      
      // Observe body for class changes
      observer.observe(document.body, {
        attributes: true,
        attributeFilter: ['class']
      });
    }

    // Public method to update configuration
    updateConfig(newConfig) {
      Object.assign(config, newConfig);
      utils.log('Configuration updated:', config);
    }
  }

  // Initialize on DOM ready
  const initSVGHandler = () => {
    window.dataimagoSVG = new SVGManager();
    window.dataimagoSVG.init();
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSVGHandler);
  } else {
    initSVGHandler();
  }

  // Export for use in other scripts
  window.DataimagoSVGHandler = SVGManager;
})();