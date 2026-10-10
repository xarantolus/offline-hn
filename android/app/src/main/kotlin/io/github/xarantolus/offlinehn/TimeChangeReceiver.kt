package io.github.xarantolus.offlinehn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import dev.fluttercommunity.workmanager.buildTaskInputData

/**
 * Hands a timezone or clock change to Dart. The rule for when the daily sync
 * runs lives there; this only starts the task that applies it. The two
 * strings repeat `SyncTasks.reschedule` and `SyncTasks.rescheduleWork`.
 */
class TimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val request = OneTimeWorkRequestBuilder<BackgroundWorker>()
            .setInputData(buildTaskInputData(TASK, null, null, WORK_NAME))
            .build()
        WorkManager.getInstance(context)
            .enqueueUniqueWork(WORK_NAME, ExistingWorkPolicy.REPLACE, request)
    }

    private companion object {
        const val TASK = "reschedule"
        const val WORK_NAME = "sync:reschedule"
    }
}
