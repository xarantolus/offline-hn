package io.github.xarantolus.page_capture

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.net.http.SslError
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.View
import android.webkit.CookieManager
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebStorage
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.RenderProcessGoneDetail
import io.github.xarantolus.page_capture.filter.AdblockEngine
import org.json.JSONObject
import org.json.JSONTokener
import java.io.File
import java.util.concurrent.atomic.AtomicInteger

/** What one capture needs besides the request, loaded before the WebView exists. */
class CaptureTools(val filters: AdblockEngine?, val consent: ConsentAssets?)

/** One page, start to finish, on the main thread. [onFinished] is called exactly once. */
class CaptureSession(
    private val context: Context,
    private val request: CaptureRequest,
    private val tools: CaptureTools,
    private val onFinished: (Map<String, Any?>) -> Unit,
) {
    private val main = Handler(Looper.getMainLooper())
    private val startedAt = SystemClock.elapsedRealtime()
    private val resources = AtomicInteger()
    private val blocker = tools.filters?.takeIf { request.blockRequests }?.let(::RequestBlocker)
    private val consent = tools.consent?.takeIf { request.rejectConsent }?.let(::ConsentBridge)

    @Volatile private var lastResource = startedAt
    @Volatile private var mainUrl = request.url
    @Volatile private var failure: CaptureOutcome.Failure? = null
    private var web: WebView? = null
    private var loaded = false
    private var finished = false
    private var removed = 0
    private var scrollSteps = 0
    private var cleanUpBegan: Long? = null
    private var consentSettled = false
    private var loadedAt: Long? = null
    private var scrollBeganAt: Long? = null
    private var saveBeganAt: Long? = null

    private val deadline get() = startedAt + request.overallMillis
    private val now get() = SystemClock.elapsedRealtime()

    fun start() {
        if (request.url.substringBefore('?').substringBefore('#').lowercase().endsWith(".pdf")) {
            return finish(CaptureOutcome.Failure.unsupported("application/pdf"))
        }
        resetBrowserState()
        val view = createWebView()
        web = view
        view.loadUrl(request.url)
        later(POLL_MILLIS, ::waitForLoad)
    }

    fun cancel() {
        if (!finished) finish(CaptureOutcome.Failure.cancelled())
    }

    private fun resetBrowserState() {
        CookieManager.getInstance().removeAllCookies(null)
        WebStorage.getInstance().deleteAllData()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun createWebView(): WebView {
        val density = context.resources.displayMetrics.density
        val width = (request.viewportWidth * density).toInt()
        val height = (request.viewportHeight * density).toInt()
        val view = WebView(context)
        view.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            mediaPlaybackRequiresUserGesture = true
            useWideViewPort = true
        }
        CookieManager.getInstance().setAcceptThirdPartyCookies(view, true)
        consent?.install(view)
        if (request.blockRequests) tools.filters?.let { Scriptlets.install(view, it, request.url) }
        view.setDownloadListener { _, _, _, mimeType, _ ->
            fail(CaptureOutcome.Failure.unsupported(mimeType ?: "application/octet-stream"))
        }
        view.webViewClient = client()
        view.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, width, height)
        view.onResume()
        view.resumeTimers()
        return view
    }

    private fun client() = object : WebViewClient() {
        override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
            val refusal = blocker?.intercept(request, mainUrl)
            if (refusal == null) {
                resources.incrementAndGet()
                lastResource = now
            }
            return refusal
        }

        override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
            mainUrl = url
            loaded = false
        }

        override fun onPageFinished(view: WebView, url: String) {
            loaded = true
            lastResource = now
        }

        override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
            if (!request.isForMainFrame || loaded) return
            val message = "${error.errorCode} ${error.description}"
            fail(
                if (error.errorCode == ERROR_TIMEOUT) CaptureOutcome.Failure.timeout(message)
                else CaptureOutcome.Failure.network(message),
            )
        }

        override fun onReceivedHttpError(view: WebView, request: WebResourceRequest, response: WebResourceResponse) {
            if (request.isForMainFrame && response.statusCode >= HTTP_ERROR) {
                fail(CaptureOutcome.Failure.http(response.statusCode))
            }
        }

        override fun onReceivedSslError(view: WebView, handler: SslErrorHandler, error: SslError) {
            handler.cancel()
            if (error.url.equals(mainUrl, ignoreCase = true)) fail(CaptureOutcome.Failure.ssl())
        }

        override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
            fail(CaptureOutcome.Failure.internal("renderer gone"))
            return true
        }
    }

    private fun waitForLoad() {
        failure?.let { return finish(it) }
        when {
            loaded -> {
                loadedAt = now
                waitForQuiet(QUIET_AFTER_LOAD_MILLIS, ::scroll)
            }
            now > deadline -> finish(CaptureOutcome.Failure.timeout("page did not finish loading"))
            else -> later(POLL_MILLIS, ::waitForLoad)
        }
    }

    private fun waitForQuiet(maxMillis: Long, next: () -> Unit) {
        val begin = now
        fun check() {
            failure?.let { return finish(it) }
            val quiet = now - lastResource > request.idleMillis
            if (quiet || now > deadline || now - begin > maxMillis) next() else later(POLL_MILLIS, ::check)
        }
        check()
    }

    private fun scroll() {
        if (scrollBeganAt == null) scrollBeganAt = now
        if (now > deadline || scrollSteps >= MAX_SCROLL_STEPS) {
            return waitForQuiet(QUIET_AFTER_SCROLL_MILLIS, ::cleanUp)
        }
        evaluate(PageScripts.METRICS) { raw ->
            val parts = raw.trim('"').split(' ').map { it.toDoubleOrNull() ?: 0.0 }
            val atBottom = parts.size == 3 && parts[2] + parts[0] + 2 >= parts[1]
            if (atBottom && scrollSteps > 0) {
                waitForQuiet(QUIET_AFTER_SCROLL_MILLIS, ::cleanUp)
            } else {
                scrollSteps++
                evaluate(PageScripts.SCROLL_STEP) { later(SCROLL_PAUSE_MILLIS, ::scroll) }
            }
        }
    }

    private fun cleanUp() {
        failure?.let { return finish(it) }
        val began = cleanUpBegan ?: now.also { cleanUpBegan = it }
        if (consent != null && consent.pending > 0 && now - began < CONSENT_GRACE_MILLIS) {
            return later(POLL_MILLIS, ::cleanUp)
        }
        if (consent != null && consent.handlers.isNotEmpty() && !consentSettled) {
            consentSettled = true
            return later(CONSENT_SETTLE_MILLIS) { waitForQuiet(QUIET_AFTER_SCROLL_MILLIS, ::cleanUp) }
        }
        if (!request.hideElements) return settle()
        evaluate(PageScripts.REMOVE_OVERLAYS) { overlays ->
            removed += overlays.toIntOrNull() ?: 0
            hiddenSelectors { selectors ->
                evaluate(PageScripts.removeElements(selectors)) { count ->
                    removed += count.toIntOrNull() ?: 0
                    settle()
                }
            }
        }
    }

    private fun hiddenSelectors(then: (List<String>) -> Unit) {
        val engine = tools.filters ?: return then(emptyList())
        val cosmetic = engine.cosmetic(mainUrl)
        if (cosmetic.genericHidden) return then(cosmetic.hide)
        evaluate(PageScripts.PAGE_NAMES) { raw ->
            val names = parseNames(raw)
            then(cosmetic.hide + engine.genericSelectors(names.first, names.second, cosmetic.exceptions))
        }
    }

    private fun parseNames(raw: String): Pair<List<String>, List<String>> = try {
        val json = JSONObject(JSONTokener(raw).nextValue() as String)
        fun list(key: String) = json.getJSONArray(key).let { array -> List(array.length()) { array.getString(it) } }
        list("c") to list("i")
    } catch (e: Exception) {
        emptyList<String>() to emptyList()
    }

    private fun settle() {
        evaluate(PageScripts.SCROLL_TOP) { later(request.settleMillis, ::save) }
    }

    private fun save() {
        val view = web ?: return
        saveBeganAt = now
        val output = File(request.outputPath)
        output.parentFile?.mkdirs()
        output.delete()
        later(request.saveMillis) { fail(CaptureOutcome.Failure.timeout("saving the archive")) }
        view.saveWebArchive(output.absolutePath, false) { path ->
            if (finished) return@saveWebArchive
            val size = path?.let(::File)?.takeIf { it.isFile }?.length()
            when {
                size == null -> finish(CaptureOutcome.Failure.internal("saveWebArchive returned nothing"))
                size > request.maxBytes -> finish(CaptureOutcome.Failure.tooLarge(size))
                else -> finish(
                    CaptureOutcome.Success(
                        size,
                        resources.get(),
                        blocker?.blocked ?: 0,
                        removed,
                        consent?.handlers ?: emptyList(),
                        view.url,
                        (request.blockRequests || request.hideElements) && tools.filters == null,
                        phases(),
                    ),
                )
            }
        }
    }

    /** Milliseconds per phase; a phase the capture never reached is 0. */
    private fun phases(): Map<String, Long> {
        val end = now
        val loaded = loadedAt ?: end
        val scrolling = scrollBeganAt ?: loaded
        val cleaning = cleanUpBegan ?: scrolling
        val saving = saveBeganAt ?: cleaning
        return mapOf(
            "load" to loaded - startedAt,
            "idle" to scrolling - loaded,
            "scroll" to cleaning - scrolling,
            "cleanup" to saving - cleaning,
            "save" to end - saving,
        )
    }

    private fun evaluate(script: String, then: (String) -> Unit) {
        val view = web
        if (finished || view == null) return
        view.evaluateJavascript(script) { result -> if (!finished) then(result ?: "") }
    }

    private fun later(delayMillis: Long, action: () -> Unit) {
        main.postDelayed({ if (!finished) action() }, delayMillis)
    }

    private fun fail(outcome: CaptureOutcome.Failure) {
        if (failure == null) failure = outcome
        main.post { if (!finished) finish(failure ?: outcome) }
    }

    private fun finish(outcome: CaptureOutcome) {
        if (finished) return
        finished = true
        main.removeCallbacksAndMessages(null)
        web?.let { view ->
            view.stopLoading()
            view.webViewClient = WebViewClient()
            view.destroy()
        }
        web = null
        if (outcome is CaptureOutcome.Failure) File(request.outputPath).delete()
        onFinished(outcome.toMap(now - startedAt))
    }

    private companion object {
        const val POLL_MILLIS = 250L
        const val SCROLL_PAUSE_MILLIS = 350L
        const val QUIET_AFTER_LOAD_MILLIS = 25_000L
        const val QUIET_AFTER_SCROLL_MILLIS = 10_000L
        const val CONSENT_GRACE_MILLIS = 8_000L
        const val CONSENT_SETTLE_MILLIS = 2_500L
        const val MAX_SCROLL_STEPS = 50
        const val HTTP_ERROR = 400
    }
}
