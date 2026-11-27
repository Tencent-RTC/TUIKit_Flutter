/// 大礼物动画队列；只准备当前及下一条资源，失败或超时后继续下一条。
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'playback/gift_player.dart';

class GiftAnimationController extends ChangeNotifier {
  GiftAnimationController({GiftPlayer? player})
      : _player = player ?? GiftPlayer();

  static const Duration playbackTimeout = Duration(seconds: 30);

  final GiftPlayer _player;
  final List<_PendingAnimation> _queue = [];
  _PendingAnimation? _current;
  Timer? _timeoutTimer;
  int _generation = 0;
  bool _disposed = false;
  double _previewBottomInset = 0;

  double get previewBottomInset => _previewBottomInset;

  void enqueue(String resourceURL) {
    if (_disposed) return;
    _queue.add(_PendingAnimation(resourceURL));
    _playNextIfNeeded();
    _prepareNextIfNeeded();
  }

  void reset() {
    if (_disposed) return;
    _clear();
    notifyListeners();
  }

  void updatePreviewBottomInset(double inset) {
    final normalized = inset.isFinite && inset > 0 ? inset : 0.0;
    if (_disposed || _previewBottomInset == normalized) return;
    _previewBottomInset = normalized;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clear();
    _player.dispose();
    super.dispose();
  }

  void _clear() {
    _generation += 1;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _current?.dispose();
    _current = null;
    for (final animation in _queue) {
      animation.dispose();
    }
    _queue.clear();
    _player.stop();
  }

  void _playNextIfNeeded() {
    if (_current != null || _queue.isEmpty) return;
    final animation = _queue.removeAt(0);
    _current = animation;
    _scheduleTimeout(animation);
    if (animation.task == null) {
      _prepare(animation);
    } else {
      _consumePreparation(animation);
    }
  }

  void _prepareNextIfNeeded() {
    if (_current?.started == true && _queue.isNotEmpty) {
      final next = _queue.first;
      if (next.task == null) _prepare(next);
    }
  }

  Future<void> _prepare(_PendingAnimation animation) async {
    final generation = _generation;
    final task = _player.prepare(animation.resourceURL);
    animation.task = task;
    try {
      final resource = await task.result;
      if (!_isActive(animation, generation)) {
        resource.release();
        return;
      }
      animation.resource = resource;
    } on Object {
      if (!_isActive(animation, generation)) return;
      animation.failed = true;
    }
    _consumePreparation(animation);
  }

  bool _isActive(_PendingAnimation animation, int generation) =>
      !_disposed &&
      _generation == generation &&
      (_current == animation ||
          (_queue.isNotEmpty && _queue.first == animation));

  void _consumePreparation(_PendingAnimation animation) {
    if (_current != animation || animation.started) return;
    if (animation.failed) {
      _finishCurrentEffect();
      return;
    }
    final resource = animation.resource;
    if (resource == null) return;
    animation.started = true;
    _player.play(resource, onFinished: (failed) {
      if (_current == animation) _finishCurrentEffect();
    });
    _scheduleTimeout(animation);
    notifyListeners();
    _prepareNextIfNeeded();
  }

  void _scheduleTimeout(_PendingAnimation animation) {
    _timeoutTimer?.cancel();
    final generation = _generation;
    _timeoutTimer = Timer(playbackTimeout, () {
      if (_generation == generation && _current == animation) {
        _finishCurrentEffect();
      }
    });
  }

  void _finishCurrentEffect() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    final previous = _current;
    _current = null;
    previous?.dispose();
    _player.stop();
    notifyListeners();
    _playNextIfNeeded();
  }
}

class _PendingAnimation {
  _PendingAnimation(this.resourceURL);
  final String resourceURL;
  GiftPreparationTask? task;
  GiftPreparedResource? resource;
  bool failed = false;
  bool started = false;

  void dispose() {
    task?.cancel();
    resource?.release();
  }
}

class GiftAnimationView extends StatelessWidget {
  const GiftAnimationView({super.key, required this.controller});
  final GiftAnimationController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Padding(
          padding: EdgeInsets.only(bottom: controller.previewBottomInset),
          child: child,
        ),
        child: GiftPlayerView(player: controller._player),
      );
}
