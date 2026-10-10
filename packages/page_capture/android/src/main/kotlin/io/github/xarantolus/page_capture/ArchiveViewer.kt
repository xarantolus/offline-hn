package io.github.xarantolus.page_capture

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.content.FileProvider
import java.io.File

class ArchiveViewer(private val context: Context) {
    var activity: Activity? = null

    fun openInCustomTab(path: String): Boolean {
        val uri = uriFor(path)
        val intent = CustomTabsIntent.Builder().build().intent
        intent.data = uri
        return launch(grant(intent, uri))
    }

    fun openPdf(path: String): Boolean {
        val uri = uriFor(path)
        val intent = Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/pdf")
        return launch(grant(intent, uri))
    }

    private fun uriFor(path: String): Uri =
        FileProvider.getUriForFile(context, "${context.packageName}$AUTHORITY_SUFFIX", File(path))

    private fun grant(intent: Intent, uri: Uri): Intent {
        intent.clipData = ClipData.newRawUri("page", uri)
        return intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    private fun launch(intent: Intent): Boolean = try {
        val host = activity
        if (host != null) {
            host.startActivity(intent)
        } else {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
        true
    } catch (e: ActivityNotFoundException) {
        false
    }

    companion object {
        const val AUTHORITY_SUFFIX = ".page_capture.fileprovider"
    }
}
