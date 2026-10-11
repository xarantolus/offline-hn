package io.github.xarantolus.page_capture

import android.net.Uri
import android.util.Log
import android.webkit.WebView
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import io.github.xarantolus.page_capture.filter.AdblockEngine

/** Runs the scriptlets the lists name for a page before any of the page's own scripts. */
object Scriptlets {
    private const val TAG = "PageCapture"

    fun install(web: WebView, engine: AdblockEngine, url: String) {
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) return
        val script = engine.cosmetic(url).script
        if (script.isEmpty()) return
        val host = Uri.parse(url).host?.lowercase() ?: return
        val twin = if (host.startsWith("www.")) host.removePrefix("www.") else "www.$host"
        val origins = listOf(host, twin).flatMap { listOf("https://$it", "http://$it") }.toSet()
        WebViewCompat.addDocumentStartJavaScript(web, script, origins)
        Log.i(TAG, "scriptlets for $host: ${script.length} chars")
    }
}
