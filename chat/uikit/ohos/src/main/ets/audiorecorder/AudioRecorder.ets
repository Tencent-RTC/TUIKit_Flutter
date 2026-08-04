import {
  AbilityAware,
  AbilityPluginBinding,
  EventChannel,
  EventSink,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import AudioRecorderHelper, {
  RecordCompletionListener,
  RecordProgressListener,
  RecordResultCode,
} from './AudioRecorderHelper';

/**
 * OHOS 端 audio_recorder channel bridge。
 * Dart 契约(见 audio_recorder_platform.dart):
 *   MethodChannel : 'tencent_chat_uikit/audio_recorder'
 *     startRecord({filepath, enableAIDeNoise, minDurationMs, maxDurationMs})
 *       ->  ⚠ 异步返回,只有 stop/cancel/超时/失败发生时才 result.success(map),
 *           map = { resultCode: int, filePath: string?, durationMs: int }
 *     stopRecord()   -> null    (触发录音结束流程,startRecord 那次调用才 return)
 *     cancelRecord() -> null    (触发取消,startRecord 那次 return errorCancel)
 *   EventChannel  : 'tencent_chat_uikit/audio_recorder_events'
 *     { type: 'recordTime',  timeMs: int }
 *     { type: 'powerLevel',  powerLevel: int }   ← 鸿蒙暂不发,harmony 端也未实现
 *
 * 需要 UIAbilityContext:麦克风权限 checkAccessToken 不需要,但 helper 保留了
 * requestPermissionsFromUser 的可能性,先把 context 传下去。
 * ApplicationContext.cacheDir 用作默认录音存放目录。
 */
export default class AudioRecorder implements
  MethodCallHandler,
  StreamHandler,
  AbilityAware,
  RecordProgressListener,
  RecordCompletionListener {
  private static readonly TAG = 'ChatUiKit.AudioRecorder';
  private static readonly METHOD_CHANNEL_NAME = 'tencent_chat_uikit/audio_recorder';
  private static readonly EVENT_CHANNEL_NAME = 'tencent_chat_uikit/audio_recorder_events';

  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;
  private uiAbilityContext: common.UIAbilityContext | null = null;
  private cacheDir: string = '';
  /** 挂起的 startRecord 调用的 MethodResult;录音真正结束时 result.success(map)。 */
  private pendingResult: MethodResult | null = null;

  constructor(binding: FlutterPluginBinding) {
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), AudioRecorder.METHOD_CHANNEL_NAME);
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), AudioRecorder.EVENT_CHANNEL_NAME);
    this.eventChannel.setStreamHandler(this);
    try {
      this.cacheDir = binding.getApplicationContext().cacheDir;
    } catch (e) {
      console.warn(`${AudioRecorder.TAG} read cacheDir failed`, (e as Error).message);
    }
  }

  // ----- AbilityAware -----
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.uiAbilityContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.uiAbilityContext = null;
  }

  // ----- StreamHandler -----
  onListen(args: ESObject, events: EventSink): void {
    this.eventSink = events;
  }

  onCancel(args: ESObject): void {
    this.eventSink = null;
  }

  // ----- RecordProgressListener (来自 helper,每个进度 tick 触发) -----
  onRecordTime(timeMs: number): void {
    this.emit({ 'type': 'recordTime', 'timeMs': timeMs });
  }

  onPowerLevel(powerLevel: number): void {
    this.emit({ 'type': 'powerLevel', 'powerLevel': powerLevel });
  }

  // ----- RecordCompletionListener (来自 helper,录音结束一次性触发) -----
  // 兑现 startRecord 挂起的 MethodResult。
  onCompleted(code: RecordResultCode, filePath: string | null, durationMs: number): void {
    const r = this.pendingResult;
    this.pendingResult = null;
    if (r === null) {
      return;
    }
    r.success(this.buildResultMap(code, filePath, durationMs));
  }

  // ----- MethodCallHandler -----
  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'startRecord':
        this.handleStartRecord(call, result);
        return;
      case 'stopRecord':
        this.handleStopRecord(result);
        return;
      case 'cancelRecord':
        this.handleCancelRecord(result);
        return;
      default:
        result.notImplemented();
    }
  }

  private handleStartRecord(call: MethodCall, result: MethodResult): void {
    // 如果上一次 startRecord 的 result 还没兑现,先把它按 cancel 兑现,避免 leak MethodResult
    if (this.pendingResult !== null) {
      console.warn(`${AudioRecorder.TAG} previous startRecord pending, force-canceling`);
      const stale = this.pendingResult;
      this.pendingResult = null;
      stale.success(this.buildResultMap(RecordResultCode.ERROR_CANCEL, null, 0));
      // 也尝试 cancel 录音机,以防仍在录
      AudioRecorderHelper.shared().cancelRecord().catch((e: Error) => {
        console.warn(`${AudioRecorder.TAG} force-cancel prev failed`, e.message);
      });
    }

    const filepath = call.argument('filepath') as string | null;
    const enableAIDeNoiseRaw = call.argument('enableAIDeNoise') as boolean | null;
    const minRaw = call.argument('minDurationMs') as number | null;
    const maxRaw = call.argument('maxDurationMs') as number | null;
    const enableAIDeNoise = enableAIDeNoiseRaw === null ? false : enableAIDeNoiseRaw;
    const minMs = minRaw === null || minRaw === undefined ? 1000 : minRaw;
    const maxMs = maxRaw === null || maxRaw === undefined ? 60000 : maxRaw;

    this.pendingResult = result;

    // ArkTS 严格模式禁止匿名 object literal(arkts-no-untyped-obj-literals),
    // 所以 handler 类自己 implements 两个 listener interface,把 this 直接传下去。
    // 见文件顶部 AudioRecorder 的 implements 列表。
    AudioRecorderHelper.shared().startRecord({
      filepath: filepath,
      enableAIDeNoise: enableAIDeNoise,
      minDurationMs: minMs,
      maxDurationMs: maxMs,
      cacheDir: this.cacheDir,
      uiAbilityContext: this.uiAbilityContext,
      progress: this,
      completion: this,
    }).catch((e: Error) => {
      console.error(`${AudioRecorder.TAG} startRecord threw`, e.message);
      const r = this.pendingResult;
      this.pendingResult = null;
      if (r !== null) {
        r.success(this.buildResultMap(RecordResultCode.ERROR_RECORD_INNER_FAIL, null, 0));
      }
    });
  }

  private handleStopRecord(result: MethodResult): void {
    // stopRecord 只是发命令,startRecord 的 result 会在 completion 里兑现
    AudioRecorderHelper.shared().stopRecord().then(() => {
      result.success(null);
    }).catch((e: Error) => {
      console.warn(`${AudioRecorder.TAG} stopRecord failed`, e.message);
      result.success(null);
    });
  }

  private handleCancelRecord(result: MethodResult): void {
    AudioRecorderHelper.shared().cancelRecord().then(() => {
      result.success(null);
    }).catch((e: Error) => {
      console.warn(`${AudioRecorder.TAG} cancelRecord failed`, e.message);
      result.success(null);
    });
  }

  private buildResultMap(
    code: RecordResultCode,
    filePath: string | null,
    durationMs: number,
  ): Record<string, ESObject> {
    const map: Record<string, ESObject> = {
      'resultCode': code as number,
      'filePath': filePath,
      'durationMs': durationMs,
    };
    return map;
  }

  private emit(payload: Record<string, ESObject>): void {
    const sink = this.eventSink;
    if (sink === null) {
      return;
    }
    sink.success(payload);
  }

  dispose(): void {
    if (this.methodChannel !== null) {
      this.methodChannel.setMethodCallHandler(null);
      this.methodChannel = null;
    }
    this.eventChannel = null;
    this.eventSink = null;
    this.uiAbilityContext = null;
    // 若有正在录音,发个 cancel 兜底
    if (this.pendingResult !== null) {
      const r = this.pendingResult;
      this.pendingResult = null;
      r.success(this.buildResultMap(RecordResultCode.ERROR_CANCEL, null, 0));
    }
    AudioRecorderHelper.shared().cancelRecord().catch((e: Error) => {
      console.warn(`${AudioRecorder.TAG} dispose cancel failed`, e.message);
    });
  }
}
