package com.tencent.cloud.tuikit.flutter.tuicallkit
import android.content.Context
import com.tencent.cloud.tuikit.flutter.tuicallkit.view.NotificationView
import com.tencent.cloud.tuikit.flutter.tuicallkit.utils.CallingVibrator
import com.trtc.tuikit.common.foregroundservice.AudioForegroundService
import com.trtc.tuikit.common.foregroundservice.VideoForegroundService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/** TencentCallsUikitPlugin */
class TencentCallsUikitPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var appContext: Context
  private lateinit var callingVibrator: CallingVibrator

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tencent_calls_uikit")
    channel.setMethodCallHandler(this)
    appContext = flutterPluginBinding.applicationContext
    callingVibrator = CallingVibrator(appContext)
    Companion.channel = channel
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "openNotificationView" -> openNotificationView(call, result)
      "closeNotificationView" -> closeNotificationView(call, result)
      "startVibration" -> startVibration(call, result)
      "stopVibration" -> stopVibration(call, result)
      "startForegroundService" -> startForegroundService(call, result)
      "stopForegroundService" -> stopForegroundService(call, result)
      else -> result.notImplemented()
    }
  }

  private fun openNotificationView(call: MethodCall, result: MethodChannel.Result) {
    val args = call.arguments as? Map<*, *>
    val name = args?.get("name") as? String ?: ""
    val avatar = args?.get("avatar") as? String ?: ""
    val mediaTypeRaw = args?.get("mediaType")
    val mediaType = NotificationView.Companion.MediaType.entries.getOrNull(mediaTypeRaw as Int) ?: NotificationView.Companion.MediaType.Audio
    NotificationView.getInstance(appContext).showNotification(name, avatar, mediaType)
    result.success(null)
  }

  private fun closeNotificationView(call: MethodCall, result: MethodChannel.Result) {
    NotificationView.getInstance(appContext).cancelNotification()
    result.success(null)
  }

  private fun startVibration(call: MethodCall, result: MethodChannel.Result) {
    callingVibrator.startVibration()
    result.success(null)
  }

  private fun stopVibration(call: MethodCall, result: MethodChannel.Result) {
    callingVibrator.stopVibration()
    result.success(null)
  }

  private fun startForegroundService(call: MethodCall, result: MethodChannel.Result) {
    val args = call.arguments as? Map<*, *>
    val isVideo = args?.get("isVideo") as? Boolean ?: false
    if (isVideo) {
      VideoForegroundService.start(appContext, "", "", 0)
    } else {
      AudioForegroundService.start(appContext, "", "", 0)
    }
    result.success(null)
  }

  private fun stopForegroundService(call: MethodCall, result: MethodChannel.Result) {
    VideoForegroundService.stop(appContext)
    AudioForegroundService.stop(appContext)
    result.success(null)
  }

  companion object {
    @Volatile internal var channel: MethodChannel? = null

    fun emit(event: String, args: Map<String, Any?>? = null) {
      try {
        channel?.invokeMethod(event, args)
      } catch (_: Throwable) {
        // swallow if channel not ready
      }
    }
  }
}
