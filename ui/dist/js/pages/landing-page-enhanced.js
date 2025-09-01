/**
 * landing-page-enhanced.js - dataimago Design System
 * Built: 2025-09-01T20:10:30.218Z
 * Source: ui/src/js/pages/landing-page-enhanced.js
 */
/**
 * landing-page-enhanced.js - dataimago Enhanced Landing Page Experience
 * Enhanced mobile-responsive scrollytelling with touch gestures and progress tracking
 */

class DataimagoLandingPageEnhanced {
    constructor() {
        this.currentSlide = 0;
        this.slides = [];
        this.indicators = [];
        this.isNavigating = false;
        this.touchStartY = 0;
        this.touchEndY = 0;
        this.touchThreshold = 100;
        this.progressBar = null;
        
        this.init();
    }

    init() {
        // Wait for DOM and other scripts to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.setup());
        } else {
            // Small delay to ensure Lenis is initialized
            setTimeout(() => this.setup(), 100);
        }
    }

    setup() {
        console.log('🚀 Initializing Enhanced Landing Page Experience');
        
        // Find all slides
        this.slides = document.querySelectorAll('.dataimago-slide.lenis-slide');
        
        if (this.slides.length === 0) {
            console.warn('⚠️ No dataimago slides found for enhanced experience');
            return;
        }
        
        console.log(`📄 Found ${this.slides.length} slides for enhanced experience`);
        
        // Add IDs to slides if they don't have them
        this.ensureSlideIds();
        
        // Create enhanced slide indicators
        this.createEnhancedIndicators();
        
        // Create progress bar
        this.createProgressBar();
        
        // Setup mobile touch gestures
        this.setupTouchGestures();
        
        // Setup intersection observers for slide tracking
        this.setupSlideTracking();
        
        // Setup scroll progress tracking
        this.setupProgressTracking();
        
        // Add slide transition animations
        this.setupSlideAnimations();
        
        console.log('✅ Enhanced Landing Page Experience initialized');
    }

    ensureSlideIds() {
        this.slides.forEach((slide, index) => {
            if (!slide.id) {
                const slideNames = ['hero', 'vision-mission', 'architecture', 'features', 'visual-identity', 'technical', 'getting-started', 'philosophy', 'cta'];
                slide.id = `${slideNames[index] || 'slide'}-${index + 1}`;
            }
        });
    }

    createEnhancedIndicators() {
        // Remove existing indicators if any
        const existingNav = document.querySelector('.dataimago-enhanced-nav');
        if (existingNav) {
            existingNav.remove();
        }

        // Create enhanced navigation container
        const nav = document.createElement('nav');
        nav.className = 'dataimago-enhanced-nav';
        nav.setAttribute('aria-label', 'Slide navigation with labels');
        
        // Create indicators container
        const indicatorsContainer = document.createElement('div');
        indicatorsContainer.className = 'dataimago-enhanced-indicators';
        
        // Slide titles for better UX
        const slideTitles = [
            'Introduction',
            'Vision & Mission', 
            'Architecture',
            'Key Features',
            'Visual Identity',
            'Technical Details',
            'Getting Started',
            'Philosophy',
            'Get Involved'
        ];
        
        // Create indicators with labels
        this.slides.forEach((slide, index) => {
            const indicatorWrapper = document.createElement('div');
            indicatorWrapper.className = 'dataimago-indicator-wrapper';
            
            const indicator = document.createElement('button');
            indicator.className = `dataimago-enhanced-indicator ${index === 0 ? 'active' : ''}`;
            indicator.setAttribute('aria-label', `Go to slide ${index + 1}: ${slideTitles[index]}`);
            indicator.setAttribute('data-slide', index);
            indicator.type = 'button';
            
            const label = document.createElement('span');
            label.className = 'dataimago-indicator-label';
            label.textContent = slideTitles[index] || `Slide ${index + 1}`;
            
            // Add click handler
            indicator.addEventListener('click', (e) => {
                e.preventDefault();
                this.goToSlide(index);
            });
            
            indicatorWrapper.appendChild(indicator);
            indicatorWrapper.appendChild(label);
            indicatorsContainer.appendChild(indicatorWrapper);
            this.indicators.push(indicator);
        });
        
        nav.appendChild(indicatorsContainer);
        
        // Add skip controls for accessibility
        this.addSkipControls(nav);
        
        document.body.appendChild(nav);
    }

    addSkipControls(nav) {
        const skipControls = document.createElement('div');
        skipControls.className = 'dataimago-skip-controls';
        
        const prevBtn = document.createElement('button');
        prevBtn.className = 'dataimago-skip-btn dataimago-skip-prev';
        prevBtn.innerHTML = '↑';
        prevBtn.setAttribute('aria-label', 'Previous slide');
        prevBtn.addEventListener('click', () => this.goToPrevSlide());
        
        const nextBtn = document.createElement('button');
        nextBtn.className = 'dataimago-skip-btn dataimago-skip-next';
        nextBtn.innerHTML = '↓';
        nextBtn.setAttribute('aria-label', 'Next slide');
        nextBtn.addEventListener('click', () => this.goToNextSlide());
        
        skipControls.appendChild(prevBtn);
        skipControls.appendChild(nextBtn);
        nav.appendChild(skipControls);
    }

    createProgressBar() {
        // Create progress bar container
        const progressContainer = document.createElement('div');
        progressContainer.className = 'dataimago-progress-container';
        
        this.progressBar = document.createElement('div');
        this.progressBar.className = 'dataimago-progress-bar';
        
        const progressFill = document.createElement('div');
        progressFill.className = 'dataimago-progress-fill';
        
        this.progressBar.appendChild(progressFill);
        progressContainer.appendChild(this.progressBar);
        
        // Add progress text
        const progressText = document.createElement('div');
        progressText.className = 'dataimago-progress-text';
        progressText.textContent = '1 / 9';
        progressContainer.appendChild(progressText);
        
        document.body.appendChild(progressContainer);
    }

    setupTouchGestures() {
        // Add touch event listeners for mobile swipe navigation
        document.addEventListener('touchstart', (e) => {
            this.touchStartY = e.touches[0].clientY;
        }, { passive: true });

        document.addEventListener('touchend', (e) => {
            this.touchEndY = e.changedTouches[0].clientY;
            this.handleSwipeGesture();
        }, { passive: true });

        // Add mouse wheel support for desktop
        document.addEventListener('wheel', (e) => {
            if (this.isNavigating) return;
            
            // Debounce wheel events
            if (this.wheelTimeout) return;
            
            this.wheelTimeout = setTimeout(() => {
                this.wheelTimeout = null;
            }, 500);
            
            if (e.deltaY > 0) {
                this.goToNextSlide();
            } else {
                this.goToPrevSlide();
            }
        }, { passive: true });
    }

    handleSwipeGesture() {
        if (this.isNavigating) return;
        
        const swipeDistance = this.touchStartY - this.touchEndY;
        
        if (Math.abs(swipeDistance) > this.touchThreshold) {
            if (swipeDistance > 0) {
                // Swipe up - go to next slide
                this.goToNextSlide();
            } else {
                // Swipe down - go to previous slide
                this.goToPrevSlide();
            }
        }
    }

    setupSlideTracking() {
        // Enhanced intersection observer for slide tracking
        const slideObserver = new IntersectionObserver(
            (entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting && entry.intersectionRatio > 0.5) {
                        const slideIndex = Array.from(this.slides).indexOf(entry.target);
                        if (slideIndex !== -1 && slideIndex !== this.currentSlide) {
                            this.currentSlide = slideIndex;
                            this.updateIndicators();
                            this.updateProgressBar();
                            this.announceSlideChange(slideIndex);
                            
                            // Trigger slide-specific animations
                            this.triggerSlideAnimations(entry.target);
                        }
                    }
                });
            },
            {
                threshold: [0.1, 0.5, 0.9],
                rootMargin: '-10% 0px'
            }
        );

        this.slides.forEach(slide => slideObserver.observe(slide));
    }

    setupProgressTracking() {
        // Track overall scroll progress
        window.addEventListener('scroll', () => {
            const scrollTop = window.pageYOffset;
            const docHeight = document.documentElement.scrollHeight - window.innerHeight;
            const scrollPercent = (scrollTop / docHeight) * 100;
            
            const progressFill = document.querySelector('.dataimago-progress-fill');
            if (progressFill) {
                progressFill.style.height = `${scrollPercent}%`;
            }
        }, { passive: true });
    }

    setupSlideAnimations() {
        // Add data attributes for animations
        this.slides.forEach((slide, index) => {
            // Add stagger animation to child elements
            const animatableElements = slide.querySelectorAll('h1, h2, h3, p, .feature-card, .architecture-layer');
            animatableElements.forEach((el, i) => {
                el.setAttribute('data-aos', 'fade-up');
                el.setAttribute('data-aos-delay', i * 100);
                el.setAttribute('data-aos-duration', '800');
            });
        });
    }

    triggerSlideAnimations(slide) {
        // Trigger animations for elements in the current slide
        const animatedElements = slide.querySelectorAll('[data-aos]');
        animatedElements.forEach((el, index) => {
            setTimeout(() => {
                el.style.opacity = '1';
                el.style.transform = 'translateY(0)';
            }, index * 100);
        });
    }

    goToSlide(index) {
        if (index < 0 || index >= this.slides.length || this.isNavigating) {
            return;
        }
        
        this.isNavigating = true;
        this.currentSlide = index;
        
        // Update UI immediately
        this.updateIndicators();
        this.updateProgressBar();
        
        // Use Lenis for smooth scrolling if available
        if (window.lenisIntegration?.lenis) {
            window.lenisIntegration.lenis.scrollTo(this.slides[index], {
                duration: 1.5,
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
            
            // Update indicator wrapper for visual feedback
            const wrapper = indicator.parentElement;
            wrapper.classList.toggle('active', isActive);
        });
    }

    updateProgressBar() {
        const progressText = document.querySelector('.dataimago-progress-text');
        if (progressText) {
            progressText.textContent = `${this.currentSlide + 1} / ${this.slides.length}`;
        }
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
        
        const slide = this.slides[slideIndex];
        const slideTitle = slide.querySelector('h1, h2, h3')?.textContent || 
                          slide.id.replace('-slide', '').replace('-', ' ') ||
                          `Slide ${slideIndex + 1}`;
        
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
        // Remove enhanced navigation
        const nav = document.querySelector('.dataimago-enhanced-nav');
        if (nav) nav.remove();
        
        // Remove progress bar
        const progress = document.querySelector('.dataimago-progress-container');
        if (progress) progress.remove();
        
        // Remove live region
        const liveRegion = document.getElementById('dataimago-slide-announcer');
        if (liveRegion) liveRegion.remove();
        
        console.log('🚀 Enhanced Landing Page Experience destroyed');
    }
}

// Initialize when script loads
const dataimagoLandingEnhanced = new DataimagoLandingPageEnhanced();

// Expose to global scope for debugging
window.dataimagoLandingEnhanced = dataimagoLandingEnhanced;

console.log('📜 Enhanced Landing Page Experience Script Loaded');