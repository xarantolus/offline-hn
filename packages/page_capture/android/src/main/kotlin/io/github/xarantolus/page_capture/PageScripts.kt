package io.github.xarantolus.page_capture

import org.json.JSONArray
import org.json.JSONObject

object PageScripts {
    const val METRICS = "[window.innerHeight, document.documentElement.scrollHeight, window.scrollY].join(' ')"

    const val SCROLL_STEP = "window.scrollBy(0, 700)"

    const val SCROLL_TOP = "window.scrollTo(0, 0)"

    /** The style sheets the page may not read, as a JSON array of URLs. */
    const val UNREADABLE_SHEETS = """
        (function () {
          var hrefs = [];
          var walk = function (sheet) {
            var rules;
            try { rules = sheet.cssRules; } catch (e) { if (sheet.href) hrefs.push(sheet.href); return; }
            for (var i = 0; i < rules.length; i++) {
              if (rules[i].styleSheet) walk(rules[i].styleSheet);
            }
          };
          var all = Array.prototype.slice.call(document.styleSheets).concat(document.adoptedStyleSheets || []);
          all.forEach(walk);
          return JSON.stringify(hrefs);
        })()
    """

    /**
     * The font faces the page loaded, as a JSON array of `{url, descriptors}`:
     * one source to download and the rule's other descriptors. [sheets] maps
     * each unreadable sheet's URL to its text, fetched outside the page. A face
     * whose source is already a data URI is left out, the archive keeps it.
     */
    fun usedFontFaces(sheets: Map<String, String>): String = """
        (function (fetched) {
          var plain = function (s) { return String(s).trim().replace(/^["']|["']${'$'}/g, ''); };
          var keyOf = function (f) { return [plain(f.family), f.style, f.weight, f.stretch, f.unicodeRange].join('|'); };
          var used = {};
          document.fonts.forEach(function (f) { if (f.status === 'loaded') used[keyOf(f)] = 1; });
          var faces = [];
          var walk = function (rules, base) {
            for (var i = 0; i < rules.length; i++) {
              var rule = rules[i];
              if (rule.type === 5) faces.push({ rule: rule, base: base });
              else if (rule.styleSheet) visit(rule.styleSheet, base);
              else if (rule.cssRules) walk(rule.cssRules, base);
            }
          };
          var visit = function (sheet, base) {
            var href = sheet.href || base;
            var rules;
            try { rules = sheet.cssRules; } catch (e) {
              var text = fetched[sheet.href];
              if (text === undefined) return;
              var copy = new CSSStyleSheet();
              try { copy.replaceSync(text); } catch (e2) { return; }
              rules = copy.cssRules;
            }
            walk(rules, href);
          };
          var all = Array.prototype.slice.call(document.styleSheets).concat(document.adoptedStyleSheets || []);
          all.forEach(function (sheet) { visit(sheet, document.baseURI); });
          var source = function (src, base) {
            var pattern = /url\(\s*(["']?)(.*?)\1\s*\)\s*(?:format\(\s*["']?([\w-]+)["']?\s*\))?/g;
            var found, first = null;
            while ((found = pattern.exec(src))) {
              var url = found[2], format = (found[3] || '').toLowerCase();
              if (url.indexOf('data:') === 0) return null;
              if (format === 'embedded-opentype' || format === 'svg') continue;
              var resolved;
              try { resolved = new URL(url, base).href; } catch (e) { continue; }
              if (format === 'woff2' || /\.woff2(${'$'}|[?#])/i.test(url)) return resolved;
              if (first === null) first = resolved;
            }
            return first;
          };
          var taken = {}, out = [];
          for (var i = faces.length - 1; i >= 0; i--) {
            var style = faces[i].rule.style;
            var descriptors = {};
            [['font-style', 'style'], ['font-weight', 'weight'], ['font-stretch', 'stretch'], ['unicode-range', 'unicodeRange']]
              .forEach(function (pair) { var v = style.getPropertyValue(pair[0]); if (v) descriptors[pair[1]] = v; });
            var key;
            try { key = keyOf(new FontFace(plain(style.getPropertyValue('font-family')), 'url(x)', descriptors)); } catch (e) { continue; }
            if (!used[key] || taken[key]) continue;
            taken[key] = 1;
            var url = source(style.getPropertyValue('src'), faces[i].base);
            if (!url) continue;
            var kept = [];
            for (var k = 0; k < style.length; k++) {
              if (style[k] !== 'src') kept.push(style[k] + ':' + style.getPropertyValue(style[k]));
            }
            out.unshift({ url: url, descriptors: kept.join(';') });
          }
          return JSON.stringify(out);
        })(${JSONObject(sheets)})
    """.trimIndent()

    /** Appends [css] as a style element, after every sheet the page has, so its rules win. */
    fun appendStyle(css: String): String =
        "(function (css) { var s = document.createElement('style'); s.textContent = css; " +
            "(document.body || document.documentElement).appendChild(s); return 1; })(${JSONObject.quote(css)})"

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
