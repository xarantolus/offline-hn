package io.github.xarantolus.page_capture.filter

import android.os.SystemClock
import android.util.Base64
import android.util.Log
import io.github.xarantolus.page_capture.AdblockNative
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.locks.ReentrantReadWriteLock
import kotlin.concurrent.read
import kotlin.concurrent.write

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

/**
 * Owns a native handle. Whoever uses the engine holds a lease ([acquire]/[release]); [close] frees the
 * handle once the last lease is gone. Stray calls after that find an empty engine instead of freed memory.
 */
class AdblockEngine private constructor(private val handle: Long) {
    private val lock = ReentrantReadWriteLock()
    private var leases = 0
    private var closing = false
    private var freed = false

    @Synchronized
    fun acquire(): AdblockEngine {
        check(!closing) { "engine is closed" }
        leases++
        return this
    }

    fun release() {
        synchronized(this) {
            leases--
            if (!closing || leases > 0) return
        }
        free()
    }

    fun close() {
        synchronized(this) {
            closing = true
            if (leases > 0) return
        }
        free()
    }

    private fun free() = lock.write {
        if (freed) return@write
        freed = true
        AdblockNative.free(handle)
    }

    private fun <T> live(whenClosed: T, block: () -> T): T = lock.read { if (freed) whenClosed else block() }

    /** What to do with a request of any of [kinds]; null lets it through. */
    fun verdict(url: String, pageUrl: String, kinds: List<String>): Verdict? {
        for (kind in kinds) {
            val answer = live(null) { AdblockNative.check(handle, url, pageUrl, kind) } ?: continue
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
        val json = JSONObject(live(EMPTY_COSMETIC) { AdblockNative.cosmetic(handle, pageUrl) })
        return CosmeticResources(
            hide = strings(json.getJSONArray("hide")),
            exceptions = strings(json.getJSONArray("exceptions")),
            script = json.getString("script"),
            genericHidden = json.getBoolean("generichide"),
        )
    }

    fun genericSelectors(classes: List<String>, ids: List<String>, exceptions: List<String>): List<String> =
        live(emptyList()) {
            AdblockNative.genericSelectors(handle, classes.toTypedArray(), ids.toTypedArray(), exceptions.toTypedArray()).toList()
        }

    companion object {
        private const val TAG = "PageCapture"
        private const val EMPTY_COSMETIC = """{"hide":[],"exceptions":[],"script":"","generichide":false}"""
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
