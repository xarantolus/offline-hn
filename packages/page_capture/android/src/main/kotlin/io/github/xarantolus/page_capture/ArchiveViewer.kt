package io.github.xarantolus.page_capture

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.content.FileProvider
import java.io.File

class ArchiveViewer(private val context: Context) {
    var activity: Activity? = null

    /// The archive goes to a browser only when the system itself would hand a
    /// type-less content:// link to one: another app that claims such links
    /// (a wallet's pass handler does) must not get it, and a browser given a
    /// MIME type for it offers a download instead of a page.
    fun openInCustomTab(path: String): Boolean {
        val uri = uriFor(path)
        val intent = CustomTabsIntent.Builder().build().intent
        intent.data = uri
        val target = context.packageManager
            .resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            ?.activityInfo
            ?.packageName
        if (target == null || target != defaultBrowser()) return false
        return launch(grant(intent, uri))
    }

    private fun defaultBrowser(): String? {
        val probe = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
            .addCategory(Intent.CATEGORY_BROWSABLE)
        val match = context.packageManager.resolveActivity(probe, PackageManager.MATCH_DEFAULT_ONLY)
        val name = match?.activityInfo?.packageName
        return if (name == null || name == "android") null else name
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
