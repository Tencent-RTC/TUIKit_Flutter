package com.tencent.cloud.tuikit.flutter.tuicallkit.utils

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

class CallingVibrator(context: Context) {

    private val appContext: Context = context.applicationContext
    private val vibrator: Vibrator

    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null
    private val vibrationRunnable = Runnable { triggerVibration() }

    init {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = appContext.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    fun startVibration() {
        stopVibration()

        handlerThread = HandlerThread("CallingVibrator").apply {
            start()
            handler = Handler(looper)
            handler?.post(vibrationRunnable)
        }
    }

    private fun triggerVibration() {
        if (!vibrator.hasVibrator()) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE)
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(500)
        }

        handler?.postDelayed(vibrationRunnable, 1500)
    }

    fun stopVibration() {
        vibrator.cancel()

        handler?.removeCallbacks(vibrationRunnable)

        handlerThread?.quitSafely()
        handlerThread = null
        handler = null
    }
}