package io.github.xarantolus.page_capture.filter

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class FilterSetTest {
    private fun filters(vararg lines: String) =
        FilterSet.parse(lines.joinToString("\n").reader().buffered())

    private fun blocked(
        set: FilterSet,
        url: String,
        page: String = "news.example.org",
        type: Int = ResourceTypes.IMAGE,
    ) = set.shouldBlock(RequestInfo.of(url, page, type))

    @Test
    fun hostAnchorMatchesTheHostAndItsSubdomainsOnly() {
        val set = filters("B\t||ads.example.com^\t\t")
        assertTrue(blocked(set, "https://ads.example.com/banner.png"))
        assertTrue(blocked(set, "https://eu.ads.example.com/banner.png"))
        assertFalse(blocked(set, "https://notads.example.com/banner.png"))
        assertFalse(blocked(set, "https://example.com/?from=ads.example.com"))
    }

    @Test
    fun separatorMatchesTheEndOfTheUrl() {
        val set = filters("B\t||tracker.net^\t\t")
        assertTrue(blocked(set, "https://tracker.net"))
        assertFalse(blocked(set, "https://tracker.network/x"))
    }

    @Test
    fun wildcardsAndAnchors() {
        val set = filters(
            "B\t/banner/*/img^\t\t",
            "B\t|https://beacon.\t\t",
            "B\t.gif|\t\t",
        )
        assertTrue(blocked(set, "https://a.com/banner/728x90/img?x=1"))
        assertFalse(blocked(set, "https://a.com/banner/img"))
        assertTrue(blocked(set, "https://beacon.a.com/p"))
        assertFalse(blocked(set, "https://a.com/https://beacon.b.com"))
        assertTrue(blocked(set, "https://a.com/pixel.gif"))
        assertFalse(blocked(set, "https://a.com/pixel.gif?x=1"))
    }

    @Test
    fun aTokenMustBeAWholeWordInTheUrl() {
        val set = filters("B\t/ads/\t\t")
        assertTrue(blocked(set, "https://a.com/ads/1.png"))
        assertFalse(blocked(set, "https://a.com/roads/1.png"))
    }

    @Test
    fun partyRestrictions() {
        val set = filters("B\t||cdn.example.org^\t3\t")
        assertTrue(blocked(set, "https://cdn.example.org/a.png", page = "other.com"))
        assertFalse(blocked(set, "https://cdn.example.org/a.png", page = "www.example.org"))
        val first = filters("B\t||cdn.example.org^\t1\t")
        assertTrue(blocked(first, "https://cdn.example.org/a.png", page = "www.example.org"))
        assertFalse(blocked(first, "https://cdn.example.org/a.png", page = "other.com"))
    }

    @Test
    fun compoundSuffixesCountAsOneSite() {
        assertEquals("bbc.co.uk", HostNames.site("static.files.bbc.co.uk"))
        assertEquals("example.com", HostNames.site("a.b.example.com"))
        assertEquals("10.0.0.1", HostNames.site("10.0.0.1"))
    }

    @Test
    fun domainOptionLimitsThePages() {
        val set = filters("B\t/promo.js\t\tshop.com|~safe.shop.com")
        assertTrue(blocked(set, "https://x.net/promo.js", page = "www.shop.com"))
        assertFalse(blocked(set, "https://x.net/promo.js", page = "safe.shop.com"))
        assertFalse(blocked(set, "https://x.net/promo.js", page = "other.com"))
    }

    @Test
    fun typeRestrictions() {
        val set = filters("B\t||metrics.io^\ts\t")
        assertTrue(blocked(set, "https://metrics.io/a", type = ResourceTypes.SCRIPT))
        assertTrue(blocked(set, "https://metrics.io/a", type = ResourceTypes.UNKNOWN))
        assertFalse(blocked(set, "https://metrics.io/a", type = ResourceTypes.IMAGE))
    }

    @Test
    fun exceptionsAllowAndImportantOverrides() {
        val set = filters(
            "B\t||ads.example.com^\t\t",
            "A\t||ads.example.com/ok^\t\t",
            "B\t||evil.net^\t!\t",
            "A\t||evil.net^\t\t",
        )
        assertTrue(blocked(set, "https://ads.example.com/bad"))
        assertFalse(blocked(set, "https://ads.example.com/ok/1.png"))
        assertTrue(blocked(set, "https://evil.net/x"))
    }

    @Test
    fun userinfoIsNotTheHost() {
        val set = filters("B\t||ads.example.com^\t\t")
        assertFalse(blocked(set, "https://ads.example.com@good.org/x"))
    }

    @Test
    fun cosmeticRulesApplyByDomainWithExceptions() {
        val set = filters(
            "H\t\t.ad-banner",
            "H\tnews.example.org\t#sponsored",
            "H\t~docs.example.org\t.promo",
            "U\tnews.example.org\t.ad-banner",
        )
        assertEquals(listOf(".ad-banner", ".promo"), set.cosmetic.selectorsFor("other.com"))
        assertEquals(listOf(".promo", "#sponsored"), set.cosmetic.selectorsFor("news.example.org"))
        assertEquals(listOf(".ad-banner"), set.cosmetic.selectorsFor("docs.example.org"))
    }

    @Test
    fun headerAndMalformedLinesAreIgnored() {
        val set = filters("#offline-hn-filters\t1\t2026-10-10T00:00:00.000Z", "B\tonly-two", "", "X\t1\t2\t3")
        assertEquals(0, set.networkRuleCount)
    }
}
