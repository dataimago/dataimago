/**
 * hero-scroller.js - dataimago Design System
 * Built: 2025-09-01T17:06:30.385Z
 * Source: ui/src/js/hero-scroller.js
 */
/**
 * Dataimago AI-Native Extension - Hero Scroller
 * Handles smooth scrolling hero content areas (carousel replacement)
 */

class DataimagoHeroScroller {
    constructor() {
        this.scrollers = new Map();
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
        console.log('🎠 Initializing Dataimago Hero Scrollers');
        
        // Find all hero scroller containers
        const scrollerContainers = document.querySelectorAll(
            '.dataimago-hero-scroller, .hero-content-scroller'
        );
        
        if (scrollerContainers.length === 0) {
            console.log('ℹ️ No hero scrollers found');
            return;
        }
        
        console.log(`🎠 Found ${scrollerContainers.length} hero scroller(s)`);
        
        // Initialize each scroller
        scrollerContainers.forEach((container, index) => {
            this.initializeScroller(container, index);
        });
        
        console.log('✅ Hero Scrollers initialized');
    }

    initializeScroller(container, index) {
        const scrollerId = `hero-scroller-${index}`;
        container.setAttribute('data-scroller-id', scrollerId);
        
        // Find or create content wrapper
        let contentWrapper = container.querySelector('.dataimago-scroller-content, .scroller-content');
        if (!contentWrapper) {
            // Wrap existing content
            contentWrapper = document.createElement('div');
            contentWrapper.className = 'dataimago-scroller-content';
            
            // Move existing content into wrapper
            while (container.firstChild) {
                contentWrapper.appendChild(container.firstChild);
            }
            container.appendChild(contentWrapper);
        }
        
        // Create Lenis instance for this scroller
        const scrollerLenis = new Lenis({
            wrapper: container,
            content: contentWrapper,
            duration: 1.2,
            easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
            direction: 'vertical',
            smoothWheel: true,
            smoothTouch: false,
            wheelMultiplier: 1.5,
            touchMultiplier: 2,
            infinite: false,
            autoResize: true,
            syncTouch: false,
            overscroll: false
        });

        // Store scroller instance
        this.scrollers.set(scrollerId, {
            container,
            contentWrapper,
            lenis: scrollerLenis,
            progressIndicator: null
        });

        // Start animation loop for this scroller
        this.startScrollerAnimationLoop(scrollerId);
        
        // Add scroll progress indicator
        this.addScrollProgressIndicator(scrollerId);
        
        // Setup content item animations
        this.setupContentItemAnimations(scrollerId);
        
        // Add smooth scrolling to content items
        this.addContentItemNavigation(scrollerId);
        
        console.log(`🎠 Initialized hero scroller: ${scrollerId}`);
    }

    startScrollerAnimationLoop(scrollerId) {
        const scroller = this.scrollers.get(scrollerId);
        if (!scroller) return;
        
        const animate = (time) => {
            scroller.lenis.raf(time);
            requestAnimationFrame(animate);
        };
        
        requestAnimationFrame(animate);
    }

    addScrollProgressIndicator(scrollerId) {
        const scroller = this.scrollers.get(scrollerId);
        if (!scroller) return;
        
        // Create progress indicator
        const indicator = document.createElement('div');
        indicator.className = 'dataimago-scroll-indicator';
        indicator.innerHTML = '<div class="dataimago-scroll-progress"></div>';
        
        scroller.container.appendChild(indicator);
        scroller.progressIndicator = indicator;
        
        const progressBar = indicator.querySelector('.dataimago-scroll-progress');
        
        // Update progress on scroll
        scroller.lenis.on('scroll', (e) => {
            if (progressBar) {
                const progress = Math.min(1, Math.max(0, e.progress));
                progressBar.style.height = `${progress * 100}%`;
            }
        });
    }

    setupContentItemAnimations(scrollerId) {
        const scroller = this.scrollers.get(scrollerId);
        if (!scroller) return;
        
        // Find all content items
        const contentItems = scroller.contentWrapper.querySelectorAll(
            '.dataimago-content-item, .content-item'
        );
        
        if (contentItems.length === 0) return;
        
        // Create intersection observer for content items
        const itemObserver = new IntersectionObserver(
            (entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('dataimago-item-visible');
                        
                        // Trigger any data-dataimago-animate elements inside
                        const animatedElements = entry.target.querySelectorAll('[data-dataimago-animate]');
                        animatedElements.forEach(el => {
                            el.classList.add('dataimago-animate-active');
                        });
                    }
                });
            },
            {
                root: scroller.container,
                threshold: 0.3,
                rootMargin: '0px 0px -20% 0px'
            }
        );
        
        // Observe all content items
        contentItems.forEach((item, index) => {
            // Add item index for potential styling
            item.setAttribute('data-item-index', index);
            
            // Add initial animation class
            item.classList.add('dataimago-content-item');
            
            // Observe for visibility changes
            itemObserver.observe(item);
        });
    }

    addContentItemNavigation(scrollerId) {
        const scroller = this.scrollers.get(scrollerId);
        if (!scroller) return;
        
        // Add click-to-scroll functionality for content items
        const contentItems = scroller.contentWrapper.querySelectorAll(
            '.dataimago-content-item, .content-item'
        );
        
        contentItems.forEach((item, index) => {
            // Make items focusable
            if (!item.hasAttribute('tabindex')) {
                item.setAttribute('tabindex', '0');
            }
            
            // Add role for screen readers
            item.setAttribute('role', 'article');
            item.setAttribute('aria-label', `Content item ${index + 1} of ${contentItems.length}`);
            
            // Add keyboard navigation
            item.addEventListener('keydown', (e) => {
                switch(e.key) {
                    case 'Enter':
                    case ' ':
                        e.preventDefault();
                        this.scrollToItem(scrollerId, index);
                        break;
                    case 'ArrowDown':
                        e.preventDefault();
                        this.scrollToItem(scrollerId, Math.min(index + 1, contentItems.length - 1));
                        break;
                    case 'ArrowUp':
                        e.preventDefault();
                        this.scrollToItem(scrollerId, Math.max(index - 1, 0));
                        break;
                }
            });
        });
    }

    scrollToItem(scrollerId, itemIndex) {
        const scroller = this.scrollers.get(scrollerId);
        if (!scroller) return;
        
        const contentItems = scroller.contentWrapper.querySelectorAll(
            '.dataimago-content-item, .content-item'
        );
        
        if (itemIndex >= 0 && itemIndex < contentItems.length) {
            const targetItem = contentItems[itemIndex];
            
            scroller.lenis.scrollTo(targetItem, {
                duration: 1.0,
                easing: (t) => 1 - Math.pow(1 - t, 3),
                offset: -20 // Small offset from top
            });
            
            // Focus the item for keyboard users
            setTimeout(() => {
                targetItem.focus();
            }, 600);
        }
    }

    // Public API methods
    getScroller(scrollerId) {
        return this.scrollers.get(scrollerId);
    }

    scrollToTop(scrollerId) {
        const scroller = this.scrollers.get(scrollerId);
        if (scroller) {
            scroller.lenis.scrollTo(0, { duration: 1.5 });
        }
    }

    scrollToBottom(scrollerId) {
        const scroller = this.scrollers.get(scrollerId);
        if (scroller) {
            scroller.lenis.scrollTo('bottom', { duration: 2.0 });
        }
    }

    // Refresh scroller layout (useful after content changes)
    refresh(scrollerId) {
        const scroller = this.scrollers.get(scrollerId);
        if (scroller && scroller.lenis.resize) {
            scroller.lenis.resize();
        }
    }

    // Destroy method for cleanup
    destroy() {
        this.scrollers.forEach((scroller, scrollerId) => {
            if (scroller.lenis && scroller.lenis.destroy) {
                scroller.lenis.destroy();
            }
            
            // Remove progress indicator
            if (scroller.progressIndicator) {
                scroller.progressIndicator.remove();
            }
            
            console.log(`🎠 Destroyed hero scroller: ${scrollerId}`);
        });
        
        this.scrollers.clear();
        console.log('🎠 All Hero Scrollers destroyed');
    }
}

// Auto-initialize when script loads
const dataimagoHeroScroller = new DataimagoHeroScroller();

// Expose to global scope for external control
window.dataimagoHeroScroller = dataimagoHeroScroller;

console.log('📜 Dataimago Hero Scroller Script Loaded');