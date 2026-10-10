package io.github.xarantolus.page_capture.filter

object ResourceTypes {
    const val SCRIPT = 1
    const val IMAGE = 2
    const val STYLESHEET = 4
    const val XHR = 8
    const val SUBDOCUMENT = 16
    const val MEDIA = 32
    const val FONT = 64
    const val OTHER = 128

    /** What a request could be when the browser does not say: anything fetched by script. */
    const val UNKNOWN = SCRIPT or XHR or OTHER

    fun fromCode(code: Char): Int = when (code) {
        's' -> SCRIPT
        'i' -> IMAGE
        'c' -> STYLESHEET
        'x' -> XHR
        'f' -> SUBDOCUMENT
        'm' -> MEDIA
        't' -> FONT
        'o' -> OTHER
        else -> 0
    }
}

class RequestInfo private constructor(
    val url: String,
    val pageHost: String,
    val typeMask: Int,
    val hostStart: Int,
    val hostEnd: Int,
) {
    val host: String get() = url.substring(hostStart, hostEnd)

    val thirdParty: Boolean = HostNames.site(host) != HostNames.site(pageHost)

    companion object {
        fun of(rawUrl: String, pageHost: String, typeMask: Int): RequestInfo {
            val hash = rawUrl.indexOf('#')
            val url = (if (hash >= 0) rawUrl.substring(0, hash) else rawUrl).lowercase()
            val scheme = url.indexOf("://")
            val start = if (scheme >= 0) scheme + 3 else 0
            var end = start
            while (end < url.length && url[end] !in "/?:@") end++
            if (end < url.length && url[end] == '@') {
                val userEnd = end + 1
                end = userEnd
                while (end < url.length && url[end] !in "/?:") end++
                return RequestInfo(url, pageHost, typeMask, userEnd, end)
            }
            return RequestInfo(url, pageHost, typeMask, start, end)
        }
    }
}
