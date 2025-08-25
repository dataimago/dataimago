$(window).scroll(function(){
    if($(window).scrollTop() > 35) {
        $('.navbar').addClass("shrink");
        $('.navbar-title').addClass("shrink");
        $('.navbar-logo').addClass("shrink");
        $('body').addClass("shrink");
    } else {
        $('.navbar').removeClass("shrink");
        $('.navbar-title').removeClass("shrink");
        $('.navbar-logo').removeClass("shrink");
        $('body').removeClass("shrink");
    }
});

// Dropdown caret rotation functionality
$(document).ready(function() {
    // Use MutationObserver to watch for changes in dropdown state
    function observeDropdownChanges() {
        var observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.type === 'attributes') {
                    var $target = $(mutation.target);
                    if ($target.hasClass('dropdown-toggle')) {
                        var $dropdown = $target.closest('.dropdown, .nav-item');
                        var isExpanded = $target.attr('aria-expanded') === 'true';
                        
                        if (isExpanded) {
                            $dropdown.addClass('open');
                        } else {
                            $dropdown.removeClass('open');
                        }
                    }
                }
            });
        });
        
        // Observe all dropdown toggles for aria-expanded changes
        $('.navbar-nav .dropdown-toggle').each(function() {
            observer.observe(this, { 
                attributes: true, 
                attributeFilter: ['aria-expanded'] 
            });
        });
    }
    
    // Initialize observer
    observeDropdownChanges();
    
    // Fallback: Listen for click events and check state after a brief delay
    $('.navbar-nav .dropdown-toggle').on('click', function() {
        var $this = $(this);
        var $dropdown = $this.closest('.dropdown, .nav-item');
        
        // Check state after Quarto/Bootstrap has processed the click
        setTimeout(function() {
            var isExpanded = $this.attr('aria-expanded') === 'true';
            if (isExpanded) {
                $dropdown.addClass('open');
            } else {
                $dropdown.removeClass('open');
            }
        }, 50);
    });
    
    // Handle Bootstrap dropdown events if they exist
    $('.navbar-nav .dropdown, .navbar-nav .nav-item').on('show.bs.dropdown', function() {
        $(this).addClass('open');
    });
    
    $('.navbar-nav .dropdown, .navbar-nav .nav-item').on('hide.bs.dropdown', function() {
        $(this).removeClass('open');
    });
});
