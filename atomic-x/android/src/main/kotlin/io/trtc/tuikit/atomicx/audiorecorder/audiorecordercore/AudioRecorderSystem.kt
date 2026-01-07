package io.trtc.tuikit.atomicx.audiorecorder.audiorecordercore

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import android.widget.Toast

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.IOException
import io.trtc.tuikit.atomicx.R
import io.trtc.tuikit.atomicx.audiorecorder.ResultCode
import io.trtc.tuikit.atomicx.audiorecorder.audiorecorderimpl.RecorderListener

class AudioRecorderSystem(private val context: Context) : AudioRecorderInternalInterface {
    private fun Context.isAppDebuggable(): Boolean {
        return (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }
    private var mediaRecorder: MediaRecorder? = null
    private var listener: RecorderListener? = null
    private var filePath: String? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    private var recordStartTime: Long = 0
    private var isEnableAIDeNoise: Boolean = false
    private var minRecordDurationMs: Int = 1000
    private var maxRecordDurationMs: Int = 60000

    private var job: Job? = null

    override fun startRecord(filePath: String?, minRecordDurationMs: Int, maxRecordDurationMs: Int) {
        if (isEnableAIDeNoise && context.isAppDebuggable()) {
            Toast.makeText(context, R.string.audio_authorization_prompter, Toast.LENGTH_SHORT).show()
        }

        this.filePath = filePath
        this.minRecordDurationMs = minRecordDurationMs
        this.maxRecordDurationMs = maxRecordDurationMs
        try {
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }
            mediaRecorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(128000)
                setAudioSamplingRate(44100)
                setOutputFile(filePath)

                try {
                    prepare()
                    start()
                    listener?.onRecordTime(0)

                } catch (e: IOException) {
                    listener?.onCompleted(ResultCode.ERROR_RECORD_INNER_FAIL, " ")
                    reset()
                    release()
                    mediaRecorder = null
                }
            }
        } catch (e: Exception) {
            listener?.onCompleted(ResultCode.ERROR_RECORD_INNER_FAIL, " ")
            releaseResources()
        }
        createJob()
    }

    override fun setListener(listener: RecorderListener?) {
        this.listener = listener
    }

    override fun stopRecord() {
        job?.cancel()
        job = null
        try {
            mediaRecorder?.apply {
                stop()
                reset()
                release()
            }
            mediaRecorder = null

            val recordTime = System.currentTimeMillis() - recordStartTime;
            Log.i(TAG, "record time : " + recordTime + " min record duration: "
                    + minRecordDurationMs + " max record duration: " + maxRecordDurationMs)
            if (recordTime < minRecordDurationMs) {
                listener?.onCompleted(ResultCode.ERROR_LESS_THAN_MIN_DURATION, filePath)
            } else if (recordTime >= maxRecordDurationMs) {
                listener?.onCompleted(ResultCode.SUCCESS_EXCEED_MAX_DURATION, filePath)
            } else {
                listener?.onCompleted(ResultCode.SUCCESS, filePath)
            }
        } catch (e: Exception) {
            listener?.onCompleted(ResultCode.ERROR_RECORD_INNER_FAIL, "")
            releaseResources()
        }
    }

    override fun enableAIDeNoise(enable: Boolean) {
        Log.e(TAG, "The system's audio recording does not support setting AI de noise")
        isEnableAIDeNoise = enable
    }

    private fun createJob() {
        job?.cancel()
        job = coroutineScope.launch {
            recordStartTime = System.currentTimeMillis();
            while (mediaRecorder != null) {
                try {
                    val amplitude = mediaRecorder?.maxAmplitude ?: 0
                    val db = if (amplitude > 0) {
                        20 * Math.log10(amplitude.toDouble()).toInt().coerceAtLeast(-90)
                    } else {
                        -90
                    }
                    val recordTime = System.currentTimeMillis() - recordStartTime;

                    if (recordTime >= maxRecordDurationMs) {
                        stopRecord()
                    }

                    listener?.onAmplitudeChanged(db)
                    listener?.onRecordTime(recordTime.toInt())
                } catch (e: Exception) {
                }
                delay(AMPLITUDE_UPDATE_INTERVAL)
            }
        }
    }

    private fun releaseResources() {
        try {
            job?.cancel()
            job = null

            mediaRecorder?.apply {
                reset()
                release()
            }
            mediaRecorder = null
        } catch (e: Exception) {
        }
    }

    companion object {
        private const val AMPLITUDE_UPDATE_INTERVAL = 100L
        private var TAG: String? = "AudioRecorderSystem"
    }
} 