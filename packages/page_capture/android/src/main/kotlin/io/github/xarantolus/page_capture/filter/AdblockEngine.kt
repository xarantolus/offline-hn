package io.github.xarantolus.page_capture.filter

import android.os.SystemClock
import android.util.Base64
import android.util.Log
import io.github.xarantolus.page_capture.AdblockNative
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class CosmeticResources(
    val hide: List<String>,
    val exceptions: List<String>,
    val script: String,
    val genericHidden: Boolean,
)

sealed interface Verdict {
    data object Block : Verdict

    class Redirect(val mimeType: String, val body: ByteArray) : Verdict
}

class AdblockEngine private constructor(private val handle: Long) {
    /** What to do with a request of any of [kinds]; null lets it through. */
    fun verdict(url: String, pageUrl: String, kinds: List<String>): Verdict? {
        for (kind in kinds) {
            val answer = AdblockNative.check(handle, url, pageUrl, kind) ?: continue
            return redirectOf(answer) ?: Verdict.Block
        }
        return null
    }

    private fun redirectOf(answer: String): Verdict.Redirect? {
        val match = DATA_URL.matchEntire(answer.removePrefix("r")) ?: return null
        val (mimeType, payload) = match.destructured
        return Verdict.Redirect(mimeType, Base64.decode(payload, Base64.DEFAULT))
    }

    fun cosmetic(pageUrl: String): CosmeticResources {
        val json = JSONObject(AdblockNative.cosmetic(handle, pageUrl))
        return CosmeticResources(
            hide = strings(json.getJSONArray("hide")),
            exceptions = strings(json.getJSONArray("exceptions")),
            script = json.getString("script"),
            genericHidden = json.getBoolean("generichide"),
        )
    }

    fun genericSelectors(classes: List<String>, ids: List<String>, exceptions: List<String>): List<String> =
        AdblockNative.genericSelectors(handle, classes.toTypedArray(), ids.toTypedArray(), exceptions.toTypedArray()).toList()

    @Suppress("unused", "ProtectedInFinal")
    protected fun finalize() {
        AdblockNative.free(handle)
    }

    companion object {
        private const val TAG = "PageCapture"
        private val DATA_URL = Regex("data:([^;,]+);base64,(.*)", RegexOption.DOT_MATCHES_ALL)

        private fun strings(array: JSONArray) = List(array.length()) { array.getString(it) }

        /** Loads the stored engine when it matches [lists]; builds it from them and stores it otherwise. Scriptlets and redirects come from [resources] when it exists. */
        fun open(lists: List<File>, stored: File, storedKey: File, resources: File?): AdblockEngine? {
            val engine = openLists(lists, stored, storedKey) ?: return null
            if (resources != null && resources.isFile) {
                val count = AdblockNative.useResources(engine.handle, resources.readText())
                Log.i(TAG, "adblock resources: $count")
            }
            return engine
        }

        private fun openLists(lists: List<File>, stored: File, storedKey: File): AdblockEngine? {
            val key = lists.joinToString { "${it.name}:${it.length()}:${it.lastModified()}" }
            val began = SystemClock.elapsedRealtime()
            if (stored.isFile && storedKey.isFile && storedKey.readText() == key) {
                val handle = AdblockNative.load(stored.readBytes())
                if (handle != 0L) {
                    Log.i(TAG, "adblock engine loaded in ${SystemClock.elapsedRealtime() - began} ms")
                    return AdblockEngine(handle)
                }
            }
            val handle = AdblockNative.build(Array(lists.size) { lists[it].readText() })
            if (handle == 0L) return null
            val bytes = AdblockNative.serialize(handle)
            stored.writeBytes(bytes)
            storedKey.writeText(key)
            Log.i(TAG, "adblock engine built from ${lists.size} lists in ${SystemClock.elapsedRealtime() - began} ms")
            return AdblockEngine(handle)
        }
    }
}
