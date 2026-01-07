package io.trtc.tuikit.atomicx.audiorecorder

import android.app.Activity
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

class AudioRecorderHandler(
    private val activity: Activity,
    private val methodChannel: MethodChannel,
    private val eventChannel: EventChannel
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val TAG = "AudioRecorderHandler"
    }

    private var eventSink: EventChannel.EventSink? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var powerLevelJob: Job? = null
    private var timeJob: Job? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecord" -> startRecord(call, result)
            "stopRecord" -> stopRecord(result)
            "cancelRecord" -> cancelRecord(result)
            else -> result.notImplemented()
        }
    }

    private fun startRecord(call: MethodCall, result: MethodChannel.Result) {
        try {
            val filepath = call.argument<String?>("filepath")
            val enableAIDeNoise = call.argument<Boolean>("enableAIDeNoise") ?: false
            val minDurationMs = call.argument<Int>("minDurationMs") ?: 1000
            val maxDurationMs = call.argument<Int>("maxDurationMs") ?: 60000

            // Start listening to power level and time updates
            startEventListeners()

            // Start recording with listener
            AudioRecorder.startRecord(
                filepath = filepath,
                enableAIDeNoise = enableAIDeNoise,
                minDurationMs = minDurationMs,
                maxDurationMs = maxDurationMs,
                listener = object : AudioRecorderListener {
                    override fun onCompleted(
                        resultCode: ResultCode,
                        path: String?,
                        durationMs: Int
                    ) {
                        stopEventListeners()
                        
                        Handler(Looper.getMainLooper()).post {
                            val resultMap = mapOf(
                                "resultCode" to resultCode.code,
                                "filePath" to path,
                                "durationMs" to durationMs
                            )
                            result.success(resultMap)
                        }
                    }
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "startRecord error", e)
            stopEventListeners()
            result.error("RECORD_ERROR", e.message, null)
        }
    }

    private fun stopRecord(result: MethodChannel.Result) {
        try {
            AudioRecorder.stopRecord()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "stopRecord error", e)
            result.error("STOP_ERROR", e.message, null)
        }
    }

    private fun cancelRecord(result: MethodChannel.Result) {
        try {
            AudioRecorder.cancelRecord()
            stopEventListeners()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "cancelRecord error", e)
            result.error("CANCEL_ERROR", e.message, null)
        }
    }

    private fun startEventListeners() {
        powerLevelJob = coroutineScope.launch {
            AudioRecorder.currentPower.collectLatest { powerLevel ->
                eventSink?.success(
                    mapOf(
                        "type" to "powerLevel",
                        "powerLevel" to powerLevel
                    )
                )
            }
        }

        timeJob = coroutineScope.launch {
            AudioRecorder.currentTimeMs.collectLatest { timeMs ->
                eventSink?.success(
                    mapOf(
                        "type" to "recordTime",
                        "timeMs" to timeMs
                    )
                )
            }
        }
    }

    private fun stopEventListeners() {
        powerLevelJob?.cancel()
        timeJob?.cancel()
        powerLevelJob = null
        timeJob = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopEventListeners()
    }

    fun dispose() {
        stopEventListeners()
        coroutineScope.cancel()
        eventSink = null
    }
}
