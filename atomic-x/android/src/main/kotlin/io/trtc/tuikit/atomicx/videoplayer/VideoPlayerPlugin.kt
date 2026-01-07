package io.trtc.tuikit.atomicx.videoplayer

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class VideoPlayerPlugin : FlutterPlugin {
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
        
        // Register PlatformView for inline playback (Flutter controls)
        binding.platformViewRegistry.registerViewFactory(
            "io.trtc.tuikit.atomicx/inline_video_player",
            InlineVideoPlayerViewFactoryWithChannel(binding)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = null
    }
}

/**
 * Factory that creates InlineVideoPlayerPlatformView with MethodChannel support
 */
class InlineVideoPlayerViewFactoryWithChannel(
    private val binding: FlutterPlugin.FlutterPluginBinding
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<*, *>
        val platformView = InlineVideoPlayerPlatformView(context, viewId, creationParams)
        
        // Create and set MethodChannel for this view
        val channel = MethodChannel(
            binding.binaryMessenger,
            "io.trtc.tuikit.atomicx/inline_video_player_$viewId"
        )
        platformView.setMethodChannel(channel)
        
        return platformView
    }
}
