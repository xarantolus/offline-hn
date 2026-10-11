package io.github.xarantolus.page_capture

import org.json.JSONArray

object PageScripts {
    const val METRICS = "[window.innerHeight, document.documentElement.scrollHeight, window.scrollY].join(' ')"

    const val SCROLL_STEP = "window.scrollBy(0, 700)"

    const val SCROLL_TOP = "window.scrollTo(0, 0)"

    /** The class and id names in the document, as a JSON string. */
    const val PAGE_NAMES = """
        (function () {
          var classes = {}, ids = {};
          var all = document.querySelectorAll('[class], [id]');
          for (var i = 0; i < all.length; i++) {
            var el = all[i];
            if (el.id) ids[el.id] = 1;
            var list = el.classList;
            if (list) for (var k = 0; k < list.length; k++) classes[list[k]] = 1;
          }
          return JSON.stringify({ c: Object.keys(classes), i: Object.keys(ids) });
        })()
    """

    /** Removes the elements the selectors match and returns how many went. */
    fun removeElements(selectors: List<String>): String = """
        (function (selectors) {
          var body = document.body;
          if (!body) return 0;
          var total = (body.textContent || '').length;
          var removed = 0;
          function protectedElement(el) {
            var tag = el.tagName;
            if (tag === 'HTML' || tag === 'BODY' || tag === 'HEAD' || tag === 'MAIN' || tag === 'ARTICLE') return true;
            if (el.querySelector('article, main')) return true;
            return total > 2000 && (el.textContent || '').length > total * 0.6;
          }
          function run(group) {
            var found;
            try { found = document.querySelectorAll(group); } catch (e) { return false; }
            for (var i = 0; i < found.length; i++) {
              var el = found[i];
              if (el.isConnected && !protectedElement(el)) { el.remove(); removed++; }
            }
            return true;
          }
          for (var i = 0; i < selectors.length; i += 300) {
            var chunk = selectors.slice(i, i + 300);
            if (!run(chunk.join(','))) { for (var k = 0; k < chunk.length; k++) run(chunk[k]); }
          }
          return removed;
        })(${JSONArray(selectors)})
    """.trimIndent()
}
