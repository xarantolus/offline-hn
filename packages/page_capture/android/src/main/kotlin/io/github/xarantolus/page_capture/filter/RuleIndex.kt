package io.github.xarantolus.page_capture.filter

/** Narrows the rules to try for a URL by host or by a token every match must contain. */
class RuleIndex(rules: List<NetworkRule>) {
    private val byHost = HashMap<String, MutableList<NetworkRule>>()
    private val byToken = HashMap<String, MutableList<NetworkRule>>()
    private val untokenised = ArrayList<NetworkRule>()

    val size = rules.size

    init {
        for (rule in rules) {
            val host = rule.anchoredHost()
            val token = if (host == null) rule.token() else null
            when {
                host != null -> byHost.getOrPut(host) { ArrayList(1) }.add(rule)
                token != null -> byToken.getOrPut(token) { ArrayList(1) }.add(rule)
                else -> untokenised.add(rule)
            }
        }
    }

    fun firstMatch(request: RequestInfo): NetworkRule? {
        for (suffix in HostNames.suffixes(request.host)) {
            byHost[suffix]?.let { found(it, request)?.let { rule -> return rule } }
        }
        val url = request.url
        var i = 0
        while (i < url.length) {
            if (!NetworkRule.isTokenChar(url[i])) {
                i++
                continue
            }
            var j = i
            while (j < url.length && NetworkRule.isTokenChar(url[j])) j++
            byToken[url.substring(i, j)]?.let {
                found(it, request)?.let { rule -> return rule }
            }
            i = j
        }
        return found(untokenised, request)
    }

    private fun found(rules: List<NetworkRule>, request: RequestInfo): NetworkRule? {
        for (rule in rules) {
            if (rule.matches(request)) return rule
        }
        return null
    }
}
