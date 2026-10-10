package io.github.xarantolus.page_capture.filter

/** Matches the pattern part of an Adblock-syntax rule: `||`, `|`, `*` and `^`. */
class PatternMatcher(pattern: String) {
    private val hostAnchor: Boolean
    private val startAnchor: Boolean
    private val endAnchor: Boolean
    private val segments: List<String>

    init {
        var body = pattern
        var host = false
        var start = false
        var end = false
        if (body.startsWith("||")) {
            host = true
            body = body.substring(2)
        } else if (body.startsWith("|")) {
            start = true
            body = body.substring(1)
        }
        if (body.endsWith("|")) {
            end = true
            body = body.dropLast(1)
        }
        if (body.startsWith("*")) {
            host = false
            start = false
        }
        if (body.endsWith("*")) end = false
        hostAnchor = host
        startAnchor = start
        endAnchor = end
        segments = body.split('*').filter { it.isNotEmpty() }
    }

    fun matches(request: RequestInfo): Boolean {
        if (segments.isEmpty()) return true
        val url = request.url
        val first = segments[0]
        if (hostAnchor) {
            var position = request.hostStart
            while (position <= request.hostEnd) {
                if (position == request.hostStart || url[position - 1] == '.') {
                    if (matchFrom(url, 0, position)) return true
                }
                position++
            }
            return false
        }
        if (startAnchor) return matchFrom(url, 0, 0)
        var position = 0
        while (position <= url.length) {
            val found = find(first, url, position) ?: return false
            if (matchFrom(url, 0, found.first)) return true
            position = found.first + 1
        }
        return false
    }

    private fun matchFrom(url: String, index: Int, position: Int): Boolean {
        var at = position
        for (i in index until segments.size) {
            val segment = segments[i]
            if (i == index) {
                val end = matchAt(segment, url, at)
                if (end < 0) return false
                if (i == segments.size - 1 && endAnchor && end != url.length) return false
                at = end
            } else if (i == segments.size - 1 && endAnchor) {
                var p = at
                while (p <= url.length) {
                    if (matchAt(segment, url, p) == url.length) return true
                    p++
                }
                return false
            } else {
                at = find(segment, url, at)?.second ?: return false
            }
        }
        return true
    }

    /** First start and end of [segment] at or after [from]. */
    private fun find(segment: String, url: String, from: Int): Pair<Int, Int>? {
        if (!segment.contains('^')) {
            val index = url.indexOf(segment, from)
            return if (index < 0) null else index to index + segment.length
        }
        var p = from
        while (p <= url.length) {
            val end = matchAt(segment, url, p)
            if (end >= 0) return p to end
            p++
        }
        return null
    }

    private fun matchAt(segment: String, url: String, position: Int): Int {
        var at = position
        for (c in segment) {
            if (c == '^') {
                if (at == url.length) continue
                if (!isSeparator(url[at])) return -1
                at++
            } else {
                if (at >= url.length || url[at] != c) return -1
                at++
            }
        }
        return at
    }

    private fun isSeparator(c: Char): Boolean =
        !(c.isLetterOrDigit() || c == '_' || c == '-' || c == '.' || c == '%')
}
