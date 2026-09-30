import 'dart:io';

import 'package:atomic_x_core/impl/common/atomic_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CameraViewCallback = void Function(int nativePtr);

class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    this.onViewCreated,
    this.onViewDisposed,
  });

  final CameraViewCallback? onViewCreated;
  final CameraViewCallback? onViewDisposed;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static const String _viewType = 'atomic_engine/video_view';
  static const String _channelPrefix = 'atomic_engine_video_view_';
  static const String _methodGetNativeViewPtr = 'getNativeViewPtr';
  static const MethodChannel _textureChannel =
      MethodChannel('atomic_engine_video_view');

  int? _nativePtr;
  int? _textureId;
  int? _surfaceId;
  (int, int)? _lastRenderSize;

  bool get _useTexture => AtomicPlatform.isOhos || Platform.isWindows;

  @override
  void initState() {
    super.initState();
    if (_useTexture) {
      _initTexture();
    }
  }

  @override
  void dispose() {
    if (_useTexture) {
      final textureId = _textureId;
      if (textureId != null) {
        _textureChannel.invokeMethod('unregisterTexture', {
          'textureId': textureId,
        });
      }
      final surfaceId = _surfaceId;
      if (surfaceId != null && surfaceId != 0) {
        widget.onViewDisposed?.call(surfaceId);
      }
      _textureId = null;
      _surfaceId = null;
    } else {
      final ptr = _nativePtr;
      if (ptr != null && ptr != 0) {
        widget.onViewDisposed?.call(ptr);
      }
      _nativePtr = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useTexture) {
      return _buildTextureView();
    }
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (Platform.isIOS) {
      return UiKitView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (Platform.isMacOS) {
      return AppKitView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return const _UnsupportedPlatformPlaceholder();
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
        // Windows
        textureId = await _textureChannel.invokeMethod('createTextureView');
        surfaceId = textureId;
        await _textureChannel.invokeMethod('setLocalTextureRender', {
          'viewId': textureId,
          'streamType': 0,
        });
      }
      if (!mounted) return;
      final int textureIdInt = textureId;
      final int surfaceIdInt = surfaceId;
      setState(() {
        _textureId = textureIdInt;
        _surfaceId = surfaceIdInt;
      });
      widget.onViewCreated?.call(_surfaceId!);
    } on PlatformException catch (e) {
      debugPrint(
          '[CameraView] init texture failed: ${e.code} ${e.message}');
    }
  }

  Widget _buildTextureView() {
    final textureId = _textureId;
    if (textureId == null) {
      return Container(color: Colors.transparent);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
          final pixelRatio = MediaQuery.of(context).devicePixelRatio;
          final renderWidth = (constraints.maxWidth * pixelRatio).toInt();
          final renderHeight = (constraints.maxHeight * pixelRatio).toInt();
          final newRenderSize = (renderWidth, renderHeight);
          if (newRenderSize != _lastRenderSize) {
            _lastRenderSize = newRenderSize;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _textureId != null) {
                _textureChannel.invokeMethod('setRenderSize', {
                  'textureId': textureId,
                  'width': renderWidth,
                  'height': renderHeight,
                });
              }
            });
          }
        }
        return Container(
          color: Colors.transparent,
          child: Texture(
            textureId: textureId,
            filterQuality: FilterQuality.medium,
          ),
        );
      },
    );
  }

  Future<void> _onPlatformViewCreated(int id) async {
    final channel = MethodChannel('$_channelPrefix$id');
    try {
      final result =
          await channel.invokeMethod<Object>(_methodGetNativeViewPtr);
      if (!mounted) return;
      final ptr = _coerceToInt(result);
      if (ptr == null || ptr == 0) {
        debugPrint(
            '[CameraView] getNativeViewPtr returned invalid value: $result');
        return;
      }
      _nativePtr = ptr;
      widget.onViewCreated?.call(ptr);
    } on PlatformException catch (e) {
      debugPrint(
          '[CameraView] getNativeViewPtr failed: ${e.code} ${e.message}');
    }
  }

  static int? _coerceToInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class _UnsupportedPlatformPlaceholder extends StatelessWidget {
  const _UnsupportedPlatformPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000),
      alignment: Alignment.center,
      child: const Icon(
        Icons.videocam_off,
        color: Color(0x66FFFFFF),
        size: 32,
      ),
    );
  }
}
