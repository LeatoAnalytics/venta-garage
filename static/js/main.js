// Add current year to footer
document.addEventListener('DOMContentLoaded', function() {
    // Update footer year
    const footerYear = document.querySelector('footer p');
    if (footerYear) {
        const currentYear = new Date().getFullYear();
        footerYear.innerHTML = footerYear.innerHTML.replace('{{ now.year }}', currentYear);
    }
    
    // Mobile navigation (if needed for smaller screens)
    const mobileNav = document.querySelector('.mobile-nav');
    const menuToggle = document.querySelector('.menu-toggle');
    
    if (menuToggle && mobileNav) {
        menuToggle.addEventListener('click', function() {
            mobileNav.classList.toggle('active');
            menuToggle.classList.toggle('active');
        });
    }
}); 