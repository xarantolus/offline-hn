package io.github.xarantolus.page_capture

import org.json.JSONArray

/** Brave's procedural filter module and the loop that applies its rules to a page. */
class ProceduralScript(library: String, apply: String) {
    private val prefix = "$library\n;($apply)("

    /** Evaluates to how many elements [rules] applied to. */
    fun forRules(rules: JSONArray): String = "$prefix$rules)"
}
