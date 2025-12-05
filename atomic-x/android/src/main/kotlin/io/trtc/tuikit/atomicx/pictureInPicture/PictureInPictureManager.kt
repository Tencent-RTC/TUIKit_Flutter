package io.trtc.tuikit.atomicx

import android.app.Activity
import android.app.Application
import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.Rational
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PictureInPictureManager(
    private val pluginBinding: FlutterPlugin.FlutterPluginBinding,
) : EventChannel.StreamHandler, MethodCallHandler {

    companion object {
        private const val TAG = "PictureInPictureManager"
        private const val STATE_ENTER_PIP = "state_enter_pip"
        private const val STATE_LEAVE_PIP = "state_leave_pip"
    }

    var activity: Activity? = null
    var application: Application? = null
    private var channel : MethodChannel
    private var enablePictureInPicture = false
    private var eventSink: EventChannel.EventSink? = null

    private val activityCallback = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityPaused(@NonNull activity: Activity) {
            Log.i(TAG, "onActivityPaused: $activity")
            if (this@PictureInPictureManager.activity == activity) {
                enterPictureInPicture(activity)
            }
        }

        override fun onActivityStopped(activity: Activity) {}

        override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

        override fun onActivityDestroyed(activity: Activity) {}

        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

        override fun onActivityStarted(activity: Activity) {}

        override fun onActivityResumed(@NonNull activity: Activity) {
            Log.i(TAG, "onActivityResumed: $activity")
            if (this@PictureInPictureManager.activity == activity) {
                onLeavePip()
            }
        }
    }

    init {
        channel = MethodChannel(pluginBinding.binaryMessenger, "atomic_x/pip")
        channel.setMethodCallHandler(this)

        val eventChannel = EventChannel(pluginBinding.binaryMessenger, "atomic_x_pip_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enablePictureInPicture" -> {
                enablePictureInPicture(call, result)
            }
            "closePictureInPicture" -> {
                closePictureInPicture(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    fun updateActivity(activity: Activity?) {
        this.activity = activity
    }

    fun attachToActivity(activity: Activity?) {
        this.activity = activity
        if (activity != null) {
            application = activity.application
            application?.registerActivityLifecycleCallbacks(activityCallback)
        }
    }

    fun detachFromActivity() {
        activity = null
        application?.unregisterActivityLifecycleCallbacks(activityCallback)
    }

    fun dispose() {
        activity = null
        application?.unregisterActivityLifecycleCallbacks(activityCallback)
        application = null
        channel.setMethodCallHandler(null)
    }

    private fun enablePictureInPicture(call: MethodCall, result: Result) {
        val activity = activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        val paramsMap = call.argument<Map<String, Any>>("params")
        if (paramsMap != null) {
            val enableParam = paramsMap["enable"] as? Boolean
            if (enableParam != null) {
                val success = enablePIP(activity, enableParam)
                result.success(success)
            } else {
                result.error("INVALID_PARAMS", "Enable parameter is required", null)
            }
        } else {
            result.error("INVALID_PARAMS", "Params parameter is required", null)
        }
    }

    private fun closePictureInPicture(result: Result) {
        val activity = activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        try {
            activity.moveTaskToBack(false)
            
            onLeavePip()
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to close picture in picture : ${e.message}")
            result.error("CLOSE_FAILED", "Failed to close picture in picture", null)
        }
    }

    private fun enablePIP(activity: Activity, enable: Boolean): Boolean {
        Log.i(TAG, "enablePictureInPicture, enable: $enable")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            activity.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
            enablePictureInPicture = enable
            return true
        }
        return false
    }

    private fun enterPictureInPicture(activity: Activity) {
        if (!enablePictureInPicture) {
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val aspectRatio = Rational(9, 16)
            val params = PictureInPictureParams.Builder().setAspectRatio(aspectRatio).build()
            try {
                val ok = activity.enterPictureInPictureMode(params)
                onEnterPip(ok)
            } catch (e: Exception) {
                Log.e(TAG, e.toString())
            }
        }
    }

    private fun onLeavePip() {
        Log.i(TAG, "onLeavePip")
        eventSink?.success(STATE_LEAVE_PIP)
    }

    private fun onEnterPip(success: Boolean) {
        Log.i(TAG, "onEnterPip: $success")
        if (success) {
            eventSink?.success(STATE_ENTER_PIP)
        }
    }

}