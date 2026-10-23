/// 单次礼物媒体播放；队列、下一条准备与超时由 GiftAnimationController 管理。
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_effect_player/ftceffect_player.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

import 'gift_resource_loader.dart';
import 'gift_svga_decoder.dart';

enum GiftPlaybackKind { svga, mp4 }

class GiftPlayer extends ChangeNotifier {
  GiftPlayer({
    GiftResourceLoader? loader,
    Future<MovieEntity> Function(String localPath)? decodeSVGA,
  })  : _loader = loader ?? GiftResourceLoader(),
        _decodeSVGA = decodeSVGA;

  final GiftResourceLoader _loader;
  final Future<MovieEntity> Function(String)? _decodeSVGA;
  final Set<GiftPreparationTask> _preparations = {};
  final Map<String, Future<String>> _loads = {};
  GiftPreparedResource? _resource;
  void Function(bool failed)? _onFinished;
  int _playbackToken = 0;
  bool _disposed = false;

  GiftPlaybackKind? get currentKind => _resource?.kind;
  String? get currentLocalPath => _resource?.localPath;

  GiftPreparationTask prepare(String resourceURL) {
    late final GiftPreparationTask task;
    task = GiftPreparationTask._(resourceURL, () => _cancelPreparation(task));
    _preparations.add(task);
    task.result = _prepare(task);
    return task;
  }

  /// 播放已准备的资源，替换当前动画，不排队。
  void play(GiftPreparedResource resource,
      {required void Function(bool failed) onFinished}) {
    if (_disposed) return;
    stop();
    _resource = resource..retain();
    _onFinished = onFinished;
    notifyListeners();
  }

  void stop() {
    _playbackToken += 1;
    _onFinished = null;
    _resource?.release();
    _resource = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
    for (final task in _preparations.toList()) {
      task.cancel();
    }
    _loader.dispose();
    super.dispose();
  }

  Future<GiftPreparedResource> _prepare(GiftPreparationTask task) async {
    var stage = 'download';
    final kind = _kindOf(task.resourceURL);
    try {
      _checkActive(task);
      if (kind == null) throw const FormatException('Unsupported gift format');
      final current = _resource;
      // 当前和下一条同 URL 时共享已解码资源，不复制图片和 GPU 缓存。
      if (current != null && current.resourceURL == task.resourceURL) {
        return current..retain();
      }
      final path = await _load(task.resourceURL);
      _checkActive(task);
      MovieEntity? movie;
      if (kind == GiftPlaybackKind.svga) {
        stage = 'svga_decode';
        movie = await (_decodeSVGA?.call(path) ??
            const GiftSVGADecoder().decodeFile(path,
                isCancelled: () => _disposed || task._cancelled));
        if (_disposed || task._cancelled) {
          movie.dispose();
          _checkActive(task);
        }
      }
      return GiftPreparedResource._(task.resourceURL, path, kind, movie);
    } on Object catch (error) {
      if (!_disposed && !task._cancelled) {
        debugPrint('[TUILiveKit][GiftPlayer] prepare failed '
            'stage=$stage kind=${kind?.name} error=${error.runtimeType}');
      }
      rethrow;
    } finally {
      _preparations.remove(task);
    }
  }

  Future<String> _load(String resourceURL) {
    final existing = _loads[resourceURL];
    if (existing != null) return existing;
    final future = _loader.load(resourceURL);
    _loads[resourceURL] = future;
    future.whenComplete(() {
      if (identical(_loads[resourceURL], future)) _loads.remove(resourceURL);
    }).ignore();
    return future;
  }

  void _cancelPreparation(GiftPreparationTask task) {
    if (!_preparations.remove(task)) return;
    if (!_preparations.any((other) => other.resourceURL == task.resourceURL)) {
      _loader.cancel(task.resourceURL);
      _loads.remove(task.resourceURL);
    }
  }

  void _checkActive(GiftPreparationTask task) {
    if (_disposed || task._cancelled) {
      throw const FormatException('Gift preparation cancelled');
    }
  }

  void _finish(int token, {bool failed = false}) {
    if (_disposed || token != _playbackToken || _resource == null) return;
    final callback = _onFinished;
    stop();
    callback?.call(failed);
  }

  static GiftPlaybackKind? _kindOf(String resourceURL) {
    final path = Uri.tryParse(resourceURL)?.path.toLowerCase();
    if (path?.endsWith('.svga') == true) return GiftPlaybackKind.svga;
    if (path?.endsWith('.mp4') == true) return GiftPlaybackKind.mp4;
    return null;
  }
}

class GiftPreparationTask {
  GiftPreparationTask._(this.resourceURL, this._onCancel);
  final String resourceURL;
  final VoidCallback _onCancel;
  late final Future<GiftPreparedResource> result;
  bool _cancelled = false;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel();
  }
}

/// 队列、播放器及仍在树中的渲染组件分别持有，最后释放者销毁 SVGA 图片。
class GiftPreparedResource {
  GiftPreparedResource._(
      this.resourceURL, this.localPath, this.kind, this._movie) {
    _movie?.autorelease = false;
  }
  final String resourceURL;
  final String localPath;
  final GiftPlaybackKind kind;
  final MovieEntity? _movie;
  int _owners = 1;

  void retain() => _owners += 1;

  void release() {
    _owners -= 1;
    if (_owners == 0) _movie?.dispose();
  }
}

class GiftPlayerView extends StatelessWidget {
  const GiftPlayerView({super.key, required this.player});
  final GiftPlayer player;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: player,
        builder: (context, _) {
          final resource = player._resource;
          if (resource == null) return const SizedBox.shrink();
          final token = player._playbackToken;
          return IgnorePointer(
            child: SizedBox.expand(
              child: resource.kind == GiftPlaybackKind.svga
                  ? _GiftSVGAView(
                      key: ValueKey((player, token)),
                      resource: resource,
                      onFinished: () => player._finish(token),
                    )
                  : _GiftMP4View(
                      key: ValueKey((player, token)),
                      localPath: resource.localPath,
                      onFinished: () => player._finish(token),
                      onFailed: () => player._finish(token, failed: true),
                    ),
            ),
          );
        },
      );
}

class _GiftSVGAView extends StatefulWidget {
  const _GiftSVGAView({
    super.key,
    required this.resource,
    required this.onFinished,
  });
  final GiftPreparedResource resource;
  final VoidCallback onFinished;

  @override
  State<_GiftSVGAView> createState() => _GiftSVGAViewState();
}

class _GiftSVGAViewState extends State<_GiftSVGAView>
    with SingleTickerProviderStateMixin {
  late final SVGAAnimationController _animationController =
      SVGAAnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    widget.resource.retain();
    _animationController.videoItem = widget.resource._movie!;
    _animationController.addStatusListener(_handleStatus);
    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_handleStatus);
    _animationController.dispose();
    widget.resource.release();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    // iOS 当前三条 Metal 绘制路径均 min(scaleX, scaleY) 居中。
    // 填满的是透明画布，素材保持等比；不能将 scaleAspectFit 误写为 fill。
    return SVGAImage(_animationController,
        fit: BoxFit.contain,
        allowDrawingOverflow: false,
        clearsAfterStop: true);
  }
}

class _GiftMP4View extends StatefulWidget {
  const _GiftMP4View({
    super.key,
    required this.localPath,
    required this.onFinished,
    required this.onFailed,
  });
  final String localPath;
  final VoidCallback onFinished;
  final VoidCallback onFailed;

  @override
  State<_GiftMP4View> createState() => _GiftMP4ViewState();
}

class _GiftMP4ViewState extends State<_GiftMP4View> {
  FTCEffectViewController? _controller;
  Timer? _licenseRetry;
  bool _isDisposed = false;
  bool _configured = false;
  bool _started = false;
  bool _waitingForLicense = false;
  bool _starting = false;
  int? _lastErrorCode;

  @override
  void dispose() {
    _isDisposed = true;
    _licenseRetry?.cancel();
    _controller?.setPlayListener(null);
    _controller?.stopPlay(clearLastFrame: true).ignore();
    _controller = null;
    super.dispose();
  }

  Future<void> _handleControllerCreated(
      FTCEffectViewController controller) async {
    if (_isDisposed) {
      await controller.stopPlay(clearLastFrame: true);
      return;
    }
    _controller = controller;
    controller.setPlayListener(FAnimPlayListener(
      onPlayEnd: () {
        if (!_isDisposed && !_waitingForLicense) {
          widget.onFinished();
        }
      },
      onPlayError: _handleError,
    ));
    try {
      await controller.setLoop(false);
      if (_isDisposed) return;
      await controller.setScaleType(FScaleType.CENTER_CROP);
      if (_isDisposed) return;
      // 插件双端 index 3 均映射 alpha-right，与 iOS 模版 rawValue 2 相同。
      await controller
          .setVideoMode(FVideoMode.VIDEO_MODE_SPLIT_HORIZONTAL_REVERSE);
      if (_isDisposed) return;
      _configured = true;
      _startPlayback();
    } on Object catch (error) {
      debugPrint(
          '[TUILiveKit][GiftMP4] configure failed: ${error.runtimeType}');
      if (!_isDisposed) widget.onFailed();
    }
  }

  Future<void> _startPlayback() async {
    if (_starting || !_configured || _isDisposed || _started) return;
    if (_waitingForLicense) {
      _scheduleLicenseRetry();
      return;
    }
    _starting = true;
    _started = true;
    try {
      final controller = _controller!;
      final result = await controller.startPlay(widget.localPath);
      // 平台调用尚未返回时视图可能已移除，迟到启动仍须停止。
      if (_isDisposed) {
        await controller.stopPlay(clearLastFrame: true);
        return;
      }
      if (result != 0) _handleError(result);
    } on Object catch (error) {
      debugPrint('[TUILiveKit][GiftMP4] playback failed: ${error.runtimeType}');
      if (!_isDisposed) widget.onFailed();
    } finally {
      _starting = false;
      if (!_isDisposed && _waitingForLicense) _scheduleLicenseRetry();
    }
  }

  void _handleError(int code) {
    if (_isDisposed) return;
    if (_lastErrorCode != code) {
      _lastErrorCode = code;
      debugPrint('[TUILiveKit][GiftMP4] playback error=$code');
    }
    if (code != -10009) {
      // 普通播放错误立即结束，授权未就绪时由下方重试。
      widget.onFailed();
      return;
    }
    _waitingForLicense = true;
    _started = false;
    _scheduleLicenseRetry();
  }

  void _scheduleLicenseRetry() {
    if (_licenseRetry != null || _isDisposed) return;
    _licenseRetry = Timer(const Duration(seconds: 1), () {
      _licenseRetry = null;
      if (_isDisposed) return;
      if (_starting) {
        _scheduleLicenseRetry();
        return;
      }
      _waitingForLicense = false;
      _startPlayback();
    });
  }

  @override
  Widget build(BuildContext context) =>
      FTCEffectAnimView(controllerCallback: _handleControllerCreated);
}
