package io.github.xarantolus.page_capture

import org.json.JSONArray

object PageScripts {
    const val METRICS = "[window.innerHeight, document.documentElement.scrollHeight, window.scrollY].join(' ')"

    const val SCROLL_STEP = "window.scrollBy(0, 700)"

    const val SCROLL_TOP = "window.scrollTo(0, 0)"

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

    /**
     * Removes modal overlays that cover most of the viewport (sign-in and
     * newsletter walls, leftover backdrops) unless they hold the article, and
     * gives scrolling back to a page that locked it. Returns how many went.
     */
    const val REMOVE_OVERLAYS = """
        (function () {
          var vw = window.innerWidth, vh = window.innerHeight, removed = 0;
          var total = ((document.body && document.body.textContent) || '').length;
          var candidates = document.querySelectorAll('body *');
          for (var i = 0; i < candidates.length; i++) {
            var el = candidates[i];
            if (!el.isConnected) continue;
            var style = getComputedStyle(el);
            if (style.position !== 'fixed' || style.display === 'none') continue;
            var box = el.getBoundingClientRect();
            if (box.width < vw * 0.9 || box.height < vh * 0.5) continue;
            if (el.querySelector('article, main, h1')) continue;
            if (total > 2000 && (el.textContent || '').length > total * 0.5) continue;
            el.remove();
            removed++;
          }
          [document.documentElement, document.body].forEach(function (root) {
            if (!root) return;
            var s = getComputedStyle(root);
            if (s.overflowY === 'hidden' || s.overflowY === 'clip') root.style.setProperty('overflow', 'auto', 'important');
            if (root === document.body && s.position === 'fixed') {
              root.style.setProperty('position', 'static', 'important');
            }
          });
          return removed;
        })()
    """
}
