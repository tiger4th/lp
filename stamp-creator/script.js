document.addEventListener('DOMContentLoaded', () => {
    // Accordion functionality
    const accordionHeaders = document.querySelectorAll('.accordion-header');

    accordionHeaders.forEach(header => {
        header.addEventListener('click', () => {
            const body = header.nextElementSibling;
            const icon = header.querySelector('i');

            // Toggle active class on header
            header.classList.toggle('active');

            // Toggle open class on body
            if (header.classList.contains('active')) {
                body.style.maxHeight = body.scrollHeight + 'px';
                body.classList.add('open');
            } else {
                body.style.maxHeight = 0;
                body.classList.remove('open');
            }

            // Optional: Close other items
            /*
            accordionHeaders.forEach(otherHeader => {
                if (otherHeader !== header && otherHeader.classList.contains('active')) {
                    otherHeader.classList.remove('active');
                    otherHeader.nextElementSibling.style.maxHeight = 0;
                    otherHeader.nextElementSibling.classList.remove('open');
                }
            });
            */
        });
    });

    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();

            const targetId = this.getAttribute('href');
            if (targetId === '#') return;

            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                // Adjust for fixed header height
                const headerHeight = 70;
                const elementPosition = targetElement.getBoundingClientRect().top;
                const offsetPosition = elementPosition + window.pageYOffset - headerHeight;

                window.scrollTo({
                    top: offsetPosition,
                    behavior: "smooth"
                });
            }
        });
    });
});
