package io.github.xarantolus.page_capture.filter

class CosmeticRules(hides: List<Rule>, unhides: List<Rule>) {
    class Rule(val selector: String, val include: List<String>, val exclude: List<String>) {
        fun appliesTo(host: String) = HostNames.appliesTo(host, include, exclude)
    }

    private val everywhere = hides.filter { it.include.isEmpty() }
    private val byDomain = HashMap<String, MutableList<Rule>>()
    private val unhidesBySelector = unhides.groupBy { it.selector }

    val size = hides.size

    init {
        for (rule in hides) {
            for (domain in rule.include) byDomain.getOrPut(domain) { ArrayList(1) }.add(rule)
        }
    }

    fun selectorsFor(host: String): List<String> {
        val selected = LinkedHashSet<String>()
        for (rule in everywhere) if (rule.appliesTo(host)) selected.add(rule.selector)
        for (suffix in HostNames.suffixes(host)) {
            byDomain[suffix]?.forEach { if (it.appliesTo(host)) selected.add(it.selector) }
        }
        selected.removeAll { selector -> unhidesBySelector[selector]?.any { it.appliesTo(host) } == true }
        return selected.toList()
    }

    companion object {
        fun parse(fields: List<String>): Rule {
            val domains = if (fields[1].isEmpty()) emptyList() else fields[1].split('|')
            return Rule(
                selector = fields[2],
                include = domains.filterNot { it.startsWith("~") },
                exclude = domains.filter { it.startsWith("~") }.map { it.substring(1) },
            )
        }
    }
}
