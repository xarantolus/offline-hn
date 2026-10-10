package io.github.xarantolus.page_capture.filter

class NetworkRule(
    val pattern: String,
    val important: Boolean,
    private val types: Int,
    private val party: Party,
    private val includeDomains: List<String>,
    private val excludeDomains: List<String>,
) {
    enum class Party { ANY, THIRD, FIRST }

    private val matcher = PatternMatcher(pattern)

    fun matches(request: RequestInfo): Boolean {
        if (types != 0 && types and request.typeMask == 0) return false
        if (party == Party.THIRD && !request.thirdParty) return false
        if (party == Party.FIRST && request.thirdParty) return false
        if (!HostNames.appliesTo(request.pageHost, includeDomains, excludeDomains)) return false
        return matcher.matches(request)
    }

    /** The host named by a `||host^` style pattern, when it is a whole host. */
    fun anchoredHost(): String? {
        if (!pattern.startsWith("||")) return null
        val end = pattern.indexOfFirst(2) { it in "^/:?" }
        if (end < 0) return null
        val host = pattern.substring(2, end)
        return host.takeIf { it.isNotEmpty() && it.all(::isHostChar) }
    }

    /** A run of letters and digits that any matching URL must contain as a whole token. */
    fun token(): String? {
        var body = pattern
        var leftBound = false
        if (body.startsWith("||") || body.startsWith("|")) {
            leftBound = true
            body = body.removePrefix("||").removePrefix("|")
        }
        val rightBound = body.endsWith("|")
        if (rightBound) body = body.dropLast(1)
        var best: String? = null
        var i = 0
        while (i < body.length) {
            if (!isTokenChar(body[i])) {
                i++
                continue
            }
            var j = i
            while (j < body.length && isTokenChar(body[j])) j++
            val before = if (i == 0) leftBound else body[i - 1] != '*'
            val after = if (j == body.length) rightBound else body[j] != '*'
            if (before && after && j - i >= MIN_TOKEN && (best == null || j - i > best.length)) {
                best = body.substring(i, j)
            }
            i = j
        }
        return best
    }

    private fun String.indexOfFirst(from: Int, predicate: (Char) -> Boolean): Int {
        for (i in from until length) if (predicate(this[i])) return i
        return -1
    }

    private fun isHostChar(c: Char) = c.isLetterOrDigit() || c == '.' || c == '-' || c == '_'

    companion object {
        private const val MIN_TOKEN = 3

        fun isTokenChar(c: Char) = c in 'a'..'z' || c in '0'..'9' || c == '%'

        fun parse(fields: List<String>): NetworkRule {
            val flags = fields[2]
            var party = Party.ANY
            var important = false
            var types = 0
            for (flag in flags) {
                when (flag) {
                    '3' -> party = Party.THIRD
                    '1' -> party = Party.FIRST
                    '!' -> important = true
                    else -> types = types or ResourceTypes.fromCode(flag)
                }
            }
            val domains = if (fields[3].isEmpty()) emptyList() else fields[3].split('|')
            return NetworkRule(
                pattern = fields[1],
                important = important,
                types = types,
                party = party,
                includeDomains = domains.filterNot { it.startsWith("~") },
                excludeDomains = domains.filter { it.startsWith("~") }.map { it.substring(1) },
            )
        }
    }
}
