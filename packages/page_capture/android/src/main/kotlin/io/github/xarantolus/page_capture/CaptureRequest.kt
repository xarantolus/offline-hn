package io.github.xarantolus.page_capture

import io.flutter.plugin.common.MethodCall

class CaptureRequest(
    val id: Int,
    val url: String,
    val outputPath: String,
    val viewportWidth: Int,
    val viewportHeight: Int,
    val idleMillis: Long,
    val overallMillis: Long,
    val saveMillis: Long,
    val settleMillis: Long,
    val blockRequests: Boolean,
    val hideElements: Boolean,
    val rejectConsent: Boolean,
    val maxBytes: Long,
    val filterListsDirectory: String?,
    val filterResourcesFile: String,
) {
    companion object {
        fun from(call: MethodCall) = CaptureRequest(
            id = call.argument<Int>("id")!!,
            url = call.argument<String>("url")!!,
            outputPath = call.argument<String>("outputPath")!!,
            viewportWidth = call.argument<Int>("viewportWidth")!!,
            viewportHeight = call.argument<Int>("viewportHeight")!!,
            idleMillis = call.argument<Number>("idleMillis")!!.toLong(),
            overallMillis = call.argument<Number>("overallMillis")!!.toLong(),
            saveMillis = call.argument<Number>("saveMillis")!!.toLong(),
            settleMillis = call.argument<Number>("settleMillis")!!.toLong(),
            blockRequests = call.argument<Boolean>("blockRequests")!!,
            hideElements = call.argument<Boolean>("hideElements")!!,
            rejectConsent = call.argument<Boolean>("rejectConsent")!!,
            maxBytes = call.argument<Number>("maxBytes")!!.toLong(),
            filterListsDirectory = call.argument<String>("filterListsDirectory"),
            filterResourcesFile = call.argument<String>("filterResourcesFile")!!,
        )
    }
}
