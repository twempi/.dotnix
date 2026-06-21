// ========================================
// Shared Utilities & Constants
// ========================================

const HANDLED_INTERNALLY = Symbol('handled');

const THEMES = [
    'stylix'
];

function isFramedStartpage() {
    try {
        return window.self !== window.top;
    } catch (_) {
        return true;
    }
}

function navigateTopLevel(url) {
    try {
        const nextUrl = new URL(url, window.location.href);
        if (nextUrl.protocol !== 'http:' && nextUrl.protocol !== 'https:') return;

        if (isFramedStartpage()) {
            window.parent.postMessage({
                type: 'startpage:navigate',
                href: nextUrl.href
            }, '*');
            return;
        }

        window.location.href = nextUrl.href;
    } catch (e) {
        console.error('Navigation failed', e);
    }
}

/**
 * Remove bookmark matching styles from elements
 */
function resetStyles(elements) {
    elements.forEach(el => {
        el.classList.remove("bookmark-match", "bookmark-nomatch", "primary-match");
        el.style.mixBlendMode = "";
    });
}

/**
 * Debounce a function call
 */
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}
