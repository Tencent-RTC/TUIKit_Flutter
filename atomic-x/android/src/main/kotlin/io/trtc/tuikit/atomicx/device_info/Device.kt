package io.trtc.tuikit.atomicx.device_info

import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Device(binding: FlutterPlugin.FlutterPluginBinding) {
    private val context = binding.applicationContext
    private var channel : MethodChannel = MethodChannel(binding.binaryMessenger, "atomic_x/device_info")

    init {
        channel.setMethodCallHandler(::handleMethodCall)
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceInfo" -> getDeviceInfo(result)
            else -> result.notImplemented()
        }
    }

    private fun getDeviceInfo(result: MethodChannel.Result) {
        try {
            val deviceInfo = mapOf<String, Any>(
                "sdkInt" to Build.VERSION.SDK_INT,
                "version" to Build.VERSION.RELEASE,
                "model" to Build.MODEL,
                "manufacturer" to Build.MANUFACTURER,
            )
            result.success(deviceInfo)
        } catch (e: Exception) {
            result.error("DEVICE_INFO_ERROR", "Failed to get device info", e.message ?: "Unknown error")
        }
    }


    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}