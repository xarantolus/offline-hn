package io.github.xarantolus.page_capture.filter

import java.io.BufferedReader
import java.io.File

class FilterSet private constructor(
    private val blocks: RuleIndex,
    private val exceptions: RuleIndex,
    val cosmetic: CosmeticRules,
) {
    val networkRuleCount get() = blocks.size + exceptions.size

    fun shouldBlock(request: RequestInfo): Boolean {
        val rule = blocks.firstMatch(request) ?: return false
        if (rule.important) return true
        return exceptions.firstMatch(request) == null
    }

    companion object {
        fun parse(reader: BufferedReader): FilterSet = build(listOf(reader))

        fun parseAll(files: List<File>): FilterSet {
            val readers = files.map { it.bufferedReader() }
            try {
                return build(readers)
            } finally {
                readers.forEach { it.close() }
            }
        }

        private fun build(readers: List<BufferedReader>): FilterSet {
            val blocks = ArrayList<NetworkRule>()
            val exceptions = ArrayList<NetworkRule>()
            val hides = ArrayList<CosmeticRules.Rule>()
            val unhides = ArrayList<CosmeticRules.Rule>()
            for (reader in readers) reader.forEachLine { line ->
                if (line.isEmpty() || line[0] == '#') return@forEachLine
                val fields = line.split('\t')
                if (fields.size < 3) return@forEachLine
                when (fields[0]) {
                    "B" -> if (fields.size >= 4) blocks.add(NetworkRule.parse(fields))
                    "A" -> if (fields.size >= 4) exceptions.add(NetworkRule.parse(fields))
                    "H" -> hides.add(CosmeticRules.parse(fields))
                    "U" -> unhides.add(CosmeticRules.parse(fields))
                }
            }
            return FilterSet(RuleIndex(blocks), RuleIndex(exceptions), CosmeticRules(hides, unhides))
        }
    }
}
