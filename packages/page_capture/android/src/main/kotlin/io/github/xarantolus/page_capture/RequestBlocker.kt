package io.github.xarantolus.page_capture

import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import io.github.xarantolus.page_capture.filter.FilterSet
import io.github.xarantolus.page_capture.filter.RequestInfo
import io.github.xarantolus.page_capture.filter.ResourceTypes
import java.io.ByteArrayInputStream
import java.util.concurrent.atomic.AtomicInteger

class RequestBlocker(private val filters: FilterSet) {
    private val blockedCount = AtomicInteger()

    val blocked: Int get() = blockedCount.get()

    /** A refusal for requests the lists block; never for the page itself. */
    fun intercept(request: WebResourceRequest, pageHost: String): WebResourceResponse? {
        if (request.isForMainFrame) return null
        val url = request.url.toString()
        if (!url.startsWith("http")) return null
        val info = RequestInfo.of(url, pageHost, guessType(request))
        if (!filters.shouldBlock(info)) return null
        blockedCount.incrementAndGet()
        return WebResourceResponse("text/plain", "utf-8", 403, "Blocked", emptyMap(), ByteArrayInputStream(ByteArray(0)))
    }

    private fun guessType(request: WebResourceRequest): Int {
        val headers = request.requestHeaders
        val accept = headers.entries.firstOrNull { it.key.equals("Accept", true) }?.value.orEmpty()
        val extension = request.url.lastPathSegment?.substringAfterLast('.', "")?.lowercase().orEmpty()
        return when {
            accept.startsWith("text/html") -> ResourceTypes.SUBDOCUMENT
            accept.startsWith("text/css") -> ResourceTypes.STYLESHEET
            accept.startsWith("image/") -> ResourceTypes.IMAGE
            extension in SCRIPTS -> ResourceTypes.SCRIPT
            extension in STYLES -> ResourceTypes.STYLESHEET
            extension in IMAGES -> ResourceTypes.IMAGE
            extension in FONTS -> ResourceTypes.FONT
            extension in MEDIA -> ResourceTypes.MEDIA
            headers.keys.any { it.equals("X-Requested-With", true) } || accept.startsWith("application/json") ->
                ResourceTypes.XHR
            else -> ResourceTypes.UNKNOWN
        }
    }

    private companion object {
        val SCRIPTS = setOf("js", "mjs")
        val STYLES = setOf("css")
        val IMAGES = setOf("png", "jpg", "jpeg", "gif", "webp", "avif", "svg", "ico", "bmp")
        val FONTS = setOf("woff", "woff2", "ttf", "otf", "eot")
        val MEDIA = setOf("mp4", "webm", "mp3", "m4a", "ogg", "m3u8", "mpd")
    }
}
