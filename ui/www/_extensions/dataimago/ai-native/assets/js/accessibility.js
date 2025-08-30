/**
 * accessibility.js - dataimago Design System
 * Built: 2025-08-30T08:53:09.831Z
 * Source: ui/src/js/accessibility.js
 */
/**
 * Dataimago AI-Native Extension - Accessibility Enhancements
 * Provides enhanced accessibility features for the AI-native website
 */

class DataimagoAccessibility {
    constructor() {
        this.prefersReducedMotion = false;
        this.highContrastMode = false;
        this.focusVisible = false;
        
        this.init();
    }

    init() {
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.setup());
        } else {
            this.setup();
        }
    }

    setup() {
        console.log('♿ Initializing Dataimago Accessibility Features');
        
        // Detect user preferences
        this.detectUserPreferences();
        
        // Setup focus management
        this.setupFocusManagement();
        
        // Setup motion preferences
        this.setupMotionPreferences();
        
        // Setup keyboard navigation enhancements
        this.setupKeyboardNavigation();
        
        // Setup screen reader announcements
        this.setupScreenReaderSupport();
        
        // Setup contrast preferences
        this.setupContrastPreferences();
        
        // Add skip links
        this.addSkipLinks();
        
        // Setup landmark navigation
        this.setupLandmarkNavigation();
        
        console.log('✅ Accessibility Features initialized');
    }

    detectUserPreferences() {
        // Detect reduced motion preference
        this.prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        
        // Detect high contrast preference
        this.highContrastMode = window.matchMedia('(prefers-contrast: high)').matches;
        
        // Listen for changes
        window.matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change', (e) => {
            this.prefersReducedMotion = e.matches;
            this.updateMotionPreferences();
        });
        
        window.matchMedia('(prefers-contrast: high)').addEventListener('change', (e) => {
            this.highContrastMode = e.matches;
            this.updateContrastPreferences();
        });
        
        console.log(`♿ User preferences: Motion=${this.prefersReducedMotion ? 'reduced' : 'normal'}, Contrast=${this.highContrastMode ? 'high' : 'normal'}`);
    }

    setupFocusManagement() {
        // Add focus-visible polyfill behavior
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                document.body.classList.add('dataimago-keyboard-nav');
                this.focusVisible = true;
            }
        });
        
        document.addEventListener('mousedown', () => {
            document.body.classList.remove('dataimago-keyboard-nav');
            this.focusVisible = false;
        });
        
        // Enhanced focus indicators for interactive elements
        const focusableElements = document.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        
        focusableElements.forEach(element => {
            element.addEventListener('focus', (e) => {
                if (this.focusVisible) {
                    e.target.classList.add('dataimago-focus-visible');
                }
            });
            
            element.addEventListener('blur', (e) => {
                e.target.classList.remove('dataimago-focus-visible');
            });
        });
    }

    setupMotionPreferences() {
        this.updateMotionPreferences();
    }

    updateMotionPreferences() {
        document.documentElement.setAttribute('data-motion', 
            this.prefersReducedMotion ? 'reduce' : 'normal'
        );
        
        if (this.prefersReducedMotion) {
            // Disable Lenis smooth scrolling
            if (window.lenisIntegration?.lenis) {
                window.lenisIntegration.lenis.stop();
            }
            
            // Add reduced motion class for CSS targeting
            document.body.classList.add('dataimago-reduced-motion');
            
            console.log('♿ Reduced motion activated');
        } else {
            // Re-enable Lenis if it was disabled
            if (window.lenisIntegration?.lenis) {
                window.lenisIntegration.lenis.start();
            }
            
            document.body.classList.remove('dataimago-reduced-motion');
        }
    }

    setupKeyboardNavigation() {
        // Global keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            // Skip if typing in an input
            if (e.target.matches('input, textarea, [contenteditable]')) {
                return;
            }
            
            // Handle global shortcuts
            switch(e.key) {
                case '?':
                    if (e.shiftKey) {
                        e.preventDefault();
                        this.showKeyboardShortcuts();
                    }
                    break;
                    
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    if (e.altKey) {
                        e.preventDefault();
                        const slideIndex = parseInt(e.key) - 1;
                        if (window.dataimagoSlideNav) {
                            window.dataimagoSlideNav.goToSlide(slideIndex);
                        }
                    }
                    break;
                    
                case 'h':
                    if (e.altKey) {
                        e.preventDefault();
                        this.navigateToLandmark('main');
                    }
                    break;
                    
                case 'n':
                    if (e.altKey) {
                        e.preventDefault();
                        this.navigateToLandmark('nav');
                    }
                    break;
            }
        });
    }

    setupScreenReaderSupport() {
        // Create and manage ARIA live regions
        this.createLiveRegions();
        
        // Announce page changes
        this.setupPageChangeAnnouncements();
        
        // Add descriptive labels to interactive elements
        this.enhanceInteractiveElements();
    }

    createLiveRegions() {
        // Polite announcements (non-interrupting)
        if (!document.getElementById('dataimago-live-polite')) {
            const politeRegion = document.createElement('div');
            politeRegion.id = 'dataimago-live-polite';
            politeRegion.setAttribute('aria-live', 'polite');
            politeRegion.setAttribute('aria-atomic', 'true');
            politeRegion.className = 'dataimago-sr-only';
            document.body.appendChild(politeRegion);
        }
        
        // Assertive announcements (interrupting)
        if (!document.getElementById('dataimago-live-assertive')) {
            const assertiveRegion = document.createElement('div');
            assertiveRegion.id = 'dataimago-live-assertive';
            assertiveRegion.setAttribute('aria-live', 'assertive');
            assertiveRegion.setAttribute('aria-atomic', 'true');
            assertiveRegion.className = 'dataimago-sr-only';
            document.body.appendChild(assertiveRegion);
        }
    }

    announceToScreenReader(message, priority = 'polite') {
        const regionId = `dataimago-live-${priority}`;
        const region = document.getElementById(regionId);
        
        if (region) {
            // Clear previous message
            region.textContent = '';
            
            // Add new message with slight delay for better SR pickup
            setTimeout(() => {
                region.textContent = message;
            }, 100);
            
            // Clear message after announcement
            setTimeout(() => {
                region.textContent = '';
            }, 5000);
        }
    }

    setupPageChangeAnnouncements() {
        // Watch for dynamic content changes
        const contentObserver = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                    // Check if significant content was added
                    const addedContent = Array.from(mutation.addedNodes).find(node => 
                        node.nodeType === Node.ELEMENT_NODE && 
                        (node.matches('section, article, main') || node.querySelector('h1, h2, h3'))
                    );
                    
                    if (addedContent) {
                        const heading = addedContent.querySelector('h1, h2, h3') || addedContent;
                        const headingText = heading.textContent?.trim();
                        
                        if (headingText) {
                            this.announceToScreenReader(`New content loaded: ${headingText}`);
                        }
                    }
                }
            });
        });
        
        // Observe changes to main content areas
        const mainContent = document.querySelector('main, .main-content, .dataimago-slide');
        if (mainContent) {
            contentObserver.observe(mainContent, {
                childList: true,
                subtree: true
            });
        }
    }

    enhanceInteractiveElements() {
        // Add missing labels and descriptions
        const interactiveElements = document.querySelectorAll('button, [role="button"], [tabindex]');
        
        interactiveElements.forEach(element => {
            // Ensure buttons have accessible names
            if (!element.getAttribute('aria-label') && !element.getAttribute('aria-labelledby') && !element.textContent.trim()) {
                const context = this.getElementContext(element);
                if (context) {
                    element.setAttribute('aria-label', context);
                }
            }
            
            // Add role descriptions where helpful
            if (element.classList.contains('dataimago-slide-indicator')) {
                element.setAttribute('role', 'tab');
                element.setAttribute('aria-roledescription', 'slide navigation button');
            }
        });
    }

    getElementContext(element) {
        // Try to determine context from surrounding content
        const parent = element.closest('[data-slide], section, article');
        if (parent) {
            const heading = parent.querySelector('h1, h2, h3, h4, h5, h6');
            if (heading) {
                return `Button in ${heading.textContent.trim()}`;
            }
        }
        
        // Look for nearby text
        const nearbyText = element.previousElementSibling?.textContent?.trim() ||
                          element.nextElementSibling?.textContent?.trim();
        
        if (nearbyText && nearbyText.length < 50) {
            return `Button: ${nearbyText}`;
        }
        
        return null;
    }

    setupContrastPreferences() {
        this.updateContrastPreferences();
    }

    updateContrastPreferences() {
        document.documentElement.setAttribute('data-contrast', 
            this.highContrastMode ? 'high' : 'normal'
        );
        
        if (this.highContrastMode) {
            document.body.classList.add('dataimago-high-contrast');
            console.log('♿ High contrast mode activated');
        } else {
            document.body.classList.remove('dataimago-high-contrast');
        }
    }

    addSkipLinks() {
        // Main skip link (if not already present)
        if (!document.querySelector('.dataimago-skip-link')) {
            const skipToMain = document.createElement('a');
            skipToMain.href = '#main-content';
            skipToMain.className = 'dataimago-skip-link';
            skipToMain.textContent = 'Skip to main content';
            document.body.insertBefore(skipToMain, document.body.firstChild);
        }
        
        // Add skip to navigation if nav exists
        const navigation = document.querySelector('nav, [role="navigation"]');
        if (navigation && !navigation.id) {
            navigation.id = 'main-navigation';
            
            const skipToNav = document.createElement('a');
            skipToNav.href = '#main-navigation';
            skipToNav.className = 'dataimago-skip-link';
            skipToNav.textContent = 'Skip to navigation';
            document.body.insertBefore(skipToNav, document.body.children[1]);
        }
    }

    setupLandmarkNavigation() {
        // Ensure main content has proper landmark
        let mainContent = document.querySelector('main');
        if (!mainContent) {
            mainContent = document.querySelector('.main-content, #main-content');
            if (mainContent && !mainContent.getAttribute('role')) {
                mainContent.setAttribute('role', 'main');
            }
        }
        
        if (mainContent && !mainContent.id) {
            mainContent.id = 'main-content';
        }
    }

    navigateToLandmark(landmarkType) {
        let landmark;
        
        switch(landmarkType) {
            case 'main':
                landmark = document.querySelector('main, [role="main"], #main-content');
                break;
            case 'nav':
                landmark = document.querySelector('nav, [role="navigation"]');
                break;
            case 'banner':
                landmark = document.querySelector('header, [role="banner"]');
                break;
            case 'contentinfo':
                landmark = document.querySelector('footer, [role="contentinfo"]');
                break;
        }
        
        if (landmark) {
            landmark.scrollIntoView({ behavior: 'smooth', block: 'start' });
            
            // Focus the landmark for keyboard users
            if (!landmark.hasAttribute('tabindex')) {
                landmark.setAttribute('tabindex', '-1');
            }
            landmark.focus();
            
            this.announceToScreenReader(`Navigated to ${landmarkType} landmark`);
        }
    }

    showKeyboardShortcuts() {
        const shortcuts = [
            'Alt + 1-9: Jump to slide',
            'Alt + H: Jump to main content',
            'Alt + N: Jump to navigation',
            'Arrow keys: Navigate slides',
            'Home/End: First/last slide',
            'Tab: Move through interactive elements',
            'Shift + ?: Show this help'
        ];
        
        this.announceToScreenReader(
            `Keyboard shortcuts available: ${shortcuts.join('. ')}`,
            'assertive'
        );
        
        // Could also show a modal or tooltip here
        console.log('⌨️ Keyboard shortcuts:', shortcuts);
    }

    // Public API methods
    setReducedMotion(enable) {
        this.prefersReducedMotion = enable;
        this.updateMotionPreferences();
    }

    setHighContrast(enable) {
        this.highContrastMode = enable;
        this.updateContrastPreferences();
    }

    announce(message, priority = 'polite') {
        this.announceToScreenReader(message, priority);
    }

    // Destroy method for cleanup
    destroy() {
        // Remove added elements
        document.querySelectorAll('.dataimago-skip-link, .dataimago-sr-only').forEach(el => {
            el.remove();
        });
        
        // Remove added classes
        document.body.classList.remove('dataimago-keyboard-nav', 'dataimago-reduced-motion', 'dataimago-high-contrast');
        
        console.log('♿ Accessibility Features destroyed');
    }
}

// Auto-initialize when script loads
const dataimagoAccessibility = new DataimagoAccessibility();

// Expose to global scope for external control
window.dataimagoAccessibility = dataimagoAccessibility;

console.log('📜 Dataimago Accessibility Script Loaded');

// Add CSS for screen reader only content and focus indicators
const accessibilityCSS = `
.dataimago-sr-only {
    position: absolute !important;
    width: 1px !important;
    height: 1px !important;
    padding: 0 !important;
    margin: -1px !important;
    overflow: hidden !important;
    clip: rect(0, 0, 0, 0) !important;
    white-space: nowrap !important;
    border: 0 !important;
}

.dataimago-focus-visible {
    outline: 2px solid var(--dataimago-primary, #83838f) !important;
    outline-offset: 2px !important;
    box-shadow: 0 0 0 4px rgba(131, 131, 143, 0.2) !important;
}

.dataimago-reduced-motion * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
}

.dataimago-high-contrast {
    filter: contrast(150%);
}

.dataimago-high-contrast .dataimago-slide-indicator {
    border-width: 3px !important;
}

.dataimago-skip-link:focus {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    z-index: 10000 !important;
    padding: 8px 16px !important;
    background: var(--dataimago-primary, #83838f) !important;
    color: white !important;
    text-decoration: none !important;
    font-weight: bold !important;
    border-radius: 0 0 4px 4px !important;
}
`;

// Inject accessibility CSS
const accessibilityStyleSheet = document.createElement('style');
accessibilityStyleSheet.textContent = accessibilityCSS;
document.head.appendChild(accessibilityStyleSheet);