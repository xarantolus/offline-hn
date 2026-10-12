package io.github.xarantolus.page_capture

import android.util.Log
import android.webkit.WebView
import androidx.webkit.JavaScriptReplyProxy
import androidx.webkit.WebMessageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import org.json.JSONObject
import java.util.Collections
import java.util.concurrent.atomic.AtomicInteger

private const val SHIM = """
        window.autoconsentSendMessage = function (m) { __ohnConsent.postMessage(JSON.stringify(m)); };
        __ohnConsent.onmessage = function (e) { window.autoconsentReceiveMessage(JSON.parse(e.data)); };
    """
private const val CONFIG = """{"enabled":true,"autoAction":"optOut","disabledCmps":[],"enablePrehide":true,
        "enableCosmeticRules":true,"enableGeneratedRules":true,"enableHeuristicDetection":true,
        "heuristicMode":"reject","detectRetries":20,"isMainWorld":true,"prehideTimeout":2000,
        "logs":{"lifecycle":false,"rulesteps":false,"detectionsteps":false,"evals":false,
        "errors":true,"messages":false,"waits":false}}"""

/**
 * Built once, off the main thread. The rules are about 750 KB and every frame of every capture asks
 * for them, on the main thread, which the app's UI shares.
 */
class ConsentAssets(script: String, rulesJson: String) {
    val startScript = SHIM + script
    val initReply = """{"type":"initResp","config":$CONFIG,"rules":$rulesJson}"""
}

/** Runs DuckDuckGo's autoconsent in every frame of one capture and rejects the popups it finds. */
class ConsentBridge(private val assets: ConsentAssets) {
    private val rejected = Collections.synchronizedList(ArrayList<String>())
    private val open = AtomicInteger()

    val handlers: List<String> get() = synchronized(rejected) { rejected.toList() }

    /** Popups found whose rejection has not finished. */
    val pending: Int get() = open.get()

    fun install(web: WebView): Boolean {
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT) ||
            !WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)
        ) return false
        val origins = setOf("*")
        WebViewCompat.addWebMessageListener(web, BRIDGE, origins) { _, message, _, _, reply ->
            handle(message, reply)
        }
        WebViewCompat.addDocumentStartJavaScript(web, assets.startScript, origins)
        return true
    }

    private fun handle(message: WebMessageCompat, reply: JavaScriptReplyProxy) {
        val data = message.data ?: return
        val json = try {
            JSONObject(data)
        } catch (e: org.json.JSONException) {
            return
        }
        when (json.optString("type")) {
            "init" -> reply.postMessage(assets.initReply)
            "popupFound" -> open.incrementAndGet()
            "optOutResult" -> if (!json.optBoolean("result")) settle()
            "autoconsentDone" -> {
                settle()
                rejected.add(json.optString("cmp"))
            }
            "autoconsentError" -> Log.d(TAG, "autoconsent error: $data")
        }
    }

    private fun settle() {
        open.updateAndGet { (it - 1).coerceAtLeast(0) }
    }

    private companion object {
        const val TAG = "PageCapture"
        const val BRIDGE = "__ohnConsent"
    }
}
