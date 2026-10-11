package io.github.xarantolus.page_capture

import android.util.Base64
import org.json.JSONArray
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.util.concurrent.Callable
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit

/**
 * Downloads the style sheets and font files a page's fonts need, outside the
 * page: the page itself may not read a cross-origin sheet, nor a font served
 * without CORS headers. Blocking; nothing here starts after [stopAt]
 * (`SystemClock.elapsedRealtime`).
 */
class FontFetcher(
    private val pageUrl: String,
    private val userAgent: String,
    private val stopAt: Long,
    private val clock: () -> Long,
) {
    private val pool: ExecutorService = Executors.newFixedThreadPool(PARALLEL)

    /** Each sheet's text by URL, with the sheets it imports. */
    fun styleSheets(hrefs: List<String>): Map<String, String> {
        val texts = LinkedHashMap<String, String>()
        var round = hrefs.distinct()
        while (round.isNotEmpty() && texts.size < MAX_SHEETS) {
            val wanted = round.filter { it !in texts }.take(MAX_SHEETS - texts.size)
            val fetched = wanted.zip(all(wanted.map { href -> Callable { text(href) } }))
            round = fetched.flatMap { (href, text) ->
                if (text == null) return@flatMap emptyList()
                texts[href] = text
                imports(text, href)
            }
        }
        return texts
    }

    /** `@font-face` rules carrying their fonts as data URIs, within the size limits. */
    fun fontFaceRules(faces: JSONArray): String {
        val wanted = List(faces.length()) { faces.getJSONObject(it) }
        val bodies = all(wanted.map { face -> Callable { font(face.optString("url")) } })
        var left = MAX_TOTAL_BYTES
        val css = StringBuilder()
        wanted.zip(bodies).forEach { (face, body) ->
            val type = body?.let(::fontType) ?: return@forEach
            if (body.size > left) return@forEach
            left -= body.size
            val data = Base64.encodeToString(body, Base64.NO_WRAP)
            css.append("@font-face{").append(face.optString("descriptors"))
                .append(";src:url(\"data:").append(type).append(";base64,").append(data).append("\")}\n")
        }
        return css.toString()
    }

    fun close() {
        pool.shutdownNow()
    }

    private fun <T> all(tasks: List<Callable<T?>>): List<T?> {
        val wait = stopAt - clock()
        if (tasks.isEmpty() || wait <= 0) return tasks.map { null }
        return pool.invokeAll(tasks, wait, TimeUnit.MILLISECONDS).map(::valueOf)
    }

    private fun <T> valueOf(future: Future<T?>): T? = try {
        if (future.isCancelled) null else future.get()
    } catch (e: Exception) {
        null
    }

    private fun text(href: String): String? =
        download(href, "text/css,*/*;q=0.1", MAX_SHEET_BYTES)?.toString(Charsets.UTF_8)

    private fun font(href: String): ByteArray? = download(href, "*/*", MAX_FONT_BYTES)

    private fun download(href: String, accept: String, limit: Int): ByteArray? {
        if (!href.startsWith("http")) return null
        val connection = try {
            URL(href).openConnection() as HttpURLConnection
        } catch (e: IOException) {
            return null
        }
        return try {
            connection.connectTimeout = TIMEOUT_MILLIS
            connection.readTimeout = TIMEOUT_MILLIS
            connection.setRequestProperty("User-Agent", userAgent)
            connection.setRequestProperty("Accept", accept)
            connection.setRequestProperty("Referer", pageUrl)
            originOf(pageUrl)?.let { connection.setRequestProperty("Origin", it) }
            if (connection.responseCode != HttpURLConnection.HTTP_OK) return null
            if (connection.contentLengthLong > limit) return null
            val out = ByteArrayOutputStream()
            connection.inputStream.use { input ->
                val buffer = ByteArray(BUFFER_BYTES)
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    out.write(buffer, 0, read)
                    if (out.size() > limit) return null
                }
            }
            out.toByteArray()
        } catch (e: IOException) {
            null
        } finally {
            connection.disconnect()
        }
    }

    companion object {
        private const val PARALLEL = 4
        private const val TIMEOUT_MILLIS = 5_000
        private const val BUFFER_BYTES = 16 * 1024
        private const val MAX_SHEETS = 10
        private const val MAX_SHEET_BYTES = 1_000_000
        private const val MAX_FONT_BYTES = 1_500_000
        private const val MAX_TOTAL_BYTES = 4_000_000

        private val IMPORT = Regex("""@import\s+(?:url\(\s*)?["']?([^"')\s;]+)""")

        fun imports(css: String, base: String): List<String> = IMPORT.findAll(css).mapNotNull { match ->
            try {
                URI(base).resolve(match.groupValues[1]).toString()
            } catch (e: IllegalArgumentException) {
                null
            }
        }.toList()

        /** The font's MIME type from its first bytes; null when it is not a font, e.g. an error page. */
        fun fontType(bytes: ByteArray): String? {
            if (bytes.size < 4) return null
            return when (String(bytes, 0, 4, Charsets.ISO_8859_1)) {
                "wOF2" -> "font/woff2"
                "wOFF" -> "font/woff"
                "OTTO" -> "font/otf"
                "\u0000\u0001\u0000\u0000", "true" -> "font/ttf"
                "ttcf" -> "font/collection"
                else -> null
            }
        }

        private fun originOf(url: String): String? = try {
            val uri = URI(url)
            if (uri.scheme == null || uri.host == null) null
            else "${uri.scheme}://${uri.host}${if (uri.port == -1) "" else ":${uri.port}"}"
        } catch (e: Exception) {
            null
        }
    }
}
