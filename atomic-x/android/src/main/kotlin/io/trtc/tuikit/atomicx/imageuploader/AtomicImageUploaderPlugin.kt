/*
 * Copyright (c) 2025 Tencent
 * All rights reserved.
 *
 * Author: eddardliu
 */

package io.trtc.tuikit.atomicx.imageuploader

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class AtomicImageUploaderPlugin(
    private val pluginBinding: FlutterPlugin.FlutterPluginBinding
) : MethodCallHandler, EventChannel.StreamHandler, ActivityAware, PluginRegistry.ActivityResultListener {

    companion object {
        private const val METHOD_CHANNEL_NAME = "atomic_x/image_uploader"
        private const val EVENT_CHANNEL_NAME = "atomic_x/image_uploader_events"
        private val REQUEST_CODE_PICK = "SystemImageSourceActivity".hashCode() and 0xFFFF
        const val RESULT_KEY_PATH = "result_path"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var awaitingResult = false

    init {
        methodChannel = MethodChannel(pluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(pluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel?.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "pick" -> handlePick(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handlePick(call: MethodCall, result: Result) {
        val context = activity ?: run {
            sendPickResult(null)
            result.success(null)
            return
        }

        val source = call.argument<String>("source") ?: SystemImageSourceActivity.SOURCE_GALLERY

        val intent = Intent(context, SystemImageSourceActivity::class.java).apply {
            putExtra(SystemImageSourceActivity.EXTRA_SOURCE, source)
        }
        context.startActivityForResult(intent, REQUEST_CODE_PICK)
        awaitingResult = true

        result.success(null)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_PICK || !awaitingResult) return false
        if (data?.hasExtra(RESULT_KEY_PATH) != true) return false
        awaitingResult = false

        val localPath = if (resultCode == Activity.RESULT_OK) {
            data.getStringExtra(RESULT_KEY_PATH)
        } else {
            null
        }
        sendPickResult(localPath)
        return true
    }

    private fun sendPickResult(localPath: String?) {
        val event = mapOf(
            "type" to "pickCompleted",
            "localPath" to localPath
        )
        eventSink?.success(event)
    }

    // MARK: - EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    fun dispose() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        eventSink = null
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }
}
