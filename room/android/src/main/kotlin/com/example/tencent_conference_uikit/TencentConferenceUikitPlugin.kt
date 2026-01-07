package com.example.tencent_conference_uikit

import android.app.Activity
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.util.Log
import android.view.Window
import android.view.WindowManager
import com.trtc.tuikit.common.foregroundservice.AudioForegroundService
import com.trtc.tuikit.common.foregroundservice.MediaForegroundService
import com.trtc.tuikit.common.foregroundservice.VideoForegroundService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** TencentConferenceUikitPlugin */
class TencentConferenceUikitPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null

    companion object {
        private const val TAG = "RoomUikitPlugin"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tencent_conference_uikit")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "enableWakeLock" -> {
                enableWakeLock(call, result)
            }
            "startForegroundService" -> {
                startForegroundService(call, result)
            }
            "stopForegroundService" -> {
                stopForegroundService(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun enableWakeLock(call: MethodCall, result: Result) {
        val enable = call.argument<Boolean>("enable") ?: false
        try {
            activity?.runOnUiThread {
                val window: Window? = activity?.window
                if (enable) {
                    window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("enableWakeLock error", "Failed to set screen keep-on", e.message)
        }
    }

    private fun startForegroundService(call: MethodCall, result: Result) {
        val serviceType = call.argument<Int>("serviceType") ?: 0
        var title = call.argument<String>("title") ?: ""
        val description = call.argument<String>("description") ?: ""

        if (title.isEmpty()) {
            title = getApplicationName()
        }

        val ctx = context
        if (ctx == null) {
            result.error("CONTEXT_ERROR", "Context is null", null)
            return
        }

        try {
            when (serviceType) {
                1 -> AudioForegroundService.start(ctx, title, description, 0)
                2 -> MediaForegroundService.start(ctx, title, description, 0)
                else -> VideoForegroundService.start(ctx, title, description, 0)
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "startForegroundService error: ${e.message}")
            result.error("SERVICE_ERROR", "Failed to start foreground service", e.message)
        }
    }

    private fun stopForegroundService(call: MethodCall, result: Result) {
        val serviceType = call.argument<Int>("serviceType") ?: 0

        val ctx = context
        if (ctx == null) {
            result.error("CONTEXT_ERROR", "Context is null", null)
            return
        }

        try {
            when (serviceType) {
                1 -> AudioForegroundService.stop(ctx)
                2 -> MediaForegroundService.stop(ctx)
                else -> VideoForegroundService.stop(ctx)
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "stopForegroundService error: ${e.message}")
            result.error("SERVICE_ERROR", "Failed to stop foreground service", e.message)
        }
    }

    private fun getApplicationName(): String {
        val ctx = context ?: return ""
        return try {
            val packageManager: PackageManager = ctx.packageManager
            val applicationInfo: ApplicationInfo = packageManager.getApplicationInfo(ctx.packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            Log.e(TAG, "getApplicationName error: ${e.message}")
            ""
        }
    }
}
