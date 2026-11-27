package com.tencent.livekit.tui_live_kit

import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.appcompat.view.ContextThemeWrapper
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import com.tencent.effect.beautykit.TEBeautyKit
import com.tencent.trtc.TRTCCloud
import com.tencent.trtc.TRTCCloudDef
import com.tencent.trtc.TRTCCloudListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

internal class AdvancedBeautyPlugin(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "tui_live_kit/advanced_beauty")
    private val main = Handler(Looper.getMainLooper())
    private val resources = Executors.newSingleThreadExecutor()
    private var licenseGeneration = 0
    private var authorized = false
    private var licensePending = false
    private var licenseResult: MethodChannel.Result? = null
    private var generation = 0
    private var key: String? = null
    private var enabled = false
    private var activation: Activation? = null
    private var dialog: Dialog? = null
    private var presentation: Long? = null
    private var closedPresentation = -1L
    private var disposed = false
    var activity: Activity? = null
        set(value) {
            if (field !== value) dismiss()
            field = value
            if (value == null) stop() else refresh()
        }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setLicense" -> {
                    licenseResult?.success(-2)
                    licenseResult = result
                    authorize(call.argument<String>("url") ?: "", call.argument<String>("key") ?: "")
                }

                "configure" -> {
                    val nextKey = call.argument<String>("key")
                    val nextEnabled = call.argument<Boolean>("enabled") == true
                    if (key != nextKey || !nextEnabled) stop()
                    key = nextKey
                    enabled = nextEnabled
                    generation = call.argument<Int>("generation") ?: 0
                    refresh()
                    result.success(null)
                }

                "status" -> {
                    val status = when {
                        activation?.ready == true -> "ready"
                        enabled && (licensePending || activation != null) -> "pending"
                        else -> "unavailable"
                    }
                    Log.i(
                        "LiveKitBeauty",
                        "status=$status authorized=$authorized enabled=$enabled host=${activity != null}"
                    )
                    result.success(status)
                }

                "show" -> result.success(show(call.argument<Number>("presentation")?.toLong() ?: -1L))
                "dismiss" -> {
                    val id = call.argument<Number>("presentation")?.toLong() ?: -1L
                    closedPresentation = maxOf(closedPresentation, id)
                    if (presentation == id) dismiss()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun authorize(url: String, licenseKey: String) {
        val request = ++licenseGeneration
        licensePending = true
        resources.execute {
            val copied = runCatching {
                TEBeautyKit.setResPath(File(context.filesDir, "livekit_beauty_4_1").absolutePath)
                TEBeautyKit.copyRes(context)
            }.getOrDefault(false)
            main.post {
                if (request != licenseGeneration || disposed) return@post
                if (!copied) {
                    authorized = false
                    licensePending = false
                    licenseResult?.success(-1)
                    licenseResult = null
                    stop()
                    emitReady()
                    return@post
                }
                TEBeautyKit.setTELicense(context, url, licenseKey) { code, _ ->
                    main.post {
                        if (request == licenseGeneration && !disposed) {
                            authorized = code == 0
                            licensePending = false
                            Log.i("LiveKitBeauty", "license result=$code")
                            licenseResult?.success(code)
                            licenseResult = null
                            if (!authorized) stop()
                            channel.invokeMethod("license", mapOf("code" to code))
                            refresh()
                        }
                    }
                }
            }
        }
    }

    private fun refresh() {
        if (!enabled || !authorized || key == null || activity == null || disposed) {
            emitReady()
            return
        }
        if (activation == null) {
            val processor = runCatching { BeautyProcessor(context, key!!) }.getOrNull()
            if (processor != null) {
                val candidate = Activation(processor)
                activation = candidate
                val result = TRTCCloud.sharedInstance(context).setLocalVideoProcessListener(
                    TRTCCloudDef.TRTC_VIDEO_PIXEL_FORMAT_Texture_2D,
                    TRTCCloudDef.TRTC_VIDEO_BUFFER_TYPE_TEXTURE, candidate,
                )
                if (result != 0) stop()
            }
        }
        emitReady()
    }

    private fun emitReady() {
        if (!disposed) channel.invokeMethod(
            "processing", mapOf(
                "generation" to generation, "ready" to (activation?.ready == true),
            )
        )
    }

    private fun stop() {
        dismiss()
        val old = activation ?: return
        activation = null
        old.ready = false
        old.processor.stop()
        TRTCCloud.sharedInstance(context).setLocalVideoProcessListener(
            TRTCCloudDef.TRTC_VIDEO_PIXEL_FORMAT_Texture_2D,
            TRTCCloudDef.TRTC_VIDEO_BUFFER_TYPE_TEXTURE, null,
        )
    }

    private fun show(id: Long): Boolean {
        val host = activity?.takeUnless { it.isFinishing || it.isDestroyed } ?: return false
        val current = activation?.takeIf { it.ready } ?: return false
        if (id <= closedPresentation || dialog != null) return false
        // FlutterActivity's system theme cannot inflate the SDK's Material TabLayout.
        // Keep this requirement local to the SDK UI instead of changing the host app theme.
        val themedContext =
            ContextThemeWrapper(host, com.google.android.material.R.style.Theme_MaterialComponents_DayNight_NoActionBar)
        val panel = runCatching { current.processor.panel(themedContext) }.onFailure {
            Log.e("LiveKitBeauty", "SDK panel creation failed", it)
        }.getOrNull() ?: return false
        val sheet = Dialog(themedContext)
        sheet.requestWindowFeature(Window.FEATURE_NO_TITLE)
        val root = FrameLayout(themedContext)
        val content = FrameLayout(themedContext)
        val fill = SafeAreaFill()
        content.background = fill
        content.addView(panel, FrameLayout.LayoutParams(-1, -2))
        root.addView(content, FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM))
        root.setOnClickListener { sheet.dismiss() }
        content.setOnClickListener { }
        ViewCompat.setOnApplyWindowInsetsListener(root) { _, insets ->
            val safe = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            root.setPadding(safe.left, safe.top, safe.right, 0)
            content.setPadding(0, 0, 0, safe.bottom)
            fill.bottomInset = safe.bottom
            insets
        }
        sheet.setContentView(root)
        sheet.window?.apply {
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            WindowCompat.setDecorFitsSystemWindows(this, false)
            navigationBarColor = 0xFF1F2024.toInt()
            statusBarColor = Color.TRANSPARENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) isNavigationBarContrastEnforced = false
            WindowCompat.getInsetsController(this, root).apply {
                isAppearanceLightStatusBars = false
                isAppearanceLightNavigationBars = false
            }
        }
        presentation = id
        dialog = sheet
        sheet.setOnDismissListener {
            current.processor.save()
            if (dialog === sheet) {
                dialog = null
                presentation = null
                closedPresentation = maxOf(closedPresentation, id)
                if (!disposed) channel.invokeMethod("dismissed", mapOf("presentation" to id))
            }
        }
        sheet.show()
        sheet.window?.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        ViewCompat.requestApplyInsets(root)
        Log.i("LiveKitBeauty", "SDK panel presented")
        return true
    }

    private fun dismiss() {
        dialog?.dismiss()
    }

    fun dispose() {
        stop()
        disposed = true
        licenseGeneration++
        licenseResult?.success(-2)
        licenseResult = null
        resources.shutdown()
        channel.setMethodCallHandler(null)
    }

    private inner class Activation(val processor: BeautyProcessor) : TRTCCloudListener.TRTCVideoFrameListener {
        @Volatile
        var ready = false
        override fun onGLContextCreated() {
            val created = processor.create()
            main.post {
                if (activation === this) {
                    ready = created
                    if (!created) stop()
                    emitReady()
                }
            }
        }

        override fun onProcessVideoFrame(src: TRTCCloudDef.TRTCVideoFrame, dst: TRTCCloudDef.TRTCVideoFrame): Int {
            dst.texture.textureId = src.texture.textureId
            try {
                dst.texture.textureId = processor.process(src.texture.textureId, src.width, src.height)
            } catch (_: Exception) {
                main.post {
                    if (activation === this) {
                        stop(); emitReady()
                    }
                }
            }
            return 0
        }

        override fun onGLContextDestory() {
            processor.destroy()
            main.post {
                if (activation === this) {
                    ready = false; dismiss(); emitReady()
                }
            }
        }
    }
}

/** Paint only the navigation inset; the SDK slider above the panel stays transparent. */
private class SafeAreaFill : ColorDrawable(0xFF1F2024.toInt()) {
    var bottomInset = 0
        set(value) {
            field = value; invalidateSelf()
        }

    override fun draw(canvas: Canvas) {
        val save = canvas.save()
        canvas.clipRect(bounds.left, bounds.bottom - bottomInset, bounds.right, bounds.bottom)
        super.draw(canvas)
        canvas.restoreToCount(save)
    }
}
