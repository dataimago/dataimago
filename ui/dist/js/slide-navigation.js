/**
 * slide-navigation.js - dataimago Design System
 * Built: 2025-08-28T14:57:57.091Z
 * Source: ui/src/js/slide-navigation.js
 */
/**
 * Dataimago AI-Native Extension - Slide Navigation
 * Handles slide-based navigation and visual indicators
 */

class DataimagoSlideNavigation {
    constructor() {
        this.currentSlide = 0;
        this.slides = [];
        this.indicators = [];
        this.isNavigating = false;
        
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
        console.log('🧭 Initializing Dataimago Slide Navigation');
        
        // Find all slides
        this.slides = document.querySelectorAll('.dataimago-slide, .lenis-slide');
        
        if (this.slides.length === 0) {
            console.warn('⚠️ No dataimago slides found');
            return;
        }
        
        console.log(`📄 Found ${this.slides.length} slides`);
        
        // Create navigation indicators
        this.createSlideIndicators();
        
        // Setup intersection observers
        this.setupIntersectionObservers();
        
        // Setup keyboard navigation
        this.setupKeyboardNavigation();
        
        console.log('✅ Slide Navigation initialized');
    }

    createSlideIndicators() {
        // Create navigation container
        const nav = document.createElement('nav');
        nav.className = 'dataimago-slide-nav';
        nav.setAttribute('aria-label', 'Slide navigation');
        
        // Create indicators list
        const indicatorsList = document.createElement('ul');
        indicatorsList.className = 'dataimago-slide-indicators';
        
        // Create indicators for each slide
        this.slides.forEach((slide, index) => {
            const li = document.createElement('li');
            const button = document.createElement('button');
            
            button.className = `dataimago-slide-indicator ${index === 0 ? 'active' : ''}`;
            button.setAttribute('aria-label', `Go to slide ${index + 1} of ${this.slides.length}`);
            button.setAttribute('data-slide', index);
            button.type = 'button';
            
            // Add click handler
            button.addEventListener('click', (e) => {
                e.preventDefault();
                this.goToSlide(index);
            });
            
            li.appendChild(button);
            indicatorsList.appendChild(li);
            this.indicators.push(button);
        });
        
        nav.appendChild(indicatorsList);
        document.body.appendChild(nav);
        
        // Add skip link for accessibility
        this.addSkipLink();
    }

    addSkipLink() {
        const skipLink = document.createElement('a');
        skipLink.href = '#main-content';
        skipLink.className = 'dataimago-skip-link';
        skipLink.textContent = 'Skip to main content';
        document.body.insertBefore(skipLink, document.body.firstChild);
    }

    setupKeyboardNavigation() {
        document.addEventListener('keydown', (e) => {
            // Don't interfere if user is typing in an input
            if (e.target.matches('input, textarea, [contenteditable]')) {
                return;
            }
            
            if (this.isNavigating) return;
            
            switch(e.key) {
                case 'ArrowDown':
                case 'PageDown':
                case ' ': // Spacebar
                    e.preventDefault();
                    this.goToNextSlide();
                    break;
                    
                case 'ArrowUp':
                case 'PageUp':
                    e.preventDefault();
                    this.goToPrevSlide();
                    break;
                    
                case 'Home':
                    e.preventDefault();
                    this.goToSlide(0);
                    break;
                    
                case 'End':
                    e.preventDefault();
                    this.goToSlide(this.slides.length - 1);
                    break;
                    
                case 'Escape':
                    // Remove focus from any focused slide indicator
                    document.activeElement?.blur();
                    break;
            }
        });
    }

    setupIntersectionObservers() {
        // Observer for slide changes
        const slideObserver = new IntersectionObserver(
            (entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting && entry.intersectionRatio > 0.6) {
                        const slideIndex = Array.from(this.slides).indexOf(entry.target);
                        if (slideIndex !== -1 && slideIndex !== this.currentSlide) {
                            this.currentSlide = slideIndex;
                            this.updateIndicators();
                            
                            // Announce slide change for screen readers
                            this.announceSlideChange(slideIndex);
                        }
                    }
                });
            },
            {
                threshold: [0.3, 0.6, 0.9],
                rootMargin: '-20% 0px'
            }
        );

        this.slides.forEach(slide => slideObserver.observe(slide));
    }

    goToSlide(index) {
        if (index < 0 || index >= this.slides.length || this.isNavigating) {
            return;
        }
        
        this.isNavigating = true;
        this.currentSlide = index;
        
        // Update indicators immediately for better UX
        this.updateIndicators();
        
        // Use Lenis for smooth scrolling if available
        if (window.lenisIntegration?.lenis) {
            window.lenisIntegration.lenis.scrollTo(this.slides[index], {
                duration: 2.0,
                easing: (t) => 1 - Math.pow(1 - t, 3),
                onComplete: () => {
                    this.isNavigating = false;
                    this.announceSlideChange(index);
                }
            });
        } else {
            // Fallback to native smooth scroll
            this.slides[index].scrollIntoView({ 
                behavior: 'smooth',
                block: 'start'
            });
            
            // Reset navigation lock after animation
            setTimeout(() => {
                this.isNavigating = false;
                this.announceSlideChange(index);
            }, 1000);
        }
    }

    goToNextSlide() {
        const nextIndex = Math.min(this.currentSlide + 1, this.slides.length - 1);
        if (nextIndex !== this.currentSlide) {
            this.goToSlide(nextIndex);
        }
    }

    goToPrevSlide() {
        const prevIndex = Math.max(this.currentSlide - 1, 0);
        if (prevIndex !== this.currentSlide) {
            this.goToSlide(prevIndex);
        }
    }

    updateIndicators() {
        this.indicators.forEach((indicator, index) => {
            const isActive = index === this.currentSlide;
            indicator.classList.toggle('active', isActive);
            indicator.setAttribute('aria-pressed', isActive);
            indicator.setAttribute('aria-label', 
                `${isActive ? 'Current slide: ' : 'Go to '}slide ${index + 1} of ${this.slides.length}`
            );
        });
    }

    announceSlideChange(slideIndex) {
        // Create or update live region for screen reader announcements
        let liveRegion = document.getElementById('dataimago-slide-announcer');
        if (!liveRegion) {
            liveRegion = document.createElement('div');
            liveRegion.id = 'dataimago-slide-announcer';
            liveRegion.setAttribute('aria-live', 'polite');
            liveRegion.setAttribute('aria-atomic', 'true');
            liveRegion.style.position = 'absolute';
            liveRegion.style.left = '-10000px';
            liveRegion.style.width = '1px';
            liveRegion.style.height = '1px';
            liveRegion.style.overflow = 'hidden';
            document.body.appendChild(liveRegion);
        }
        
        // Get slide title if available
        const slide = this.slides[slideIndex];
        const slideTitle = slide.querySelector('h1, h2, h3')?.textContent || 
                          slide.getAttribute('data-slide-title') ||
                          `Section ${slideIndex + 1}`;
        
        liveRegion.textContent = `Now viewing: ${slideTitle}. Slide ${slideIndex + 1} of ${this.slides.length}`;
    }

    // Public API methods
    getCurrentSlide() {
        return this.currentSlide;
    }

    getTotalSlides() {
        return this.slides.length;
    }

    // Destroy method for cleanup
    destroy() {
        // Remove navigation elements
        const nav = document.querySelector('.dataimago-slide-nav');
        if (nav) {
            nav.remove();
        }
        
        // Remove skip link
        const skipLink = document.querySelector('.dataimago-skip-link');
        if (skipLink) {
            skipLink.remove();
        }
        
        // Remove live region
        const liveRegion = document.getElementById('dataimago-slide-announcer');
        if (liveRegion) {
            liveRegion.remove();
        }
        
        console.log('🧭 Slide Navigation destroyed');
    }
}

// Auto-initialize when script loads
const dataimagoSlideNav = new DataimagoSlideNavigation();

// Expose to global scope for external control
window.dataimagoSlideNav = dataimagoSlideNav;

console.log('📜 Dataimago Slide Navigation Script Loaded');