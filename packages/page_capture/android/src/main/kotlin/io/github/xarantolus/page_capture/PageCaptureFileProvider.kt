package io.github.xarantolus.page_capture

import android.net.Uri
import androidx.core.content.FileProvider

class PageCaptureFileProvider : FileProvider() {
    /// A browser renders an archive only when the provider calls it one; the
    /// platform's own table has no entry for the .mhtml extension.
    override fun getType(uri: Uri): String? {
        val path = uri.path ?: return super.getType(uri)
        return if (path.endsWith(".mhtml")) ARCHIVE_TYPE else super.getType(uri)
    }

    private companion object {
        const val ARCHIVE_TYPE = "message/rfc822"
    }
}
