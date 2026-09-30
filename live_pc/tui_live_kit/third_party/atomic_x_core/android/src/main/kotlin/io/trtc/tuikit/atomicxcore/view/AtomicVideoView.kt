package io.trtc.tuikit.atomicxcore.view

import android.content.Context
import android.view.View
import com.tencent.rtmp.ui.TXCloudVideoView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

internal class AtomicVideoView(
    context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    private val onDisposed: (Int) -> Unit,
) : PlatformView, MethodChannel.MethodCallHandler {

    private val videoView: TXCloudVideoView = TXCloudVideoView(context)
    private val channel: MethodChannel =
        MethodChannel(messenger, "$CHANNEL_PREFIX$viewId").apply {
            setMethodCallHandler(this@AtomicVideoView)
        }

    private var nativeViewPtr: Long = 0L

    override fun getView(): View = videoView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_GET_NATIVE_VIEW_PTR -> {
                if (nativeViewPtr == 0L) {
                    nativeViewPtr = EngineBridgeJniHelper.nativeViewToPointer(videoView)
                }
                result.success(nativeViewPtr)
            }
            else -> result.notImplemented()
        }
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
        if (nativeViewPtr != 0L) {
            EngineBridgeJniHelper.nativeReleaseViewPointer(nativeViewPtr)
            nativeViewPtr = 0L
        }
        onDisposed(viewId)
    }

    companion object {
        const val CHANNEL_PREFIX: String = "atomic_engine_video_view_"
        const val METHOD_GET_NATIVE_VIEW_PTR: String = "getNativeViewPtr"
    }
}
