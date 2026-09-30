// Copyright (c) 2026 Tencent. All rights reserved.

import 'dart:io';

import 'package:atomic_x_core/api/view/camera_view.dart';
import 'package:atomic_x_core/impl/common/atomic_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MediaMixingRenderView extends StatefulWidget {
  const MediaMixingRenderView({
    super.key,
    required this.onViewCreated,
    required this.onViewDisposed,
  });

  final CameraViewCallback onViewCreated;

  final CameraViewCallback onViewDisposed;

  @override
  State<MediaMixingRenderView> createState() => _MediaMixingRenderViewState();
}

class _MediaMixingRenderViewState extends State<MediaMixingRenderView> {
  static const MethodChannel _textureChannel = MethodChannel('atomic_engine_video_view');

  int? _textureId;
  int? _surfaceId;
  bool _fallbackToPlatformView = false;

  bool get _preferTexture => AtomicPlatform.isOhos || Platform.isWindows;

  @override
  void initState() {
    super.initState();
    if (_preferTexture) {
      _initTexture();
    }
  }

  @override
  void dispose() {
    final textureId = _textureId;
    if (textureId != null) {
      _textureChannel.invokeMethod('unregisterTexture', {
        'textureId': textureId,
      });
    }
    final surfaceId = _surfaceId;
    if (surfaceId != null && surfaceId != 0) {
      widget.onViewDisposed(surfaceId);
    }
    super.dispose();
  }

  Future<void> _initTexture() async {
    try {
      int textureId;
      int surfaceId;
      if (AtomicPlatform.isOhos) {
        textureId = await _textureChannel.invokeMethod('getTextureId');
        surfaceId = await _textureChannel.invokeMethod('getSurfaceId', {
          'textureId': textureId,
        });
      } else {
        // Windows：createTextureView + setMixedTextureRender。帧来自引擎
        // 转码模块自身的 setVideoFrameRenderCallback（开播前未 attachTRTC
        // 即出画面）；引擎导出缺失时插件报错，回退 CameraView 本地流。
        textureId = await _textureChannel.invokeMethod('createTextureView');
        surfaceId = textureId;
        await _textureChannel.invokeMethod('setMixedTextureRender', {
          'viewId': textureId,
        });
      }
      if (!mounted) return;
      setState(() {
        _textureId = textureId;
        _surfaceId = surfaceId;
      });
      widget.onViewCreated(_surfaceId!);
    } on PlatformException catch (e) {
      debugPrint('[MediaMixingRenderView] texture unavailable (${e.code}), '
          'falling back to platform view');
      if (!mounted) return;
      setState(() => _fallbackToPlatformView = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_preferTexture && !_fallbackToPlatformView) {
      final textureId = _textureId;
      if (textureId == null) {
        return Container(color: const Color(0xFF000000));
      }
      return Container(
        color: const Color(0xFF000000),
        child: Texture(textureId: textureId),
      );
    }
    return CameraView(
      onViewCreated: widget.onViewCreated,
      onViewDisposed: widget.onViewDisposed,
    );
  }
}
