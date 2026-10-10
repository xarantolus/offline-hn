package io.github.xarantolus.page_capture.filter

object HostNames {
    private val secondLevel = setOf("co", "com", "org", "net", "gov", "edu", "ac", "or", "ne", "go")

    /** The site a host belongs to, without a public suffix list: the last two labels, three after co.uk and similar. */
    fun site(host: String): String {
        if (host.contains(':') || host.all { it.isDigit() || it == '.' }) return host
        val labels = host.split('.')
        if (labels.size <= 2) return host
        val keep = if (labels.last().length == 2 && labels[labels.size - 2] in secondLevel) 3 else 2
        return labels.takeLast(keep).joinToString(".")
    }

    fun isWithin(host: String, domain: String): Boolean =
        host == domain || host.endsWith(".$domain")

    /** The host followed by each parent domain, longest first. */
    fun suffixes(host: String): List<String> {
        val result = ArrayList<String>()
        var rest = host
        while (true) {
            result.add(rest)
            val dot = rest.indexOf('.')
            if (dot < 0) return result
            rest = rest.substring(dot + 1)
        }
    }

    fun appliesTo(host: String, include: List<String>, exclude: List<String>): Boolean {
        if (exclude.any { isWithin(host, it) }) return false
        return include.isEmpty() || include.any { isWithin(host, it) }
    }
}
