package io.trtc.tuikit.atomicxcore

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.trtc.tuikit.atomicxcore.view.AtomicVideoViewFactory

/** AtomicEnginePlugin */
class AtomicEnginePlugin: FlutterPlugin, MethodCallHandler {
  companion object {
    init {
      System.loadLibrary("ImSDK")
      System.loadLibrary("liteavsdk")
      System.loadLibrary("atomicengine")
    }
  }

  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "atomic_engine")
    channel.setMethodCallHandler(this)

    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      AtomicVideoViewFactory.VIEW_TYPE,
      AtomicVideoViewFactory(flutterPluginBinding.binaryMessenger),
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
