package io.github.xarantolus.page_capture

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.github.xarantolus.page_capture.filter.AdblockEngine
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/** Loads the filter lists and the consent script, keeping them for a while between captures. */
class CaptureTooling(private val context: Context, private val assetPrefix: String) {
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var cachedFilters: Pair<String, AdblockEngine>? = null
    private var cachedConsent: ConsentAssets? = null
    private val release = Runnable {
        cachedFilters = null
        cachedConsent = null
    }

    /** Loads on a worker thread and hands the tools to [then] on the main thread. */
    fun prepare(request: CaptureRequest, then: (CaptureTools) -> Unit) {
        executor.execute {
            val tools = CaptureTools(filters(request), consent(request))
            main.post {
                main.removeCallbacks(release)
                main.postDelayed(release, KEEP_MILLIS)
                then(tools)
            }
        }
    }

    private fun filters(request: CaptureRequest): AdblockEngine? {
        if (!request.blockRequests && !request.hideElements) return null
        val directory = request.filterListsDirectory?.let(::File) ?: return null
        val files = directory.listFiles { file -> file.extension == LIST_EXTENSION }
            ?.sortedBy { it.name }
            ?.takeIf { it.isNotEmpty() }
            ?: return null
        val key = files.joinToString { "${it.name}:${it.length()}:${it.lastModified()}" }
        cachedFilters?.takeIf { it.first == key }?.let { return it.second }
        return try {
            AdblockEngine.open(files, File(directory, STORED_ENGINE), File(directory, STORED_KEY))
                ?.also { cachedFilters = key to it }
        } catch (e: IOException) {
            null
        }
    }

    private fun consent(request: CaptureRequest): ConsentAssets? {
        if (!request.rejectConsent) return null
        cachedConsent?.let { return it }
        return try {
            ConsentAssets(read("autoconsent/autoconsent.js"), read("autoconsent/rules.json"))
                .also { cachedConsent = it }
        } catch (e: IOException) {
            null
        }
    }

    private fun read(name: String): String =
        context.assets.open("$assetPrefix/$name").use { it.readBytes().toString(Charsets.UTF_8) }

    private companion object {
        const val LIST_EXTENSION = "txt"
        const val STORED_ENGINE = "engine.bin"
        const val STORED_KEY = "engine.key"
        const val KEEP_MILLIS = 120_000L
    }
}
