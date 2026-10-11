package io.github.xarantolus.page_capture

import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import io.github.xarantolus.page_capture.filter.AdblockEngine
import io.github.xarantolus.page_capture.filter.Verdict
import java.io.ByteArrayInputStream
import java.util.concurrent.atomic.AtomicInteger

class RequestBlocker(private val engine: AdblockEngine) {
    private val blockedCount = AtomicInteger()

    val blocked: Int get() = blockedCount.get()

    /** A refusal, or a stand-in resource, for requests the lists block; never for the page itself. */
    fun intercept(request: WebResourceRequest, pageUrl: String): WebResourceResponse? {
        if (request.isForMainFrame) return null
        val url = request.url.toString()
        if (!url.startsWith("http")) return null
        val verdict = engine.verdict(url, pageUrl, kindsOf(request)) ?: return null
        blockedCount.incrementAndGet()
        return when (verdict) {
            is Verdict.Block ->
                WebResourceResponse("text/plain", "utf-8", 403, "Blocked", emptyMap(), ByteArrayInputStream(ByteArray(0)))
            is Verdict.Redirect ->
                WebResourceResponse(
                    verdict.mimeType, null, 200, "OK",
                    mapOf("Access-Control-Allow-Origin" to "*"),
                    ByteArrayInputStream(verdict.body),
                )
        }
    }

    /** WebView gives no request type, so it is guessed; an unknown one is asked as everything a script can fetch. */
    private fun kindsOf(request: WebResourceRequest): List<String> {
        val headers = request.requestHeaders
        val accept = headers.entries.firstOrNull { it.key.equals("Accept", true) }?.value.orEmpty()
        val extension = request.url.lastPathSegment?.substringAfterLast('.', "")?.lowercase().orEmpty()
        val kind = when {
            accept.startsWith("text/html") -> "sub_frame"
            accept.startsWith("text/css") -> "stylesheet"
            accept.startsWith("image/") -> "image"
            extension in SCRIPTS -> "script"
            extension in STYLES -> "stylesheet"
            extension in IMAGES -> "image"
            extension in FONTS -> "font"
            extension in MEDIA -> "media"
            headers.keys.any { it.equals("X-Requested-With", true) } || accept.startsWith("application/json") -> "xhr"
            else -> return UNKNOWN
        }
        return listOf(kind)
    }

    private companion object {
        val UNKNOWN = listOf("script", "xhr", "other")
        val SCRIPTS = setOf("js", "mjs")
        val STYLES = setOf("css")
        val IMAGES = setOf("png", "jpg", "jpeg", "gif", "webp", "avif", "svg", "ico", "bmp")
        val FONTS = setOf("woff", "woff2", "ttf", "otf", "eot")
        val MEDIA = setOf("mp4", "webm", "mp3", "m4a", "ogg", "m3u8", "mpd")
    }
}
