import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'asr_service_error.dart';
import 'realtime_asr.dart';
import 'realtime_asr_experimental.dart';
import 'realtime_asr_packet_buffer.dart';
import 'realtime_asr_spec.dart';
import 'realtime_audio_capture.dart';

enum _SessionStage {
  /// 还没建，或上一次建失败了。
  none,

  /// start 已发出，会话 ID 还没回来。
  starting,

  /// 会话可用。
  ready,

  /// 已 stop，等尾句结果。
  draining,
}

/// 长按录音期间的实时语音识别，[RealtimeAsrSession] 的默认实现。
///
/// 一次长按的完整生命周期：
///
/// 1. [prime] —— 手指按下、开始录音。麦克风采集起来，同时把后台会话也建上：建会话要一个
///    网络往返，等用户滑到「转文字」再建，那几百毫秒到几秒会原样变成用户盯着空气等的时间。
/// 2. [beginRecognize] —— 手指**第一次**滑到「转文字」。正常情况下是空操作，只兜两件事：
///    按下那次建会话失败了在这里重试，以及把建会话往返期间攒的缓冲补推上去。
/// 3. [finish] —— 在「转文字」上松手。先送完尾包再 stop，再留一个收尾窗口等尾句结果。
/// 4. [cancel] —— 滑到「取消」松手、录音失败、页面销毁。全部丢弃。
///
/// 「会话开没开」和「音频推不推」是两件独立的事，分别由 [_stage] 和 [_uploading] 表示。
class RealtimeAsrRecognizer implements RealtimeAsrSession {
  RealtimeAsrRecognizer({this.language = ''});

  /// ISO 639-1，留空交给后台判断。
  final String language;

  final StreamController<String> _textController = StreamController<String>.broadcast();
  final RealtimeAsrPacketBuffer _preRoll = RealtimeAsrPacketBuffer(RealtimeAsrSpec.preRollCapacity);
  final List<Uint8List> _pendingUpload = [];

  /// chunkIndex -> 该句当前最完整的文本。后台会对同一句反复下发修正后的结果。
  final SplayTreeMap<int, String> _sentences = SplayTreeMap<int, String>();

  /// [prime] 成功到 [_release] 之间为 true，即麦克风采集是否归本实例所有。
  bool _active = false;

  /// 采集正在启动（[prime] 的异步窗口）。期间被 cancel / finish 时启动结果作废。
  bool _priming = false;
  int _primeToken = 0;

  _SessionStage _stage = _SessionStage.none;

  /// 音频是否往上推。false 时一律进 [_preRoll]，等开关打开再补推。
  bool _uploading = false;

  String? _sessionID;
  Timer? _startTimeout;
  Timer? _drainTimeout;
  Completer<String>? _finishCompleter;

  /// 每次状态跃迁都 +1。建会话的回调、超时任务各自捕获发起时的代数，对不上就说明
  /// 自己已经过期。不能用布尔量代替：松手后紧接着的下一次长按会把布尔量复位，
  /// 让上一轮在途请求的迟到回调污染新一轮。
  int _generation = 0;

  /// 本次长按建会话时后台回了 [AsrServiceError.isServiceUnavailable]，重试也没用。
  bool _isServiceUnavailable = false;

  @override
  Stream<String> get onTextChanged => _textController.stream;

  @override
  bool get isRecognizing =>
      _active && _uploading && (_stage == _SessionStage.starting || _stage == _SessionStage.ready);

  @override
  String get text => _sentences.values.join();

  @override
  Future<bool> prime() async {
    if (_active || _priming) {
      return _active;
    }
    _reset();
    _isServiceUnavailable = false;
    _priming = true;
    final token = ++_primeToken;
    final started = await RealtimeAudioCapture.instance.start(
      mode: RealtimeAudioCaptureMode.recognition,
      minBufferFrames: 8,
      onFrame: _onCapturedFrame,
    );
    if (token != _primeToken) {
      // 启动期间已被取消，别让刚起来的采集悬空
      if (started) {
        unawaited(RealtimeAudioCapture.instance.stop());
      }
      return false;
    }
    _priming = false;
    if (!started) {
      return false;
    }
    _active = true;
    _uploading = RealtimeAsrSpec.uploadFromPress;
    RealtimeAsrExperimental.addResponseListener(_handleResponse);
    _startSession();
    return true;
  }

  @override
  Future<void> beginRecognize() async {
    if (!_active) {
      return;
    }
    _uploading = true;
    switch (_stage) {
      case _SessionStage.none:
        // 按下时那次建会话失败了（网络抖动等），用户既然滑过来了就再试一次
        if (!_isServiceUnavailable) {
          _startSession();
        }
        break;
      case _SessionStage.ready:
        _flushPreRoll();
        break;
      case _SessionStage.starting:
      case _SessionStage.draining:
        break;
    }
  }

  void _startSession() {
    if (_stage != _SessionStage.none) {
      return;
    }
    _stage = _SessionStage.starting;
    final currentGeneration = ++_generation;
    _scheduleStartTimeout(currentGeneration);
    RealtimeAsrExperimental.start(language: language).then((result) {
      if (result.isSuccess) {
        _onStartSucceeded(currentGeneration, result.sessionID);
      } else {
        _onStartFailed(currentGeneration, result.code, result.desc);
      }
    });
  }

  /// 一定会完成一次：收到带 isFinished 的终态响应、stop 失败、或收尾超时，三者取最早。
  /// 识别没能起来时给空串，调用方据此回落到「上传整段音频再识别」。
  @override
  Future<String> finish() {
    if (!_active) {
      _abortPriming();
      return Future.value('');
    }
    _stopCapture();
    final activeSessionID = _sessionID;
    if (_stage != _SessionStage.ready || activeSessionID == null) {
      // 会话还没建起来（或压根没开始识别），没有尾句可等
      final recognized = text;
      _release();
      return Future.value(recognized);
    }
    _stage = _SessionStage.draining;
    _generation++;
    final completer = Completer<String>();
    _finishCompleter = completer;
    _drainTimeout = Timer(const Duration(milliseconds: RealtimeAsrSpec.drainTimeoutMs), _completeDrain);
    _flushTailThenStop(activeSessionID);
    return completer.future;
  }

  /// 把最后一批音频送完再关会话。
  ///
  /// 不能一边上行一边 stop：后者一到服务端就把会话关了，还在飞的那包会撞上
  /// `140002 session is closed`，松手前最后几十毫秒的音频连同它对应的尾字一起丢。
  /// 后台不回 ack 时由 [RealtimeAsrSpec.tailUploadTimeoutMs] 兜底。
  void _flushTailThenStop(String id) {
    _pendingUpload.addAll(_preRoll.drain());
    final tail = List<Uint8List>.of(_pendingUpload);
    _pendingUpload.clear();
    final chunks = _chunked(tail, RealtimeAsrSpec.uploadMaxFramesPerCall);
    if (chunks.isEmpty) {
      _stopSession(id);
      return;
    }
    var stopped = false;
    var pending = chunks.length;
    void stopOnce() {
      if (!stopped) {
        stopped = true;
        _stopSession(id);
      }
    }

    final guard = Timer(const Duration(milliseconds: RealtimeAsrSpec.tailUploadTimeoutMs), () {
      debugPrint('RealtimeAsrRecognizer: tail upload timed out, stopping anyway');
      stopOnce();
    });
    for (final chunk in chunks) {
      RealtimeAsrExperimental.feed(sessionID: id, packets: chunk).then((result) {
        if (!result.isSuccess) {
          debugPrint('RealtimeAsrRecognizer: tail feed failed: ${result.code} ${result.desc}');
        }
        pending--;
        if (pending == 0) {
          guard.cancel();
          stopOnce();
        }
      });
    }
  }

  void _stopSession(String id) {
    RealtimeAsrExperimental.stop(sessionID: id).then((result) {
      // 成功只是「会话已关闭」的 ack，不代表结果到齐了，继续等 isFinished 或收尾超时
      if (!result.isSuccess) {
        debugPrint('RealtimeAsrRecognizer: stop failed: ${result.code} ${result.desc}');
        // 停不掉的会话不会再吐结果，继续干等只是白白拖慢发送
        _completeDrain();
      }
    });
  }

  @override
  Future<void> cancel() async {
    if (!_active) {
      _abortPriming();
      return;
    }
    _stopCapture();
    final id = _sessionID;
    if (id != null) {
      unawaited(RealtimeAsrExperimental.stop(sessionID: id));
    }
    _release();
  }

  void _onStartSucceeded(int expectedGeneration, String id) {
    if (expectedGeneration != _generation) {
      // 用户已经松手/取消了，后台却仍然分配了会话，立刻关掉，别留悬空会话
      if (id.isNotEmpty) {
        unawaited(RealtimeAsrExperimental.stop(sessionID: id));
      }
      return;
    }
    _cancelStartTimeout();
    _generation++;
    if (id.isEmpty) {
      _stage = _SessionStage.none;
      return;
    }
    _sessionID = id;
    _stage = _SessionStage.ready;
    if (_uploading) {
      _flushPreRoll();
    }
  }

  /// 把会话就绪前攒下的音频补推上去，连同已在排队的那批。
  void _flushPreRoll() {
    final id = _sessionID;
    if (id == null) {
      return;
    }
    _pendingUpload.addAll(_preRoll.drain());
    _flushPendingUpload(id);
  }

  void _onStartFailed(int expectedGeneration, int code, String desc) {
    if (expectedGeneration != _generation) {
      return;
    }
    _cancelStartTimeout();
    _generation++;
    debugPrint('RealtimeAsrRecognizer: start failed: $code $desc');
    _isServiceUnavailable = AsrServiceError.isServiceUnavailable(code);
    // 退回 none 而不是直接废掉：用户滑到「转文字」时 beginRecognize 还能再试一次
    _stage = _SessionStage.none;
  }

  void _onCapturedFrame(List<Uint8List> packets, double rms) {
    for (final packet in packets) {
      _onCapturedPacket(packet);
    }
  }

  void _onCapturedPacket(Uint8List packet) {
    if (!_active) {
      return;
    }
    final id = _sessionID;
    if (_uploading && _stage == _SessionStage.ready && id != null) {
      _pendingUpload.add(packet);
      if (_pendingUpload.length >= RealtimeAsrSpec.uploadBatchFrames) {
        _flushPendingUpload(id);
      }
    } else if (_stage != _SessionStage.draining) {
      _preRoll.append(packet);
    }
  }

  void _flushPendingUpload(String id) {
    if (_pendingUpload.isEmpty) {
      return;
    }
    final batch = List<Uint8List>.of(_pendingUpload);
    _pendingUpload.clear();
    // 补推积压时这一批会比实时节奏长，切片发：失败的话丢的只是一片而不是全部。
    // 切出来的几片是并行在飞的，不会因为分片而变慢。
    for (final chunk in _chunked(batch, RealtimeAsrSpec.uploadMaxFramesPerCall)) {
      RealtimeAsrExperimental.feed(sessionID: id, packets: chunk).then((result) {
        // 丢包容忍：记日志继续，不中断会话
        if (!result.isSuccess) {
          debugPrint('RealtimeAsrRecognizer: feed failed: ${result.code} ${result.desc}');
        }
      });
    }
  }

  void _handleResponse(RealtimeAsrResponse response) {
    final activeSessionID = _sessionID;
    if (activeSessionID == null) {
      return;
    }
    if (response.sessionID.isNotEmpty && response.sessionID != activeSessionID) {
      return;
    }
    // 后台偶发下发 index=0 / text=""，别让它把已累积的句子桶覆盖成空
    if (response.text.isNotEmpty) {
      _sentences[response.chunkIndex] = response.text;
      _textController.add(text);
    }
    if (response.isFinished && _stage == _SessionStage.draining) {
      _completeDrain();
    }
  }

  void _scheduleStartTimeout(int expectedGeneration) {
    _startTimeout?.cancel();
    _startTimeout = Timer(const Duration(milliseconds: RealtimeAsrSpec.startTimeoutMs), () {
      _startTimeout = null;
      if (expectedGeneration != _generation) {
        return;
      }
      debugPrint('RealtimeAsrRecognizer: start timed out');
      _generation++;
      _stage = _SessionStage.none;
    });
  }

  void _cancelStartTimeout() {
    _startTimeout?.cancel();
    _startTimeout = null;
  }

  void _completeDrain() {
    final completer = _finishCompleter;
    if (completer == null) {
      return;
    }
    _finishCompleter = null;
    _drainTimeout?.cancel();
    _drainTimeout = null;
    final recognized = text;
    _release();
    completer.complete(recognized);
  }

  void _abortPriming() {
    if (_priming) {
      _priming = false;
      _primeToken++;
    }
  }

  void _stopCapture() {
    if (_active) {
      unawaited(RealtimeAudioCapture.instance.stop());
    }
  }

  void _release() {
    _cancelStartTimeout();
    _drainTimeout?.cancel();
    _drainTimeout = null;
    final pending = _finishCompleter;
    _finishCompleter = null;
    // 收尾途中被取消也要让 finish() 的调用方醒过来
    if (pending != null && !pending.isCompleted) {
      pending.complete(text);
    }
    if (_active) {
      RealtimeAsrExperimental.removeResponseListener(_handleResponse);
    }
    _generation++;
    _active = false;
    _uploading = false;
    _stage = _SessionStage.none;
    _sessionID = null;
    _reset();
  }

  void _reset() {
    _preRoll.clear();
    _pendingUpload.clear();
    _sentences.clear();
  }

  static List<List<Uint8List>> _chunked(List<Uint8List> source, int size) {
    return [
      for (var i = 0; i < source.length; i += size)
        source.sublist(i, i + size > source.length ? source.length : i + size),
    ];
  }
}
