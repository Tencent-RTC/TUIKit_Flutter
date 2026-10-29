/// 长按录音「边说边出字」的接入口。
///
/// 默认实现是 [ImRealtimeAsrProvider]：原生插件实时采集麦克风并编码成 16kHz 单声道裸 Opus
/// （`RealtimeAudioCapture`），经 IMSDK 实验接口上行识别（`RealtimeAsrExperimental`）。
/// 首次进入输入框时调用 [RealtimeAsr.ensureDefaultProvider]，设备支持实时采集
/// （Android 10+ / iOS）就自动装上；不支持时保持不可用，录音气泡照常显示，只是不出字，
/// 松手在「转文字」上仍然走「上传整段音频再识别」。
///
/// 也可以注入自己的实现，赋值后不会再被默认实现覆盖：
///
/// ```dart
/// void main() {
///   RealtimeAsr.provider = MyRealtimeAsrProvider();
///   runApp(const MyApp());
/// }
/// ```
library;

import 'dart:async';

import 'realtime_asr_recognizer.dart';
import 'realtime_audio_capture.dart';

/// 一次长按对应的识别会话。
///
/// 生命周期与 Android 端一致：
/// [prime] 手指按下 → [beginRecognize] 首次滑到「转文字」 → [finish] 在其上松手 /
/// [cancel] 取消。
///
/// [prime] 时采集和后台会话就一起起来、音频从按下就开始上行：后台只按实时语速出字，
/// 等滑过去再建会话、补推历史音频，换不来对应的文本，用户只会盯着空气等。
abstract class RealtimeAsrSession {
  /// 识别结果流，每次后台吐字推送一次「到目前为止的完整文本」。
  Stream<String> get onTextChanged;

  /// 当前已识别出的完整文本。
  String get text;

  /// 有识别结果可以期待：采集在跑、上行开着，且会话已建好或正在建。
  ///
  /// 松手在「转文字」上时为 false，说明这次实时识别没起来，调用方应当直接回落到整段上传识别。
  bool get isRecognizing;

  /// 开始采集，同时建后台会话。
  ///
  /// 返回 false 表示采集通路不可用（权限、机型、编码器缺失等），调用方应当
  /// 直接放弃本次实时识别，不影响语音消息本身。
  Future<bool> prime();

  /// 手指首次滑到「转文字」。按下时建会话失败了在这里重试，并把缓冲的音频补推上去。
  /// 重复调用无副作用。
  Future<void> beginRecognize();

  /// 在「转文字」上松手：停采集、关会话、等尾句结果。
  ///
  /// 返回完整识别文本；没识别出东西时返回空串，调用方据此回落到整段上传识别。
  Future<String> finish();

  /// 放弃本次识别并释放资源。可重复调用。
  Future<void> cancel();
}

abstract class RealtimeAsrProvider {
  const RealtimeAsrProvider();

  /// 当前环境能不能做实时识别。false 时 UI 不会创建会话。
  bool get isAvailable;

  /// @param language ISO 639-1 语言码，如 "zh"、"en"；留空交给后台判断
  RealtimeAsrSession createSession({String language});
}

/// 全局开关兼注入点。
class RealtimeAsr {
  RealtimeAsr._();

  static RealtimeAsrProvider _provider = const UnavailableRealtimeAsrProvider();
  static bool _isCustomProvider = false;
  static Future<void>? _defaultProviderInstall;

  static RealtimeAsrProvider get provider => _provider;

  /// 注入自定义实现。赋值后 [ensureDefaultProvider] 不会再覆盖它。
  static set provider(RealtimeAsrProvider value) {
    _provider = value;
    _isCustomProvider = true;
  }

  static bool get isAvailable => _provider.isAvailable;

  /// 设备支持实时采集、且没有注入过自定义实现时装上 [ImRealtimeAsrProvider]。
  /// 只检测一次，重复调用直接复用结果。
  static Future<void> ensureDefaultProvider() {
    return _defaultProviderInstall ??= _installDefaultProvider();
  }

  static Future<void> _installDefaultProvider() async {
    if (_isCustomProvider || _provider is! UnavailableRealtimeAsrProvider) {
      return;
    }
    final supported = await RealtimeAudioCapture.isSupported();
    if (supported && !_isCustomProvider && _provider is UnavailableRealtimeAsrProvider) {
      _provider = const ImRealtimeAsrProvider();
    }
  }

  /// 退回默认的「不可用」实现，之后 [ensureDefaultProvider] 会重新检测。主要给测试用。
  static void reset() {
    _provider = const UnavailableRealtimeAsrProvider();
    _isCustomProvider = false;
    _defaultProviderInstall = null;
  }
}

/// 默认实现：永远不可用，[createSession] 不会被调用。
class UnavailableRealtimeAsrProvider extends RealtimeAsrProvider {
  const UnavailableRealtimeAsrProvider();

  @override
  bool get isAvailable => false;

  @override
  RealtimeAsrSession createSession({String language = ''}) {
    throw UnsupportedError(
      'Realtime ASR is not available. Set RealtimeAsr.provider first.',
    );
  }
}

/// 基于原生实时采集 + IMSDK 实验接口的实现，由 [RealtimeAsr.ensureDefaultProvider]
/// 在设备支持时装上。
class ImRealtimeAsrProvider extends RealtimeAsrProvider {
  const ImRealtimeAsrProvider();

  @override
  bool get isAvailable => true;

  @override
  RealtimeAsrSession createSession({String language = ''}) {
    return RealtimeAsrRecognizer(language: language);
  }
}
