package io.trtc.tuikit.atomicx.audiorecorder.audiorecorderimpl

import android.Manifest
import android.os.Looper
import android.util.Log
import com.tencent.qcloud.tuicore.permission.PermissionCallback
import com.tencent.qcloud.tuicore.permission.PermissionRequester
import io.trtc.tuikit.atomicx.audiorecorder.AudioRecorderListener
import io.trtc.tuikit.atomicx.audiorecorder.ResultCode
import io.trtc.tuikit.atomicx.audiorecorder.audiorecordercore.AudioRecorderInternalInterface
import io.trtc.tuikit.atomicx.audiorecorder.audiorecordercore.AudioRecorderSystem
import io.trtc.tuikit.atomicx.audiorecorder.audiorecordercore.AudioRecorderTXUGC
import io.trtc.tuikit.atomicx.basecomponent.utils.ContextProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

interface RecorderListener {
    fun onRecordTime(time: Int)
    fun onAmplitudeChanged(db: Int)
    fun onCompleted(resultCode: ResultCode, path: String?)
}

class AudioRecorderImpl() {
    companion object {
        private var TAG: String? = "AudioRecorderImpl"
    }

    private var recorder: AudioRecorderInternalInterface? = null
    private val mainCoroutineScope = CoroutineScope(Dispatchers.Main)
    private val _currentPower = MutableStateFlow(0)
    private val _recordTimeMs = MutableStateFlow(0)
    internal val currentPowerFlow = _currentPower.asStateFlow()
    internal val recordTimeMsFlow = _recordTimeMs.asStateFlow()
    private var isRecording = false
    private var isCancelRecord = false
    private var audioFilePath: String? = null

    private var enableAIDeNoise: Boolean = false
    private var listener: AudioRecorderListener? = null

    init {
        val context = ContextProvider.appContext
        try {
            recorder = AudioRecorderTXUGC(context)
            (recorder as AudioRecorderTXUGC).init()
        } catch (e: Exception) {
            Log.i("AudioRecorderFactory", "can not create ugc audio recorder." + e.message)
            recorder = AudioRecorderSystem(context)
        }
        recorder?.setListener(RecorderListenerImpl())
    }

    private fun setCurrentPower(value: Int) {
        _currentPower.value = value
    }

    private fun setCurrentTime(value: Int) {
        _recordTimeMs.value = value
    }

    fun startRecord(
        filepath: String?,
        enableAIDeNoise: Boolean,
        minRecordDurationMs: Int,
        maxRecordDurationMs: Int,
        listener: AudioRecorderListener
    ) {
        this.listener = listener
        Log.i(TAG, "start record filepath:$filepath")
        PermissionRequester.newInstance(Manifest.permission.RECORD_AUDIO).callback(object : PermissionCallback() {
            override fun onGranted() {
                runOnMainThread { startRecordInternal(filepath, enableAIDeNoise, minRecordDurationMs, maxRecordDurationMs) }
            }

            override fun onDenied() {
                Log.i(TAG, "request record audio permission refuse")
                onRecordingComplete(ResultCode.ERROR_RECORD_PERMISSION_DENIED, "", 0)
            }
        }).request()
    }

    private fun startRecordInternal(
        filepath: String?,
        enableAIDeNoise: Boolean,
        minRecordDurationMs: Int,
        maxRecordDurationMs: Int
    ) {
        if (isRecording) {
            onRecordingComplete(ResultCode.ERROR_RECORDING, "", 0)
            return
        }
        isRecording = true
        isCancelRecord = false

        audioFilePath = filepath
        if (audioFilePath.isNullOrEmpty()) {
            audioFilePath = getFilePath()
        }

        if (audioFilePath.isNullOrEmpty()) {
            onRecordingComplete(ResultCode.ERROR_STORAGE_UNAVAILABLE, audioFilePath, 0)
            return
        }

        recorder?.enableAIDeNoise(enableAIDeNoise)
        recorder?.startRecord(filePath = audioFilePath, minRecordDurationMs, maxRecordDurationMs)
    }

    fun stopRecord() {
        Log.i(TAG, "stop record")
        runOnMainThread {
            if (isRecording) {
                recorder?.stopRecord()
                isRecording = false
            }
        }
    }

    fun cancelRecord() {
        Log.i(TAG, "cancel record")
        runOnMainThread {
            if (isRecording) {
                isCancelRecord = true
                recorder?.stopRecord()
                onRecordingComplete(ResultCode.ERROR_CANCEL, audioFilePath, 0)
            }
        }
    }

    private fun getFilePath(): String? {
        val context = ContextProvider.appContext
        val audioDir = File(context?.filesDir, "audio")
        val dirExists = audioDir.exists()
        if (!dirExists) {
            val dirCreated = audioDir.mkdirs()
            if (!dirCreated) {
                return null
            }
        }

        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val outputFile = File(audioDir, "audio_$timestamp.m4a")
        return outputFile.absolutePath
    }

    private fun onRecordingComplete(resultCode: ResultCode, recordFilePath: String?, recordDuration: Int) {
        runOnMainThread {
            this.listener?.onCompleted(resultCode, recordFilePath, recordDuration)
            this.listener = null
        }
    }

    private fun runOnMainThread(action: () -> Unit?) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action()
        } else {
            mainCoroutineScope.launch {
                action()
            }
        }
    }

    inner class RecorderListenerImpl : RecorderListener {
        private var recordTimeMs: Int = 0

        override fun onRecordTime(time: Int) {
            Log.i(TAG, "onRecordProcess time:$time")
            this@AudioRecorderImpl.runOnMainThread {
                recordTimeMs = time
                this@AudioRecorderImpl.setCurrentTime(recordTimeMs)
            }
        }

        override fun onAmplitudeChanged(db: Int) {
            this@AudioRecorderImpl.runOnMainThread {
                this@AudioRecorderImpl.setCurrentPower(db)
            }
        }

        override fun onCompleted(resultCode: ResultCode, path: String?) {
            if (resultCode != ResultCode.SUCCESS) {
                Log.e(TAG, "on record completed. resultCode:$resultCode")
            }
            Log.i(TAG, "on record completed. path:$path")
            this@AudioRecorderImpl.runOnMainThread {
                isRecording = false
                if (!isCancelRecord) {
                    this@AudioRecorderImpl.onRecordingComplete(resultCode, path, recordTimeMs)
                }
            }
        }
    }
}