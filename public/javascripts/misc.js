
window.pathToUrl = (function() {
  var base = null;
  return function(path) {
    if (base == null) {
      base = $('meta[name=base_url]').attr('content').replace(/\/+$/, '');
    }
    return base + path;
  }
})();

function escapeHtml(text) {
  // From http://stackoverflow.com/questions/24816/escaping-html-strings-with-jquery
  // Caveat: does not preserve whitespace.
  return $('<div/>').text(text).html();
}

function getMeta(name) {
  return $('meta[name=' + name + ']').attr('content');
}
