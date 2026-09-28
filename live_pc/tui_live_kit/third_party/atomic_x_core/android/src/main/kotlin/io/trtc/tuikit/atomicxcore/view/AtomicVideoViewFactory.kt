package io.trtc.tuikit.atomicxcore.view

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class AtomicVideoViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    private val viewMap: MutableMap<Int, AtomicVideoView> = HashMap()

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val view = AtomicVideoView(context, viewId, messenger) { id ->
            viewMap.remove(id)
        }
        viewMap[viewId] = view
        return view
    }

    companion object {
        const val VIEW_TYPE: String = "atomic_engine/video_view"
    }
}
