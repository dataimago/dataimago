/**
 * lenis-integration.js - dataimago Design System
 * Built: 2025-08-28T14:46:13.376Z
 * Source: ui/src/js/lenis-integration.js
 */
/**
 * Lenis Integration for HelloWorld Website
 * Provides smooth scrolling and slide-based navigation
 */

class LenisIntegration {
    constructor() {
        this.lenis = null;
        this.currentSlide = 0;
        this.slides = [];
        this.isScrolling = false;
        this.scrollTimeout = null;
        
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
        console.log('🚀 Initializing Lenis Integration');
        
        // Initialize Lenis with optimized settings
        this.lenis = new Lenis({
            duration: 1.0,
            easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
            direction: 'vertical',
            gestureOrientation: 'vertical',
            smooth: true,
            smoothTouch: false,
            touchMultiplier: 1.5,
            wheelMultiplier: 1,
            infinite: false,
            autoResize: true,
            syncTouch: false,
            overscroll: false
        });

        // Start the animation loop
        this.startAnimationLoop();
        
        // Setup slide navigation
        this.setupSlideNavigation();
        
        // Setup hero content scroller (replacement for carousel)
        this.setupHeroContentScroller();
        
        // Setup scroll-triggered animations
        this.setupScrollAnimations();
        
        // Setup intersection observers for slide transitions
        this.setupIntersectionObservers();
        
        // Setup navbar scroll effects (replaces jQuery scroll handler)
        this.setupNavbarScrollEffects();
        
        console.log('✅ Lenis Integration Complete');
    }

    startAnimationLoop() {
        const raf = (time) => {
            this.lenis.raf(time);
            requestAnimationFrame(raf);
        };
        requestAnimationFrame(raf);
    }

    setupSlideNavigation() {
        // Get all slides
        this.slides = document.querySelectorAll('.lenis-slide');
        
        if (this.slides.length === 0) {
            console.warn('⚠️ No slides found with class .lenis-slide');
            return;
        }
        
        console.log(`📄 Found ${this.slides.length} slides`);
        
        // Add keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (this.isScrolling) return;
            
            switch(e.key) {
                case 'ArrowDown':
                case 'PageDown':
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
            }
        });
        
        // Add slide indicators
        this.createSlideIndicators();
    }

    createSlideIndicators() {
        // Create slide navigation indicators
        const nav = document.createElement('nav');
        nav.className = 'lenis-slide-nav';
        nav.setAttribute('aria-label', 'Slide navigation');
        
        const indicatorsList = document.createElement('ul');
        indicatorsList.className = 'slide-indicators';
        
        this.slides.forEach((_, index) => {
            const li = document.createElement('li');
            const button = document.createElement('button');
            button.className = `slide-indicator ${index === 0 ? 'active' : ''}`;
            button.setAttribute('aria-label', `Go to slide ${index + 1}`);
            button.setAttribute('data-slide', index);
            
            button.addEventListener('click', () => this.goToSlide(index));
            
            li.appendChild(button);
            indicatorsList.appendChild(li);
        });
        
        nav.appendChild(indicatorsList);
        document.body.appendChild(nav);
    }

    goToSlide(index) {
        if (index < 0 || index >= this.slides.length || this.isScrolling) return;
        
        this.isScrolling = true;
        this.currentSlide = index;
        
        // Update indicators
        document.querySelectorAll('.slide-indicator').forEach((indicator, i) => {
            indicator.classList.toggle('active', i === index);
        });
        
        // Scroll to slide
        this.lenis.scrollTo(this.slides[index], {
            duration: 2.5,
            easing: (t) => 1 - Math.pow(1 - t, 3),
            onComplete: () => {
                this.isScrolling = false;
            }
        });
    }

    goToNextSlide() {
        this.goToSlide(Math.min(this.currentSlide + 1, this.slides.length - 1));
    }

    goToPrevSlide() {
        this.goToSlide(Math.max(this.currentSlide - 1, 0));
    }

    setupHeroContentScroller() {
        // Replace the old carousel with smooth scrolling content area
        const contentScroller = document.querySelector('.hero-content-scroller');
        if (!contentScroller) return;
        
        console.log('🎠 Setting up Hero Content Scroller');
        
        // Create Lenis instance for the hero content area
        const heroLenis = new Lenis({
            wrapper: contentScroller,
            content: contentScroller.querySelector('.scroller-content'),
            duration: 1.2,
            easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
            direction: 'vertical',
            smoothWheel: true,
            smoothTouch: false,
            wheelMultiplier: 1.5,
            touchMultiplier: 2,
            infinite: false,
            autoResize: true,
        });

        // Animation loop for hero scroller
        const heroRaf = (time) => {
            heroLenis.raf(time);
            requestAnimationFrame(heroRaf);
        };
        requestAnimationFrame(heroRaf);

        // Add scroll indicators for the hero content
        this.addHeroScrollIndicators(contentScroller, heroLenis);
    }

    addHeroScrollIndicators(scroller, heroLenis) {
        const indicator = document.createElement('div');
        indicator.className = 'hero-scroll-indicator';
        indicator.innerHTML = '<div class="scroll-progress"></div>';
        scroller.appendChild(indicator);

        heroLenis.on('scroll', (e) => {
            const progress = e.progress;
            const progressBar = indicator.querySelector('.scroll-progress');
            if (progressBar) {
                progressBar.style.height = `${progress * 100}%`;
            }
        });
    }

    setupScrollAnimations() {
        // Animate elements as they come into view
        const animateElements = document.querySelectorAll('[data-lenis-animate]');
        
        animateElements.forEach(element => {
            const animationType = element.getAttribute('data-lenis-animate');
            element.style.opacity = '0';
            element.style.transform = this.getInitialTransform(animationType);
            element.style.transition = 'opacity 0.8s ease, transform 0.8s ease';
        });
    }

    getInitialTransform(type) {
        switch(type) {
            case 'fade-up':
                return 'translateY(30px)';
            case 'fade-down':
                return 'translateY(-30px)';
            case 'fade-left':
                return 'translateX(30px)';
            case 'fade-right':
                return 'translateX(-30px)';
            case 'scale':
                return 'scale(0.95)';
            default:
                return 'translateY(20px)';
        }
    }

    setupIntersectionObservers() {
        // Observer for slide changes
        const slideObserver = new IntersectionObserver(
            (entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const slideIndex = Array.from(this.slides).indexOf(entry.target);
                        if (slideIndex !== -1 && slideIndex !== this.currentSlide) {
                            this.currentSlide = slideIndex;
                            this.updateSlideIndicators();
                        }
                    }
                });
            },
            {
                threshold: 0.6,
                rootMargin: '-20% 0px'
            }
        );

        this.slides.forEach(slide => slideObserver.observe(slide));

        // Observer for animation elements
        const animationObserver = new IntersectionObserver(
            (entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.style.opacity = '1';
                        entry.target.style.transform = 'translate(0) scale(1)';
                        animationObserver.unobserve(entry.target);
                    }
                });
            },
            {
                threshold: 0.2,
                rootMargin: '0px 0px -10% 0px'
            }
        );

        document.querySelectorAll('[data-lenis-animate]').forEach(el => {
            animationObserver.observe(el);
        });
    }

    updateSlideIndicators() {
        document.querySelectorAll('.slide-indicator').forEach((indicator, index) => {
            indicator.classList.toggle('active', index === this.currentSlide);
        });
    }

    setupNavbarScrollEffects() {
        // Setup navbar shrinking based on Lenis scroll position
        // Replaces the jQuery $(window).scroll() handler to avoid conflicts
        console.log('🔧 Setting up Lenis-integrated navbar scroll effects');
        
        let isNavbarShrunk = false;
        const shrinkThreshold = 35; // pixels
        
        // Use Lenis scroll event instead of window scroll to avoid conflicts
        this.lenis.on('scroll', (e) => {
            const scrollY = e.scroll;
            const shouldShrink = scrollY > shrinkThreshold;
            
            // Only update DOM when state changes to optimize performance
            if (shouldShrink !== isNavbarShrunk) {
                isNavbarShrunk = shouldShrink;
                
                // Direct DOM updates - no nested RAF needed (already in Lenis RAF context)
                const navbar = document.querySelector('.navbar');
                const navbarTitle = document.querySelector('.navbar-title');
                const navbarLogo = document.querySelector('.navbar-logo');
                const body = document.body;
                
                if (shouldShrink) {
                    // Add shrink classes
                    navbar?.classList.add('shrink');
                    navbarTitle?.classList.add('shrink');
                    navbarLogo?.classList.add('shrink');
                    body?.classList.add('shrink');
                    
                    console.debug('📏 Navbar shrunk at scroll position:', scrollY);
                } else {
                    // Remove shrink classes
                    navbar?.classList.remove('shrink');
                    navbarTitle?.classList.remove('shrink');
                    navbarLogo?.classList.remove('shrink');
                    body?.classList.remove('shrink');
                    
                    console.debug('📏 Navbar expanded at scroll position:', scrollY);
                }
            }
        });
        
        console.log(`✅ Navbar scroll effects integrated with Lenis (threshold: ${shrinkThreshold}px)`);
    }

    // Public methods for external control
    scrollTo(target, options = {}) {
        if (this.lenis) {
            this.lenis.scrollTo(target, options);
        }
    }

    stop() {
        if (this.lenis) {
            this.lenis.stop();
        }
    }

    start() {
        if (this.lenis) {
            this.lenis.start();
        }
    }

    destroy() {
        if (this.lenis) {
            this.lenis.destroy();
        }
    }
}

// Initialize Lenis Integration when the script loads
const lenisIntegration = new LenisIntegration();

// Expose to global scope for debugging and external control
window.lenisIntegration = lenisIntegration;

console.log('📜 Lenis Integration Script Loaded');