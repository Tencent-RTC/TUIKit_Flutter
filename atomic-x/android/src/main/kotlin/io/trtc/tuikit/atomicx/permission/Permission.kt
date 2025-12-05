package io.trtc.tuikit.atomicx.permission

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Manages MethodChannel communication and delegates to PermissionHandler.
 */
class Permission(
    private val pluginBinding: FlutterPlugin.FlutterPluginBinding,
) : ActivityAware {

    companion object {
        private const val CHANNEL_NAME = "atomic_x/permission"
    }

    private val methodChannel: MethodChannel = MethodChannel(
        pluginBinding.binaryMessenger,
        CHANNEL_NAME,
    )
    private val handler: PermissionHandler = PermissionHandler(pluginBinding)
    private var activityBinding: ActivityPluginBinding? = null

    init {
        methodChannel.setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermissions" -> {
                call.argument<List<String>>("permissions")?.takeIf { it.isNotEmpty() }?.let {
                    handler.requestPermissions(it, result)
                } ?: result.error("INVALID_ARGUMENT", "Permissions are required", null)
            }
            "openAppSettings" -> result.success(handler.openAppSettings())
            "getPermissionStatus" -> {
                call.argument<String>("permission")?.let {
                    result.success(handler.getPermissionStatus(it))
                } ?: result.error("INVALID_ARGUMENT", "Permission is required", null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun attachActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        handler.setActivity(binding.activity)
        binding.addRequestPermissionsResultListener(handler)
    }

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(handler)
        handler.setActivity(null)
        activityBinding = null
    }

    fun dispose() {
        detachActivity()
        methodChannel.setMethodCallHandler(null)
        handler.dispose()
    }
}
