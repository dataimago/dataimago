# Assets Directory

This directory contains all static assets for the dataimago-ai-native Quarto extension.

## 📁 Directory Structure

```
assets/
├── css/                    # Stylesheets and themes
│   ├── ai-native-light.scss   # Light theme styles
│   ├── ai-native-dark.scss    # Dark theme styles
│   ├── lenis-integration.scss # Smooth scrolling styles
│   └── components.scss        # Reusable component styles
├── js/                     # JavaScript functionality
│   ├── lenis-integration.js   # Main Lenis setup
│   ├── slide-navigation.js   # Slide navigation system
│   ├── hero-scroller.js      # Hero content scroller
│   └── accessibility.js      # Accessibility enhancements
└── img/                    # Image assets
    └── placeholder-logo.png   # Default logo placeholder
```

## 🎨 CSS Architecture

### Theme Files
- **`ai-native-light.scss`**: Complete light theme with all component styles
- **`ai-native-dark.scss`**: Complete dark theme with all component styles

### Component Files
- **`lenis-integration.scss`**: Core smooth scrolling and slide navigation styles
- **`components.scss`**: Reusable components (feature boxes, MiCP display, etc.)

### CSS Custom Properties
All stylesheets use CSS custom properties for theming:

```scss
:root {
  --dataimago-primary: #83838f;
  --dataimago-accent: #ff69b4;
  --dataimago-bg: var(--quarto-bg);
  --dataimago-text: var(--quarto-color);
}
```

## ⚡ JavaScript Architecture

### Core Functionality
- **`lenis-integration.js`**: Main Lenis smooth scroll setup and management
- **`slide-navigation.js`**: Slide-based navigation with keyboard support
- **`hero-scroller.js`**: Smooth scrolling content areas (carousel replacement)
- **`accessibility.js`**: Enhanced accessibility features and WCAG compliance

### Module Pattern
Each JavaScript file follows a modular class-based pattern:

```javascript
class DataimagoModule {
  constructor() {
    this.init();
  }
  
  init() {
    // Initialization logic
  }
  
  // Public API methods
  
  destroy() {
    // Cleanup logic
  }
}
```

## 🖼️ Image Assets

### Logo Guidelines
- **Format**: PNG with transparency preferred
- **Size**: Minimum 200x200px, optimal 400x400px
- **Naming**: Use descriptive names like `package-logo.png`

### Optimization
- Images should be optimized for web delivery
- Consider providing multiple resolutions (@1x, @2x, @3x)
- Use appropriate compression settings

## 🔧 Customization

### Overriding Styles
Users can override styles by:

1. **CSS Custom Properties**: Modify color scheme and spacing
2. **Additional CSS Files**: Include custom stylesheets after extension files
3. **Inline Styles**: Use `style` attributes for specific customizations

### Adding Assets
To add new assets:

1. Place files in appropriate subdirectories
2. Reference them in templates using relative paths
3. Update extension configuration if needed

### Performance Considerations
- **CSS Containment**: Used for optimal rendering performance
- **Content Visibility**: Implemented for off-screen content
- **Hardware Acceleration**: Applied to animated elements
- **Lazy Loading**: Consider for image assets

## 📱 Responsive Design

All CSS uses responsive design principles:
- **Mobile-first approach**: Styles scale up from mobile
- **Clamp functions**: `clamp()` for fluid typography and spacing
- **Container queries**: Where supported, for component-based responsiveness
- **Touch optimization**: Enhanced touch targets and interactions

## 🌍 Browser Support

### CSS Features
- **CSS Grid**: Full support (IE11+ with fallbacks)
- **CSS Custom Properties**: Modern browsers (IE11 needs PostCSS)
- **CSS Containment**: Progressive enhancement
- **Content Visibility**: Progressive enhancement

### JavaScript Features
- **ES6 Classes**: Transpiled for older browsers if needed
- **Intersection Observer**: Polyfill available
- **ResizeObserver**: Polyfill available
- **Modern Event Handling**: addEventListener with passive listeners

## 🚀 Performance

### Optimization Strategies
- **Critical CSS**: Above-the-fold styles prioritized
- **CSS Splitting**: Modular CSS for better caching
- **JavaScript Modules**: Async loading where possible
- **Asset Minification**: Production builds should minify assets

### Monitoring
- **Bundle Size**: Keep CSS under 50KB compressed
- **JavaScript Size**: Keep JS under 100KB compressed
- **Image Optimization**: Use modern formats (WebP, AVIF) when supported

## 🧪 Testing

### CSS Testing
- Cross-browser compatibility testing
- Responsive design testing across devices
- Accessibility testing with screen readers
- Performance testing with PageSpeed Insights

### JavaScript Testing
- Unit tests for each module
- Integration tests for component interactions
- Accessibility testing with keyboard navigation
- Performance profiling for smooth animations

## 📚 Documentation

Each asset file should include:
- **Header comments** explaining purpose and usage
- **Dependency information** for external resources
- **Version information** for tracking updates
- **Author/contributor information** for maintenance