import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import VideoRecorderHelper, {
  VideoRecordMediaKind,
  VideoRecordResult,
} from './VideoRecorderHelper';

/**
 * OHOS 端 video_recorder channel bridge。
 * Dart 契约(见 video_recorder_platform.dart):
 *   MethodChannel : 'tencent_chat_uikit/video_recorder'
 *     startRecord({recordMode, videoQuality, minDurationMs, maxDurationMs,
 *                  isDefaultFrontCamera, isSupportEdit, isSupportBeauty, ...,
 *                  primaryColor, languageCode, countryCode, scriptCode})
 *       ->  ⚠ 异步返回,只有系统相机 picker 关闭时才 result.success(map):
 *           - photo:  { type: 'photo', filePath }
 *           - video:  { type: 'video', filePath, durationMs, thumbnailPath }
 *           - cancel: { type: 'video', filePath: '' }
 *             (Dart 上层 message_input._onTakeVideo 用 `result.filePath.isEmpty` 判断取消,
 *              这样比 result.error 更简单,不用 try/catch)
 *
 * 与 Android 版差异:
 *   - Android 用 VideoRecorderActivity 自绘录制 UI + 支持美颜/滤镜/编辑等
 *   - OHOS 用系统 cameraPicker,不支持美颜/编辑/多档画质,这些参数(videoQuality/
 *     isSupportBeauty 等)当前全部忽略,只吃 recordMode + isDefaultFrontCamera
 *   - 权限:cameraPicker 是系统组件,拉起时自己会走 CAMERA/MIC 授权流程,
 *     加上 Dart 上层已经先 Permission.checkAndRequest([camera]),不用二次申请
 */
export default class VideoRecorder implements MethodCallHandler, AbilityAware {
  private static readonly TAG = 'ChatUiKit.VideoRecorder';
  private static readonly CHANNEL_NAME = 'tencent_chat_uikit/video_recorder';

  private channel: MethodChannel | null = null;
  private uiAbilityContext: common.UIAbilityContext | null = null;
  private cacheDir: string = '';

  constructor(binding: FlutterPluginBinding) {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), VideoRecorder.CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    try {
      this.cacheDir = binding.getApplicationContext().cacheDir;
    } catch (e) {
      console.warn(`${VideoRecorder.TAG} read cacheDir failed`, (e as Error).message);
    }
  }

  // ----- AbilityAware -----
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.uiAbilityContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.uiAbilityContext = null;
  }

  // ----- MethodCallHandler -----
  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'startRecord') {
      this.handleStartRecord(call, result);
      return;
    }
    result.notImplemented();
  }

  private handleStartRecord(call: MethodCall, result: MethodResult): void {
    const ctx = this.uiAbilityContext;
    if (ctx === null) {
      console.warn(`${VideoRecorder.TAG} startRecord called but no UIAbilityContext`);
      result.error('NO_ABILITY', 'UIAbilityContext not attached', null);
      return;
    }

    const recordModeRaw = call.argument('recordMode') as number | null;
    const recordMode = recordModeRaw === null || recordModeRaw === undefined ? 0 : recordModeRaw;
    const defaultFrontRaw = call.argument('isDefaultFrontCamera') as boolean | null;
    const defaultFront = defaultFrontRaw === null || defaultFrontRaw === undefined ? false : defaultFrontRaw;

    VideoRecorderHelper.takeMedia(recordMode, defaultFront, ctx, this.cacheDir).then(
      (r: VideoRecordResult) => {
        result.success(this.buildResultMap(r));
      },
    ).catch((e: Error) => {
      console.error(`${VideoRecorder.TAG} takeMedia threw`, e.message);
      // 意外异常也走 cancel(空 filePath),Dart 上层 return 即可,不弹错误弹窗
      result.success(this.buildResultMap({
        mediaKind: VideoRecordMediaKind.CANCEL,
        filePath: '',
        durationMs: 0,
        thumbnailPath: '',
      }));
    });
  }

  private buildResultMap(r: VideoRecordResult): Record<string, ESObject> {
    if (r.mediaKind === VideoRecordMediaKind.PHOTO) {
      const map: Record<string, ESObject> = {
        'type': 'photo',
        'filePath': r.filePath,
      };
      return map;
    }
    // VIDEO 或 CANCEL 都走 video 分支,cancel 时 filePath 是空串
    const map: Record<string, ESObject> = {
      'type': 'video',
      'filePath': r.filePath,
      'durationMs': r.durationMs,
      'thumbnailPath': r.thumbnailPath,
    };
    return map;
  }

  dispose(): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.uiAbilityContext = null;
  }
}
