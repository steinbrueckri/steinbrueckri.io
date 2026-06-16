// Hide the mouse cursor after a short idle time, but ONLY while the
// baguetteBox lightbox overlay is open. Outside the lightbox the cursor
// always stays visible.
(function () {
    var mouseTimer = null;
    var cursorVisible = true;

    function getOverlay() {
        return document.getElementById('baguetteBox-overlay');
    }

    function lightboxOpen() {
        var overlay = getOverlay();
        return overlay && overlay.classList.contains('visible');
    }

    function showCursor(el) {
        if (el && !cursorVisible) {
            el.style.cursor = 'default';
            cursorVisible = true;
        }
    }

    function hideCursor(el) {
        if (el) {
            el.style.cursor = 'none';
            cursorVisible = false;
        }
    }

    document.addEventListener('mousemove', function () {
        if (mouseTimer) {
            window.clearTimeout(mouseTimer);
            mouseTimer = null;
        }

        var overlay = getOverlay();
        if (!lightboxOpen()) {
            // Never leave the cursor hidden once the lightbox is closed.
            showCursor(overlay);
            return;
        }

        showCursor(overlay);
        mouseTimer = window.setTimeout(function () {
            mouseTimer = null;
            hideCursor(overlay);
        }, 2000);
    });
})();
