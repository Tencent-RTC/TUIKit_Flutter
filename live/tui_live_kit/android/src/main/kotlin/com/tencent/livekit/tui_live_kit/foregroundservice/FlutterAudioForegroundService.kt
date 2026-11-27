package com.tencent.livekit.tui_live_kit.foregroundservice

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

private const val TAG = "AudioForegroundService"
private const val NOTIFICATION_ID = 1001
private const val CHANNEL_ID = "flutter_livekit_audio_foreground_service"

private const val EXTRA_TITLE = "title"
private const val EXTRA_DESCRIPTION = "description"

enum class ServiceState {
    IDLE,
    STARTING,
    RUNNING,
    STOPPING,
}

/**
 * 观众上麦开麦期间的前台服务，对应 Android `tuilivekit` 的 `AudioForegroundService`。
 *
 * `foregroundServiceType` 为 microphone：Android 14 起缺少该类型会直接拒绝启动，
 * 且启动前必须已获得 `RECORD_AUDIO`，否则系统同样拒绝。
 */
class FlutterAudioForegroundService : Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE)
        val description = intent?.getStringExtra(EXTRA_DESCRIPTION)

        try {
            val notification = createNotification(title, description)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (error: RuntimeException) {
            Log.e(TAG, "Unable to promote foreground service", error)
            ServiceLauncher.updateState(ServiceState.IDLE)
            stopSelf()
            return START_NOT_STICKY
        }

        if (ServiceLauncher.state == ServiceState.STOPPING) {
            stopSelf()
            ServiceLauncher.updateState(ServiceState.IDLE)
        } else {
            ServiceLauncher.updateState(ServiceState.RUNNING)
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        stopSelf()
        ServiceLauncher.updateState(ServiceState.IDLE)
    }

    override fun onDestroy() {
        super.onDestroy()
        (getSystemService(NOTIFICATION_SERVICE) as? NotificationManager)?.cancel(NOTIFICATION_ID)
        // 旧实例销毁时可能已有新的启动在排队，不能把新的 STARTING 复位。
        if (ServiceLauncher.state == ServiceState.RUNNING) {
            ServiceLauncher.updateState(ServiceState.IDLE)
        }
    }

    private fun createNotification(title: String?, description: String?): Notification {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                applicationInfo.loadLabel(packageManager).toString(),
                NotificationManager.IMPORTANCE_LOW,
            )
            manager.createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .setContentTitle(title)
            .setContentText(description)
            .build()
    }
}

/**
 * 启停编排：与 Android 侧 `ServiceLauncher` 的状态机一致。
 *
 * 串行到主线程，重复 start 幂等；STARTING 期间收到 stop 延迟到服务真正启动后由服务自行结束，
 * 避免 `startForegroundService` 后 5 秒未调用 `startForeground` 的异常。
 */
internal object ServiceLauncher {
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    var state: ServiceState = ServiceState.IDLE
        private set

    fun updateState(newState: ServiceState) {
        state = newState
    }

    fun start(context: Context, title: String?, description: String?, callback: (Boolean) -> Unit) {
        val appContext = context.applicationContext
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mainHandler.post { startInternal(appContext, title, description, callback) }
            return
        }
        startInternal(appContext, title, description, callback)
    }

    fun stop(context: Context) {
        val appContext = context.applicationContext
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mainHandler.post { stopInternal(appContext) }
            return
        }
        stopInternal(appContext)
    }

    private fun startInternal(
        context: Context,
        title: String?,
        description: String?,
        callback: (Boolean) -> Unit,
    ) {
        if (state == ServiceState.STARTING || state == ServiceState.RUNNING) {
            Log.i(TAG, "start foreground service, service is already active")
            callback(true)
            return
        }
        if (state == ServiceState.STOPPING) {
            state = ServiceState.STARTING
            Log.i(TAG, "start foreground service, changing STOPPING to STARTING")
            callback(true)
            return
        }

        state = ServiceState.STARTING
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            state = ServiceState.IDLE
            Log.e(TAG, "start failed: RECORD_AUDIO denied")
            callback(false)
            return
        }

        val intent = Intent(context, FlutterAudioForegroundService::class.java).apply {
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_DESCRIPTION, description)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            callback(true)
        } catch (error: RuntimeException) {
            state = ServiceState.IDLE
            Log.e(TAG, "Unable to start foreground service", error)
            callback(false)
        }
    }

    private fun stopInternal(context: Context) {
        when (state) {
            ServiceState.RUNNING -> {
                context.stopService(Intent(context, FlutterAudioForegroundService::class.java))
                state = ServiceState.IDLE
            }

            ServiceState.STARTING -> state = ServiceState.STOPPING
            else -> Unit
        }
    }
}
