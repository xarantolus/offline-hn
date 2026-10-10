package io.github.xarantolus.page_capture

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PageCapturePlugin : FlutterPlugin, ActivityAware, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var queue: CaptureQueue
    private lateinit var viewer: ArchiveViewer

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val prefix = binding.flutterAssets.getAssetFilePathBySubpath("assets", "page_capture")
        queue = CaptureQueue.get(context, prefix)
        viewer = ArchiveViewer(context)
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        queue.cancelAll(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        viewer.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        viewer.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        viewer.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        viewer.activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "capture" -> queue.submit(this, CaptureRequest.from(call), result)
            "cancel" -> {
                queue.cancel(this, call.argument<Int>("id")!!)
                result.success(null)
            }
            "openInCustomTab" -> result.success(viewer.openInCustomTab(call.argument<String>("path")!!))
            "openPdf" -> result.success(viewer.openPdf(call.argument<String>("path")!!))
            else -> result.notImplemented()
        }
    }

    private companion object {
        const val CHANNEL = "io.github.xarantolus/page_capture"
    }
}
