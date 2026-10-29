/// 长按录音实时识别的固定参数。
///
/// 音频格式由 IMSDK 实时识别接口规定：Opus / 16kHz / 单声道 / 裸 packet。
class RealtimeAsrSpec {
  RealtimeAsrSpec._();

  static const int sampleRate = 16000;
  static const int channelCount = 1;

  /// 20ms @ 16kHz
  static const int frameSamples = 320;
  static const int frameDurationMs = 20;

  /// 每 5 帧（100ms）上行一次，兼顾识别延迟与调用频率。
  static const int uploadBatchFrames = 5;

  /// 补推积压音频时，单次上行最多带这么多帧（100 帧 = 2 秒）。
  ///
  /// 会话就绪时要把 [preRollCapacity] 那点缓冲一次推完。全塞进一个请求失败了整段一起丢；
  /// 照实时节奏按 [uploadBatchFrames] 切又会一次性打出上百个请求。切出来的几片是并行在飞的。
  static const int uploadMaxFramesPerCall = 100;

  /// 按下就把音频推上去，而不是等手指滑到「转文字」。
  ///
  /// 必须为 true：后台只按实时语速出字，滑过去再把攒下的整段补推，换不来对应的文本。
  /// 代价是每一次长按都真的走一遍 ASR，哪怕用户只是想发条语音。
  static const bool uploadFromPress = true;

  /// startRealtimeTranscriber 迟迟不回时放弃本次识别，回落到「上传整段音频再识别」。
  static const int startTimeoutMs = 5000;

  /// 上行开关打开前的音频缓冲上界：盖住建会话那一个往返，再多给 1 秒余量。
  ///
  /// 不要按整段录音时长来定：后台不会加速消化突发音频，攒得再多也换不来文字。
  static const int preRollCapacity = (startTimeoutMs + 1000) ~/ frameDurationMs;

  /// 松手后等最后一批音频 ack 完再 stop 的上限。
  ///
  /// stop 一到服务端就把会话关掉，和它并发在飞的上行会撞上 `140002 session is closed`，
  /// 松手前最后那几十毫秒的音频就丢了。后台不回话时宁可关掉会话也不能卡着不发。
  static const int tailUploadTimeoutMs = 400;

  /// stop 之后等尾句结果的收尾窗口。
  ///
  /// 不能拿 stop 的回调当结束信号：它只是「会话已关闭」的 ack，不代表结果都到齐了。
  /// 真正的结束信号是带 isFinished 的那条响应，这里是它不来时的兜底。
  static const int drainTimeoutMs = 800;
}
