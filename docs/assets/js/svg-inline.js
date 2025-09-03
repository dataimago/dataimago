/**
 * SVG Inline Injection - dataimago Design System
 * Converts <img> tags with SVG sources to inline SVG for CSS styling
 */

// Function to inline SVG images
function inlineSVGImages() {
  // Target all img elements with SVG sources that have logo classes
  const svgImages = document.querySelectorAll('img[src$=".svg"][class*="logo"]');
  
  svgImages.forEach(async (img) => {
    try {
      // Fetch the SVG content
      const response = await fetch(img.src);
      const svgText = await response.text();
      
      // Parse the SVG
      const parser = new DOMParser();
      const svgDoc = parser.parseFromString(svgText, 'image/svg+xml');
      const svg = svgDoc.querySelector('svg');
      
      if (svg) {
        // Copy all classes from img to svg
        if (img.className) {
          svg.setAttribute('class', img.className);
        }
        
        // Copy inline styles
        if (img.style.cssText) {
          svg.style.cssText = img.style.cssText;
        }
        
        // Copy other attributes (alt becomes title, etc.)
        if (img.alt) {
          svg.setAttribute('title', img.alt);
        }
        
        // Ensure proper sizing
        if (!svg.getAttribute('width') && !svg.getAttribute('height')) {
          const computedStyle = window.getComputedStyle(img);
          svg.style.width = computedStyle.width;
          svg.style.height = computedStyle.height;
        }
        
        // Replace img with svg
        img.parentNode.replaceChild(svg, img);
        
        console.log(`Inlined SVG: ${img.src}`);
      }
    } catch (error) {
      console.warn(`Failed to inline SVG: ${img.src}`, error);
    }
  });
}

// Run when DOM is loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', inlineSVGImages);
} else {
  inlineSVGImages();
}

// Also run when new content is dynamically added
const observer = new MutationObserver((mutations) => {
  mutations.forEach((mutation) => {
    if (mutation.type === 'childList') {
      mutation.addedNodes.forEach((node) => {
        if (node.nodeType === 1) { // Element node
          const svgImages = node.querySelectorAll ? 
            node.querySelectorAll('img[src$=".svg"][class*="logo"]') : [];
          if (svgImages.length > 0) {
            setTimeout(inlineSVGImages, 100); // Small delay for DOM stability
          }
        }
      });
    }
  });
});

observer.observe(document.body, { childList: true, subtree: true });
