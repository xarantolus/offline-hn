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

    /// The intent is aimed at one Custom Tabs provider. Left to the system, a
    /// type-less content:// link goes to whichever app claims such links (a
    /// wallet's pass handler does), and a browser given a MIME type offers a
    /// download instead of a page.
    fun openInCustomTab(path: String): Boolean {
        val provider = CustomTabsClient.getPackageName(context, null) ?: return false
        val uri = uriFor(path)
        val intent = CustomTabsIntent.Builder().build().intent
        intent.data = uri
        intent.setClassName(provider, entryPoint(provider) ?: return false)
        context.grantUriPermission(provider, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return launch(grant(intent, uri))
    }

    private fun entryPoint(provider: String): String? {
        val web = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .setPackage(provider)
        return context.packageManager
            .resolveActivity(web, PackageManager.MATCH_DEFAULT_ONLY)
            ?.activityInfo
            ?.name
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
    } catch (e: SecurityException) {
        false
    }

    companion object {
        const val AUTHORITY_SUFFIX = ".page_capture.fileprovider"
    }
}
