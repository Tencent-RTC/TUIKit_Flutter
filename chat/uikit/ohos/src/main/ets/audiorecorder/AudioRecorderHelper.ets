import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';

/**
 * OHOS 端 audio 录音核心工具类。
 * 从 harmony/atomic_x/audiorecorder/components/AudioRecorder.ets 复用并扩展:
 *   1. 加了 min/max duration 参数(原实现硬编码 1s / 60s)
 *   2. 加了 filepath 参数,允许 Dart 侧传入指定路径,否则内部生成
 *   3. 录音结果通过 CompletionListener.onCompleted(resultCode, path, durationMs) 返回,
 *      对齐 Android AudioRecorderHandler 的 result payload。
 *   4. powerLevel: harmony 端 media.AVRecorder 无原生 API 拿实时音量,先不发。
 *
 * ResultCode 定义与 Dart AudioRecordResultCode 一一对齐:
 *   success                      =  0
 *   successExceedMaxDuration     =  1
 *   errorCancel                  = -1
 *   errorRecording               = -2  (通用录音失败)
 *   errorStorageUnavailable      = -3
 *   errorLessThanMinDuration     = -4
 *   errorRecordInnerFail         = -5
 *   errorRecordPermissionDenied  = -6
 */

export enum RecordResultCode {
  SUCCESS = 0,
  SUCCESS_EXCEED_MAX_DURATION = 1,
  ERROR_CANCEL = -1,
  ERROR_RECORDING = -2,
  ERROR_STORAGE_UNAVAILABLE = -3,
  ERROR_LESS_THAN_MIN_DURATION = -4,
  ERROR_RECORD_INNER_FAIL = -5,
  ERROR_RECORD_PERMISSION_DENIED = -6,
}

export interface RecordProgressListener {
  /** 录音时长回调,timeMs 累计毫秒。 */
  onRecordTime?(timeMs: number): void;
  /** 音量等级回调,鸿蒙暂未实现,保留接口。 */
  onPowerLevel?(powerLevel: number): void;
}

export interface RecordCompletionListener {
  onCompleted(resultCode: RecordResultCode, filePath: string | null, durationMs: number): void;
}

interface RecordConfig {
  filepath: string | null;
  enableAIDeNoise: boolean;
  minDurationMs: number;
  maxDurationMs: number;
  cacheDir: string;                        // 生成 filepath 时用
  uiAbilityContext: common.UIAbilityContext | null;   // 用来查权限
  progress: RecordProgressListener | null;
  completion: RecordCompletionListener;
}

export default class AudioRecorderHelper {
  private static readonly TAG = 'ChatUiKit.AudioRecorderHelper';
  private static readonly PROGRESS_INTERVAL_MS = 200;
  private static readonly MIC_PERM: Permissions = 'ohos.permission.MICROPHONE';

  private static _instance: AudioRecorderHelper | null = null;
  static shared(): AudioRecorderHelper {
    if (AudioRecorderHelper._instance === null) {
      AudioRecorderHelper._instance = new AudioRecorderHelper();
    }
    return AudioRecorderHelper._instance;
  }

  private avRecorder: media.AVRecorder | null = null;
  private audioFile: fs.File | null = null;
  private recordingFilePath: string = '';
  private isRecording: boolean = false;
  private recordingStartTs: number = 0;   // Date.now() 值,精确计时
  private recordingDurationMs: number = 0;
  private progressTimerId: number = -1;
  private progress: RecordProgressListener | null = null;
  private completion: RecordCompletionListener | null = null;
  private currentConfig: RecordConfig | null = null;
  /** 保证 completion 只被 fire 一次,stop 和 timeout 竞争 */
  private completionFired: boolean = false;

  async startRecord(config: RecordConfig): Promise<void> {
    if (this.isRecording) {
      console.warn(`${AudioRecorderHelper.TAG} already recording, reject start`);
      config.completion.onCompleted(RecordResultCode.ERROR_RECORDING, null, 0);
      return;
    }

    this.currentConfig = config;
    this.progress = config.progress;
    this.completion = config.completion;
    this.completionFired = false;
    this.recordingDurationMs = 0;

    // 1) 权限:Dart 上层调用前已经 Permission.checkAndRequest(microphone),
    //    这里只 check,授权被撤销时才走 -6 分支。
    const hasPerm = await this.checkMicPermission();
    if (!hasPerm) {
      this.fireCompletion(RecordResultCode.ERROR_RECORD_PERMISSION_DENIED, null, 0);
      return;
    }

    // 2) 目标文件路径
    try {
      this.recordingFilePath = this.resolveTargetPath(config.filepath, config.cacheDir);
      await this.ensureParentDir(this.recordingFilePath);
      this.audioFile = fs.openSync(
        this.recordingFilePath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE,
      );
    } catch (e) {
      console.error(`${AudioRecorderHelper.TAG} prepare file failed`, (e as BusinessError).message);
      this.fireCompletion(RecordResultCode.ERROR_STORAGE_UNAVAILABLE, null, 0);
      return;
    }

    // 3) 创建 AVRecorder,准备参数
    try {
      this.avRecorder = await media.createAVRecorder();
      this.setupRecorderCallbacks();
      const avConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: {
          audioBitrate: 100000,
          audioChannels: 1,
          audioCodec: media.CodecMimeType.AUDIO_AAC,
          audioSampleRate: 16000,
          fileFormat: media.ContainerFormatType.CFT_MPEG_4A,
        },
        url: `fd://${this.audioFile.fd}`,
      };
      await this.avRecorder.prepare(avConfig);
      await this.avRecorder.start();
    } catch (e) {
      console.error(`${AudioRecorderHelper.TAG} start failed`, (e as BusinessError).message);
      await this.cleanupRecorder();
      this.fireCompletion(RecordResultCode.ERROR_RECORD_INNER_FAIL, null, 0);
      return;
    }

    // 4) 状态置位 + 计时
    this.isRecording = true;
    this.recordingStartTs = Date.now();
    this.startProgressTracking(config.maxDurationMs);
  }

  /** 用户主动停止(松开语音键)。产生成功结果或时长过短结果。 */
  async stopRecord(): Promise<void> {
    if (!this.isRecording) {
      console.warn(`${AudioRecorderHelper.TAG} stopRecord called but not recording`);
      return;
    }
    await this.finishAndEmit(false);
  }

  /** 用户取消(上滑取消)。产生 -1 cancel 结果并删除录音文件。 */
  async cancelRecord(): Promise<void> {
    if (!this.isRecording) {
      return;
    }
    this.isRecording = false;
    this.stopProgressTracking();
    await this.cleanupRecorder();
    await this.deleteRecordingFile();
    this.fireCompletion(RecordResultCode.ERROR_CANCEL, null, 0);
  }

  // ---- private ----

  /**
   * 收尾流程:stop AVRecorder + 判定 min duration + 触发 completion。
   * @param exceededMax 是否是因为达到 maxDurationMs 自动结束
   */
  private async finishAndEmit(exceededMax: boolean): Promise<void> {
    this.isRecording = false;
    this.stopProgressTracking();

    const finalDurationMs = this.recordingDurationMs > 0
      ? this.recordingDurationMs
      : (Date.now() - this.recordingStartTs);

    // 先落盘 stop + release,再判定 min duration,否则 avRecorder 内部资源没释放
    let stopOk = true;
    try {
      const r = this.avRecorder;
      if (r !== null && (r.state === 'started' || r.state === 'paused')) {
        await r.stop();
      }
    } catch (e) {
      stopOk = false;
      console.warn(`${AudioRecorderHelper.TAG} stop() failed`, (e as BusinessError).message);
    }
    await this.cleanupRecorder();

    const minMs = this.currentConfig?.minDurationMs ?? 1000;
    if (finalDurationMs < minMs) {
      await this.deleteRecordingFile();
      this.fireCompletion(RecordResultCode.ERROR_LESS_THAN_MIN_DURATION, null, finalDurationMs);
      return;
    }
    if (!stopOk) {
      // stop 失败:结果文件可能已经写了大部分,但为了保守起见按 inner fail 处理
      this.fireCompletion(RecordResultCode.ERROR_RECORD_INNER_FAIL, null, finalDurationMs);
      return;
    }
    const code = exceededMax
      ? RecordResultCode.SUCCESS_EXCEED_MAX_DURATION
      : RecordResultCode.SUCCESS;
    this.fireCompletion(code, this.recordingFilePath, finalDurationMs);
  }

  private setupRecorderCallbacks(): void {
    const r = this.avRecorder;
    if (r === null) {
      return;
    }
    r.on('error', (err: BusinessError) => {
      console.error(`${AudioRecorderHelper.TAG} avRecorder error`, err.message);
      // 走 cancel 语义,清理资源并回调 inner fail
      this.isRecording = false;
      this.stopProgressTracking();
      this.cleanupRecorder().finally(() => {
        this.deleteRecordingFile().finally(() => {
          this.fireCompletion(RecordResultCode.ERROR_RECORD_INNER_FAIL, null, 0);
        });
      });
    });
  }

  private startProgressTracking(maxDurationMs: number): void {
    this.stopProgressTracking();
    this.progressTimerId = setInterval(() => {
      if (!this.isRecording) {
        return;
      }
      const elapsed = Date.now() - this.recordingStartTs;
      this.recordingDurationMs = elapsed;
      this.progress?.onRecordTime?.(elapsed);
      if (elapsed >= maxDurationMs) {
        // 到达上限,自动 stop 并给 exceedMax 结果
        this.finishAndEmit(true).catch((e: Error) => {
          console.warn(`${AudioRecorderHelper.TAG} auto stop on max duration failed`, e.message);
        });
      }
    }, AudioRecorderHelper.PROGRESS_INTERVAL_MS);
  }

  private stopProgressTracking(): void {
    if (this.progressTimerId !== -1) {
      clearInterval(this.progressTimerId);
      this.progressTimerId = -1;
    }
  }

  private async cleanupRecorder(): Promise<void> {
    const r = this.avRecorder;
    this.avRecorder = null;
    if (r !== null) {
      try {
        const state = r.state;
        if (state !== 'idle' && state !== 'released') {
          try {
            await r.reset();
          } catch (e) {
            console.warn(`${AudioRecorderHelper.TAG} reset failed`, (e as BusinessError).message);
          }
        }
        await r.release();
      } catch (e) {
        console.warn(`${AudioRecorderHelper.TAG} release failed`, (e as BusinessError).message);
      }
    }
    const f = this.audioFile;
    this.audioFile = null;
    if (f !== null) {
      try {
        fs.closeSync(f);
      } catch (e) {
        console.warn(`${AudioRecorderHelper.TAG} close fd failed`, (e as BusinessError).message);
      }
    }
  }

  private async deleteRecordingFile(): Promise<void> {
    if (this.recordingFilePath.length === 0) {
      return;
    }
    try {
      if (fs.accessSync(this.recordingFilePath)) {
        fs.unlinkSync(this.recordingFilePath);
      }
    } catch (e) {
      console.warn(`${AudioRecorderHelper.TAG} unlink recording failed`,
        (e as BusinessError).message);
    }
    this.recordingFilePath = '';
  }

  private fireCompletion(
    code: RecordResultCode,
    filePath: string | null,
    durationMs: number,
  ): void {
    if (this.completionFired) {
      return;
    }
    this.completionFired = true;
    const cb = this.completion;
    this.completion = null;
    this.progress = null;
    this.currentConfig = null;
    cb?.onCompleted(code, filePath, durationMs);
  }

  private resolveTargetPath(preferred: string | null, cacheDir: string): string {
    if (preferred !== null && preferred.length > 0) {
      return preferred;
    }
    const timestamp = Date.now();
    const rand = Math.floor(Math.random() * 1e6);
    return `${cacheDir}/audio_recorder/voice_${timestamp}_${rand}.m4a`;
  }

  private async ensureParentDir(filePath: string): Promise<void> {
    const idx = filePath.lastIndexOf('/');
    if (idx <= 0) {
      return;
    }
    const dir = filePath.substring(0, idx);
    try {
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
    } catch (e) {
      console.warn(`${AudioRecorderHelper.TAG} mkdir failed ${dir}`,
        (e as BusinessError).message);
    }
  }

  /**
   * 只 check 不 request。Dart 上层在打开录音面板前已经 checkAndRequest 过一次,
   * 此处 fail 说明用户在设置里撤销了权限,给一个明确的 -6 结果。
   */
  private async checkMicPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const info = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
      );
      const status = await atManager.checkAccessToken(info.appInfo.accessTokenId, AudioRecorderHelper.MIC_PERM);
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (e) {
      console.warn(`${AudioRecorderHelper.TAG} checkMicPermission failed`,
        (e as BusinessError).message);
      return false;
    }
  }
}
