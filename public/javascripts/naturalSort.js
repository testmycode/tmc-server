/*
 * Natural sort ordering algorithm from
 * http://my.opera.com/GreyWyvern/blog/show.dml/1671288
 */
function naturalOrdering(a, b) {
  function chunkify(t) {
    var tz = [], x = 0, y = -1, n = 0, i, j;

    while (i = (j = t.charAt(x++)).charCodeAt(0)) {
      var m = (i == 46 || (i >=48 && i <= 57));
      if (m !== n) {
        tz[++y] = "";
        n = m;
      }
      tz[y] += j;
    }
    return tz;
  }

  var aa = chunkify(a);
  var bb = chunkify(b);

  for (x = 0; aa[x] && bb[x]; x++) {
    if (aa[x] !== bb[x]) {
      var c = Number(aa[x]), d = Number(bb[x]);
      if (c == aa[x] && d == bb[x]) {
        return c - d;
      } else return (aa[x] > bb[x]) ? 1 : -1;
    }
  }
  return aa.length - bb.length;
}

// Data tables extensions
jQuery.fn.dataTableExt.oSort['natural-asc']  = function(a,b) {
    return naturalOrdering(a,b);
};

jQuery.fn.dataTableExt.oSort['natural-desc'] = function(a,b) {
    return naturalOrdering(a,b) * -1;
};