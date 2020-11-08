window.addEventListener('load', function() {
    baguetteBox.run('.gallery', {
        overlayBackgroundColor: 'white',
        captions: function(element) {
            return element.getElementsByTagName('img')[0].alt;
        }
    });
});