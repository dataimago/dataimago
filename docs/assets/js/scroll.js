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

$(document).ready(function() {
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

        $('.navbar-nav .dropdown-toggle').each(function() {
            observer.observe(this, {
                attributes: true,
                attributeFilter: ['aria-expanded']
            });
        });
    }

    observeDropdownChanges();

    $('.navbar-nav .dropdown-toggle').on('click', function() {
        var $this = $(this);
        var $dropdown = $this.closest('.dropdown, .nav-item');

        setTimeout(function() {
            var isExpanded = $this.attr('aria-expanded') === 'true';
            if (isExpanded) {
                $dropdown.addClass('open');
            } else {
                $dropdown.removeClass('open');
            }
        }, 50);
    });

    $('.navbar-nav .dropdown, .navbar-nav .nav-item').on('show.bs.dropdown', function() {
        $(this).addClass('open');
    });

    $('.navbar-nav .dropdown, .navbar-nav .nav-item').on('hide.bs.dropdown', function() {
        $(this).removeClass('open');
    });
});
