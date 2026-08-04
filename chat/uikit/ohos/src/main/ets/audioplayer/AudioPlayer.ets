import {
  EventChannel,
  EventSink,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler,
} from '@ohos/flutter_ohos';
import AudioPlayerHelper, { AudioPlayerListener } from './AudioPlayerHelper';

/**
 * OHOS 端 audio_player channel bridge。
 * Dart 契约(见 audio_player_platform.dart):
 *   MethodChannel : 'tencent_chat_uikit/audio_player'
 *     play({filePath}) -> null       (启动播放,状态通过 event 回调)
 *     pause()          -> null
 *     resume()         -> null
 *     stop()           -> null
 *     getCurrentPosition() -> int(ms)
 *     getDuration()        -> int(ms)
 *     isPlaying()          -> bool
 *     isPaused()           -> bool
 *   EventChannel  : 'tencent_chat_uikit/audio_player_events'
 *     { type: 'onPlay' }
 *     { type: 'onPause' }
 *     { type: 'onResume' }
 *     { type: 'onProgressUpdate', currentPosition, duration }   ← Dart 期望 int(ms)
 *     { type: 'onComplete' }                                     ← 注意 Dart 是 onComplete,helper listener 是 onCompletion
 *     { type: 'onError', errorMessage }
 *
 * AudioPlayerHelper 是进程单例,handler 只做转发。
 */
export default class AudioPlayer implements MethodCallHandler, StreamHandler, AudioPlayerListener {
  private static readonly TAG = 'ChatUiKit.AudioPlayer';
  private static readonly METHOD_CHANNEL_NAME = 'tencent_chat_uikit/audio_player';
  private static readonly EVENT_CHANNEL_NAME = 'tencent_chat_uikit/audio_player_events';

  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;

  constructor(binding: FlutterPluginBinding) {
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), AudioPlayer.METHOD_CHANNEL_NAME);
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), AudioPlayer.EVENT_CHANNEL_NAME);
    this.eventChannel.setStreamHandler(this);
    // 把自己注册为 helper 的 listener,event 单向流出
    AudioPlayerHelper.shared().setListener(this);
  }

  // ----- StreamHandler -----
  onListen(args: ESObject, events: EventSink): void {
    this.eventSink = events;
  }

  onCancel(args: ESObject): void {
    this.eventSink = null;
  }

  // ----- AudioPlayerListener (来自 helper) -----
  onPlay(): void {
    this.emit({ 'type': 'onPlay' });
  }

  onPause(): void {
    this.emit({ 'type': 'onPause' });
  }

  onResume(): void {
    this.emit({ 'type': 'onResume' });
  }

  onProgressUpdate(currentPositionMs: number, durationMs: number): void {
    this.emit({
      'type': 'onProgressUpdate',
      'currentPosition': currentPositionMs,
      'duration': durationMs,
    });
  }

  onCompletion(): void {
    // Dart 侧 type 键为 'onComplete',与 helper 里的方法名有一个字母差
    this.emit({ 'type': 'onComplete' });
  }

  onError(errorMessage: string): void {
    this.emit({
      'type': 'onError',
      'errorMessage': errorMessage,
    });
  }

  private emit(payload: Record<string, ESObject>): void {
    const sink = this.eventSink;
    if (sink === null) {
      // Dart 侧还没来得及 listen 就已产生事件是有可能的(比如 stop 前 dispose)
      return;
    }
    sink.success(payload);
  }

  // ----- MethodCallHandler -----
  onMethodCall(call: MethodCall, result: MethodResult): void {
    const helper = AudioPlayerHelper.shared();
    switch (call.method) {
      case 'play': {
        const filePath = call.argument('filePath') as string | null;
        if (filePath === null || filePath === undefined || filePath.length === 0) {
          result.error('INVALID_ARGUMENTS', 'filePath is required', null);
          return;
        }
        helper.play(filePath).then(() => {
          result.success(null);
        }).catch((e: Error) => {
          console.error(`${AudioPlayer.TAG} play failed`, e.message);
          result.success(null); // 错误通过 onError 事件走
        });
        return;
      }
      case 'pause':
        helper.pause().then(() => result.success(null)).catch((e: Error) => {
          console.warn(`${AudioPlayer.TAG} pause failed`, e.message);
          result.success(null);
        });
        return;
      case 'resume':
        helper.resume().then(() => result.success(null)).catch((e: Error) => {
          console.warn(`${AudioPlayer.TAG} resume failed`, e.message);
          result.success(null);
        });
        return;
      case 'stop':
        helper.stop().then(() => result.success(null)).catch((e: Error) => {
          console.warn(`${AudioPlayer.TAG} stop failed`, e.message);
          result.success(null);
        });
        return;
      case 'getCurrentPosition':
        result.success(helper.getCurrentPosition());
        return;
      case 'getDuration':
        result.success(helper.getDuration());
        return;
      case 'isPlaying':
        result.success(helper.isPlaying());
        return;
      case 'isPaused':
        result.success(helper.isPaused());
        return;
      default:
        result.notImplemented();
    }
  }

  dispose(): void {
    if (this.methodChannel !== null) {
      this.methodChannel.setMethodCallHandler(null);
      this.methodChannel = null;
    }
    // EventChannel.setStreamHandler 类型不接受 null,engine 断开时 messenger 已回收,只清引用
    this.eventChannel = null;
    this.eventSink = null;
    // 卸载 listener,避免 helper 单例持有已 dispose 的 handler
    AudioPlayerHelper.shared().setListener(null);
    // 顺手 stop 掉,避免 hot restart 时 avPlayer 泄漏
    AudioPlayerHelper.shared().stop().catch((e: Error) => {
      console.warn(`${AudioPlayer.TAG} dispose stop failed`, e.message);
    });
  }
}
