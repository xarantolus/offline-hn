package io.github.xarantolus.page_capture

import org.json.JSONArray

object PageScripts {
    const val METRICS = "[window.innerHeight, document.documentElement.scrollHeight, window.scrollY].join(' ')"

    const val SCROLL_STEP = "window.scrollBy(0, 700)"

    const val SCROLL_TOP = "window.scrollTo(0, 0)"

    /**
     * The archive writer leaves font files out, so a copy would fall back to
     * whatever the phone has. This puts the font faces the page actually used
     * into their rules as data URIs, which the writer does keep. Runs on its
     * own: [FONTS_DONE] turns true when it is finished.
     */
    const val EMBED_FONTS = """
        (function () {
          window.__fontsDone = false;
          var finish = function () { window.__fontsDone = true; };
          try {
            var weights = { normal: '400', bold: '700' };
            var weightOf = function (w) { w = String(w || 'normal'); return weights[w] || w; };
            var plain = function (s) { return String(s).replace(/^["']|["']${'$'}/g, ''); };
            var used = {};
            document.fonts.forEach(function (f) {
              if (f.status === 'loaded') used[plain(f.family) + '|' + weightOf(f.weight) + '|' + (f.style || 'normal')] = 1;
            });
            var rules = [];
            var walk = function (list) {
              for (var i = 0; i < list.length; i++) {
                var rule = list[i];
                if (rule.cssRules && !rule.style) { try { walk(rule.cssRules); } catch (e) {} }
                else if (rule.styleSheet) { try { walk(rule.styleSheet.cssRules); } catch (e) {} }
                else if (rule.type === 5) {
                  var st = rule.style;
                  var key = plain(st.getPropertyValue('font-family')) + '|' + weightOf(st.getPropertyValue('font-weight')) + '|' + (st.getPropertyValue('font-style') || 'normal');
                  if (used[key]) rules.push(rule);
                }
              }
            };
            for (var s = 0; s < document.styleSheets.length; s++) {
              try { walk(document.styleSheets[s].cssRules); } catch (e) {}
            }
            var budget = 4000000;
            var one = function (rule) {
              var src = rule.style.getPropertyValue('src');
              var found = /url\(\s*["']?([^"')]+)["']?\s*\)/.exec(src);
              if (!found || found[1].indexOf('data:') === 0) return Promise.resolve();
              var base = rule.parentStyleSheet && rule.parentStyleSheet.href || document.baseURI;
              return fetch(new URL(found[1], base).href, { credentials: 'omit' })
                .then(function (r) { return r.ok ? r.blob() : null; })
                .then(function (blob) {
                  if (!blob || blob.size > 1500000 || blob.size > budget) return;
                  budget -= blob.size;
                  return new Promise(function (resolve) {
                    var reader = new FileReader();
                    reader.onload = function () {
                      rule.style.setProperty('src', 'url(' + reader.result + ')');
                      resolve();
                    };
                    reader.onerror = resolve;
                    reader.readAsDataURL(blob);
                  });
                })
                .catch(function () {});
            };
            Promise.all(rules.map(one)).then(finish, finish);
          } catch (e) { finish(); }
          return rules ? 'started' : 'none';
        })()
    """

    const val FONTS_DONE = "window.__fontsDone === true"

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
