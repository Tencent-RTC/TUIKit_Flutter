package com.tencent.livekit.tui_live_kit

import android.app.Activity
import android.content.Context
import android.view.WindowManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import com.tencent.livekit.tui_live_kit.foregroundservice.ServiceLauncher
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `tui_live_kit` 的 Android 承载层。
 *
 * 只封装 AtomicXCore 未覆盖、且当前产品范围实际需要的系统能力：
 * 系统热状态、网络类型与观众上麦期间的麦克风前台服务，前两者分别对应主播端
 *「直播状态 → 设备状态」的温度行与网络行。
 */
class TUILiveKitPlugin : FlutterPlugin, ActivityAware {
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        applyScreenAwake()
        advancedBeauty?.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        restoreScreenAwake()
        activity = null
        advancedBeauty?.activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
    private var activity: Activity? = null
    private var screenAwakeChannel: MethodChannel? = null
    private val screenAwakeOwners = mutableSetOf<String>()
    private var previousKeepScreenOn: Boolean? = null

    private fun applyScreenAwake() {
        val window = activity?.window ?: return
        if (screenAwakeOwners.isEmpty()) {
            restoreScreenAwake()
            return
        }
        if (previousKeepScreenOn == null) {
            previousKeepScreenOn = window.attributes.flags and WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON != 0
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun restoreScreenAwake() {
        val previous = previousKeepScreenOn ?: return
        if (previous) activity?.window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        else activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        previousKeepScreenOn = null
    }

    private var advancedBeauty: AdvancedBeautyPlugin? = null
    private var thermalStateChannel: EventChannel? = null
    private var thermalStateHandler: ThermalStateStreamHandler? = null
    private var networkTypeChannel: EventChannel? = null
    private var networkTypeHandler: NetworkTypeStreamHandler? = null
    private var audioForegroundServiceChannel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        advancedBeauty = AdvancedBeautyPlugin(binding.applicationContext, binding.binaryMessenger)
        val thermalHandler = ThermalStateStreamHandler(binding.applicationContext)
        val thermalChannel = EventChannel(binding.binaryMessenger, THERMAL_STATE_CHANNEL_NAME)
        thermalChannel.setStreamHandler(thermalHandler)
        thermalStateChannel = thermalChannel
        thermalStateHandler = thermalHandler

        val networkHandler = NetworkTypeStreamHandler(binding.applicationContext)
        val networkChannel = EventChannel(binding.binaryMessenger, NETWORK_TYPE_CHANNEL_NAME)
        networkChannel.setStreamHandler(networkHandler)
        networkTypeChannel = networkChannel
        networkTypeHandler = networkHandler

        val audioChannel = MethodChannel(binding.binaryMessenger, AUDIO_FOREGROUND_SERVICE_CHANNEL_NAME)
        audioChannel.setMethodCallHandler { call, result ->
            handleAudioForegroundServiceCall(call, result, binding.applicationContext)
        }
        audioForegroundServiceChannel = audioChannel
        screenAwakeChannel = MethodChannel(binding.binaryMessenger, "tui_live_kit/screen_awake").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "setEnabled") {
                    result.notImplemented()
                } else {
                    val owner = call.argument<String>("owner")
                    val enabled = call.argument<Boolean>("enabled")
                    if (owner == null || enabled == null) {
                        result.error("invalid_arguments", null, null)
                    } else {
                        if (enabled) screenAwakeOwners.add(owner) else screenAwakeOwners.remove(owner)
                        applyScreenAwake()
                        result.success(null)
                    }
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        screenAwakeChannel?.setMethodCallHandler(null)
        screenAwakeChannel = null
        screenAwakeOwners.clear()
        restoreScreenAwake()
        advancedBeauty?.dispose()
        advancedBeauty = null
        thermalStateChannel?.setStreamHandler(null)
        thermalStateChannel = null
        thermalStateHandler?.dispose()
        thermalStateHandler = null

        networkTypeChannel?.setStreamHandler(null)
        networkTypeChannel = null
        networkTypeHandler?.dispose()
        networkTypeHandler = null

        audioForegroundServiceChannel?.setMethodCallHandler(null)
        audioForegroundServiceChannel = null
    }

    private fun handleAudioForegroundServiceCall(
        call: MethodCall,
        result: MethodChannel.Result,
        context: Context,
    ) {
        when (call.method) {
            METHOD_START -> ServiceLauncher.start(
                context,
                call.argument(ARG_TITLE),
                call.argument(ARG_DESCRIPTION),
            ) { started -> result.success(started) }

            METHOD_STOP -> {
                ServiceLauncher.stop(context)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private companion object {
        const val THERMAL_STATE_CHANNEL_NAME = "tui_live_kit/thermal_state"
        const val NETWORK_TYPE_CHANNEL_NAME = "tui_live_kit/network_type"
        const val AUDIO_FOREGROUND_SERVICE_CHANNEL_NAME = "tui_live_kit/audio_foreground_service"
        const val METHOD_START = "start"
        const val METHOD_STOP = "stop"
        const val ARG_TITLE = "title"
        const val ARG_DESCRIPTION = "description"
    }
}

/**
 * 用 `ConnectivityManager` 的网络回调向 Dart 推送归一化的网络类型。
 *
 * `getNetworkCapabilities` 与 `registerNetworkCallback` 需要 API 23；
 * 低版本只能使用已废弃的 `getActiveNetworkInfo`，这里不再使用，
 * 统一上报 [LEVEL_UNKNOWN]。需要 `ACCESS_NETWORK_STATE` 权限。
 */
private class NetworkTypeStreamHandler(context: Context) : EventChannel.StreamHandler {
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private var callback: ConnectivityManager.NetworkCallback? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null) {
            return
        }
        val manager = connectivityManager
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || manager == null) {
            events.success(LEVEL_UNKNOWN)
            return
        }

        events.success(currentNetworkType(manager))

        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onCapabilitiesChanged(
                network: Network, networkCapabilities: NetworkCapabilities
            ) {
                // 回调在系统线程，EventSink 必须在主线程使用。
                mainHandler.post { events.success(normalize(networkCapabilities)) }
            }

            override fun onLost(network: Network) {
                mainHandler.post { events.success(currentNetworkType(manager)) }
            }
        }
        manager.registerNetworkCallback(NetworkRequest.Builder().build(), networkCallback)
        callback = networkCallback
    }

    override fun onCancel(arguments: Any?) {
        removeCallback()
    }

    fun dispose() {
        removeCallback()
    }

    private fun removeCallback() {
        val networkCallback = callback ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // 注销时机可能晚于系统回收，避免未注册异常导致崩溃。
            runCatching { connectivityManager?.unregisterNetworkCallback(networkCallback) }
        }
        callback = null
    }

    private fun currentNetworkType(manager: ConnectivityManager): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return LEVEL_UNKNOWN
        }
        val network = manager.activeNetwork ?: return LEVEL_UNKNOWN
        val capabilities = manager.getNetworkCapabilities(network) ?: return LEVEL_UNKNOWN
        return normalize(capabilities)
    }

    /**
     * 归一化到与 iOS `NetworkKind` 相同的三档。
     *
     * 以太网与其他链路归为未知，与 iOS 只区分 Wi-Fi、蜂窝、未知的语义一致。
     */
    private fun normalize(capabilities: NetworkCapabilities): Int {
        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> LEVEL_WIFI
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> LEVEL_CELLULAR
            else -> LEVEL_UNKNOWN
        }
    }

    private companion object {
        const val LEVEL_UNKNOWN = 0
        const val LEVEL_WIFI = 1
        const val LEVEL_CELLULAR = 2
    }
}

/**
 * 用 `PowerManager` 的热状态回调向 Dart 推送归一化档位。
 *
 * `getCurrentThermalStatus` 与 `addThermalStatusListener` 需要 API 29；
 * 低版本没有等价系统能力，固定上报 [LEVEL_NORMAL]。
 */
private class ThermalStateStreamHandler(context: Context) : EventChannel.StreamHandler {
    private val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private var listener: PowerManager.OnThermalStatusChangedListener? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null) {
            return
        }
        val manager = powerManager
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || manager == null) {
            events.success(LEVEL_NORMAL)
            return
        }

        events.success(normalize(manager.currentThermalStatus))
        val statusListener = PowerManager.OnThermalStatusChangedListener { status ->
            // 系统回调线程不保证是主线程，EventSink 必须在主线程使用。
            mainHandler.post { events.success(normalize(status)) }
        }
        manager.addThermalStatusListener(statusListener)
        listener = statusListener
    }

    override fun onCancel(arguments: Any?) {
        removeListener()
    }

    fun dispose() {
        removeListener()
    }

    private fun removeListener() {
        val statusListener = listener ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            powerManager?.removeThermalStatusListener(statusListener)
        }
        listener = null
    }

    /**
     * 归一化到与 iOS `ProcessInfo.ThermalState` 相同的三档。
     *
     * `NONE` 对应正常；`LIGHT`、`MODERATE` 对应轻微发热；
     * `SEVERE` 及以上对应严重发热。
     */
    private fun normalize(status: Int): Int {
        return when (status) {
            PowerManager.THERMAL_STATUS_NONE -> LEVEL_NORMAL
            PowerManager.THERMAL_STATUS_LIGHT, PowerManager.THERMAL_STATUS_MODERATE -> LEVEL_FAIR
            PowerManager.THERMAL_STATUS_SEVERE, PowerManager.THERMAL_STATUS_CRITICAL, PowerManager.THERMAL_STATUS_EMERGENCY, PowerManager.THERMAL_STATUS_SHUTDOWN -> LEVEL_SERIOUS
            else -> LEVEL_NORMAL
        }
    }

    private companion object {
        const val LEVEL_NORMAL = 0
        const val LEVEL_FAIR = 1
        const val LEVEL_SERIOUS = 2
    }
}
