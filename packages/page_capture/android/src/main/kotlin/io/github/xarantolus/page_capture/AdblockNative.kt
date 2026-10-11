package io.github.xarantolus.page_capture

object AdblockNative {
    init {
        System.loadLibrary("page_capture_adblock")
    }

    external fun build(lists: Array<String>): Long

    external fun load(bytes: ByteArray): Long

    /** Replaces the scriptlets and redirects; returns how many resources were read. */
    external fun useResources(handle: Long, text: String): Int

    external fun serialize(handle: Long): ByteArray

    /** Null allows; empty blocks; "r" followed by a body redirects. */
    external fun check(handle: Long, url: String, source: String, kind: String): String?

    external fun cosmetic(handle: Long, url: String): String

    external fun genericSelectors(
        handle: Long,
        classes: Array<String>,
        ids: Array<String>,
        exceptions: Array<String>,
    ): Array<String>

    external fun free(handle: Long)
}
