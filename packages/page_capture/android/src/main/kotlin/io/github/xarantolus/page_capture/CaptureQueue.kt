package io.github.xarantolus.page_capture

import android.content.Context
import io.flutter.plugin.common.MethodChannel

/** Runs up to [MAX_ACTIVE] captures at a time, process-wide: a WebView is heavy and the engines share it. */
class CaptureQueue private constructor(
    private val context: Context,
    private val tooling: CaptureTooling,
) {
    private class Entry(val owner: Any, val request: CaptureRequest, val result: MethodChannel.Result) {
        var cancelled = false
        var session: CaptureSession? = null
    }

    private val entries = ArrayDeque<Entry>()
    private val active = HashSet<Entry>()

    fun submit(owner: Any, request: CaptureRequest, result: MethodChannel.Result) {
        entries.addLast(Entry(owner, request, result))
        startNext()
    }

    fun cancel(owner: Any, id: Int) {
        cancelWhere { it.owner === owner && it.request.id == id }
    }

    fun cancelAll(owner: Any) {
        cancelWhere { it.owner === owner }
    }

    private fun cancelWhere(matches: (Entry) -> Boolean) {
        val waiting = entries.filter(matches)
        entries.removeAll(waiting.toSet())
        for (entry in waiting) entry.result.success(CaptureOutcome.Failure.cancelled().toMap(0))
        for (entry in active.filter(matches)) {
            entry.cancelled = true
            entry.session?.cancel()
        }
    }

    private fun startNext() {
        while (active.size < MAX_ACTIVE) {
            val entry = entries.removeFirstOrNull() ?: return
            val alone = active.isEmpty()
            active.add(entry)
            tooling.prepare(entry.request) { tools ->
                if (entry.cancelled) return@prepare done(entry, CaptureOutcome.Failure.cancelled().toMap(0))
                val session = CaptureSession(context, entry.request, tools, clearsBrowserState = alone) { done(entry, it) }
                entry.session = session
                session.start()
            }
        }
    }

    private fun done(entry: Entry, outcome: Map<String, Any?>) {
        entry.result.success(outcome)
        active.remove(entry)
        startNext()
    }

    companion object {
        /** Pages captured at once; the Dart side runs the same number. */
        const val MAX_ACTIVE = 2

        private var instance: CaptureQueue? = null

        fun get(context: Context, assetPrefix: String): CaptureQueue =
            instance ?: CaptureQueue(context, CaptureTooling(context, assetPrefix)).also { instance = it }
    }
}
