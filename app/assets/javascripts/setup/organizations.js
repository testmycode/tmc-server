var Organizations = (function() {
    return {
        updateSlugPreview: function(value) {
            if (value.length > 0) {
                value += '/';
            }
            $("#organization-id-preview-slug").text(value);
        }
    }
})();
