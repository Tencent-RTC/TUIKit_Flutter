import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';

/**
 * OHOS 端 audio 播放核心工具类。
 * 完整复用 harmony/atomic_x/audioplayer/utils/AudioPlayer.ets 的 MediaAudioPlayer 实现,
 * 差异:
 *   1. 单例(global),chat 会话内同时只允许一个音频在放,方便 Dart 上层做互斥。
 *   2. progress 用 setInterval 而不是递归 setTimeout,避免 stop 后残留一次触发。
 *   3. play 时如果传入的 filePath 与当前正在播放的一致,直接 resume 避免重开 fd。
 *
 * AVPlayer 状态机链路:
 *   setSource(url=fd://) -> initialized -> prepare -> prepared -> play -> playing
 *   pause/resume/stop/completed 都靠 stateChange 回调驱动 listener。
 */

export interface AudioPlayerListener {
  onPlay?(): void;
  onPause?(): void;
  onResume?(): void;
  onProgressUpdate?(currentPositionMs: number, durationMs: number): void;
  onCompletion?(): void;
  onError?(errorMessage: string): void;
}

export default class AudioPlayerHelper {
  private static readonly TAG = 'ChatUiKit.AudioPlayerHelper';
  private static readonly PROGRESS_INTERVAL_MS = 200;

  private static _instance: AudioPlayerHelper | null = null;
  static shared(): AudioPlayerHelper {
    if (AudioPlayerHelper._instance === null) {
      AudioPlayerHelper._instance = new AudioPlayerHelper();
    }
    return AudioPlayerHelper._instance;
  }

  private avPlayer: media.AVPlayer | null = null;
  private srcFile: fs.File | null = null;
  private _isPlaying: boolean = false;
  private _isPaused: boolean = false;
  private currentDuration: number = 0;
  private currentPosition: number = 0;
  private listener: AudioPlayerListener | null = null;
  private progressTimerId: number = -1;

  setListener(listener: AudioPlayerListener | null): void {
    this.listener = listener;
  }

  async play(filePath: string): Promise<void> {
    try {
      // 若当前有播放器,先彻底 release 掉,避免 stateChange 事件混淆
      if (this.avPlayer !== null) {
        await this.stop();
      }

      this.avPlayer = await media.createAVPlayer();
      this.setupAVPlayerCallbacks();

      // 分两种 source:
      //   1) http(s):// —— TTS 朗读、AI 翻译语音等,后端下发临时签名 URL,
      //      AVPlayer 原生支持,直接赋给 url,由播放器内部走网络加载。
      //   2) 本地绝对路径 —— IMSDK 缓存的语音消息文件,fs.open 拿 fd 后走 fd:// 播放,
      //      fd 的所有权在 stop() 里 close,避免泄漏。
      if (AudioPlayerHelper.isNetworkUrl(filePath)) {
        this.avPlayer.url = filePath;
      } else {
        try {
          this.srcFile = await fs.open(filePath, fs.OpenMode.READ_ONLY);
        } catch (e) {
          this.emitError(`can not open file: ${filePath}, ${(e as BusinessError).message}`);
          // 失败时必须把刚创建的 avPlayer 释放掉,否则下次 play 时残留 state 会崩
          await this.stop();
          return;
        }
        this.avPlayer.url = `fd://${this.srcFile.fd}`;
      }
      // 从这里开始 AVPlayer 会自动流转到 initialized -> prepared -> playing,
      // 见 setupAVPlayerCallbacks.stateChange 里的处理。
    } catch (e) {
      this.emitError(`play error: ${(e as Error).message}`);
      // 兜底:任何异常都要清理已创建的 avPlayer,防止状态残留导致下次 play 崩
      await this.stop().catch((se: Error) => {
        console.warn(`${AudioPlayerHelper.TAG} stop after play error failed`, se.message);
      });
    }
  }

  private static isNetworkUrl(path: string): boolean {
    const lower = path.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  async pause(): Promise<void> {
    if (this.avPlayer !== null && this._isPlaying) {
      try {
        await this.avPlayer.pause();
      } catch (e) {
        this.emitError(`pause error: ${(e as BusinessError).message}`);
      }
    }
  }

  async resume(): Promise<void> {
    if (this.avPlayer !== null && this._isPaused) {
      try {
        await this.avPlayer.play();
      } catch (e) {
        this.emitError(`resume error: ${(e as BusinessError).message}`);
      }
    }
  }

  async stop(): Promise<void> {
    this.stopProgressTracking();
    const player = this.avPlayer;
    this.avPlayer = null;
    this._isPlaying = false;
    this._isPaused = false;
    this.currentPosition = 0;

    if (player !== null) {
      // ⚠ 关键:先 off 掉 stateChange / error,避免 release 过程中
      // 老 player 触发 'released' 事件,回调里 `this.avPlayer = null`
      // 会把已被下一次 play() 创建的新 player 也置空,导致后续 play 时崩溃。
      try {
        player.off('stateChange');
        player.off('error');
      } catch (_) {
        // off 失败无关紧要,继续走 stop/release
      }
      try {
        // 只有非 idle/released 状态才需要 stop
        const state = player.state;
        if (state !== 'idle' && state !== 'released') {
          await player.stop();
        }
        await player.release();
      } catch (e) {
        console.warn(`${AudioPlayerHelper.TAG} stop/release failed`, (e as BusinessError).message);
      }
    }

    // fd 在 player.release 后才安全关掉,不然 AVPlayer 内部还在读
    const f = this.srcFile;
    this.srcFile = null;
    if (f !== null) {
      try {
        fs.closeSync(f);
      } catch (e) {
        console.warn(`${AudioPlayerHelper.TAG} close(fd) failed`, (e as BusinessError).message);
      }
    }
  }

  isPlaying(): boolean {
    return this._isPlaying;
  }

  isPaused(): boolean {
    return this._isPaused;
  }

  getCurrentPosition(): number {
    return this.currentPosition;
  }

  getDuration(): number {
    return this.currentDuration;
  }

  private setupAVPlayerCallbacks(): void {
    const p = this.avPlayer;
    if (p === null) {
      return;
    }
    p.on('error', (err: BusinessError) => {
      this.emitError(`playError: ${err.message}`);
      try {
        this.avPlayer?.reset();
      } catch (_) {
        // reset 失败也接受,通常紧接着会走 stop
      }
    });

    p.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        case 'initialized':
          if (this.avPlayer !== null) {
            this.avPlayer.audioRendererInfo = {
              usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
              rendererFlags: 0,
            };
            try {
              await this.avPlayer.prepare();
            } catch (e) {
              this.emitError(`prepare error: ${(e as BusinessError).message}`);
            }
          }
          break;
        case 'prepared':
          if (this.avPlayer !== null) {
            this.currentDuration = this.avPlayer.duration;
            try {
              await this.avPlayer.play();
            } catch (e) {
              this.emitError(`play error: ${(e as BusinessError).message}`);
            }
          }
          break;
        case 'playing': {
          const wasPlaying = this._isPlaying;
          const wasPaused = this._isPaused;
          this._isPlaying = true;
          this._isPaused = false;
          if (wasPaused) {
            this.listener?.onResume?.();
          } else if (!wasPlaying) {
            this.listener?.onPlay?.();
          }
          this.startProgressTracking();
          break;
        }
        case 'paused':
          this._isPlaying = false;
          this._isPaused = true;
          this.stopProgressTracking();
          this.listener?.onPause?.();
          break;
        case 'completed':
          this._isPlaying = false;
          this._isPaused = false;
          this.currentPosition = 0;
          this.stopProgressTracking();
          this.listener?.onCompletion?.();
          // completed 后主动 stop+release,让下一次 play 从干净状态开始
          try {
            await this.stop();
          } catch (e) {
            console.warn(`${AudioPlayerHelper.TAG} auto stop after completed failed`,
              (e as BusinessError).message);
          }
          break;
        case 'stopped':
          this._isPlaying = false;
          this._isPaused = false;
          this.stopProgressTracking();
          break;
        case 'released':
          this.avPlayer = null;
          break;
        default:
          break;
      }
    });
  }

  private startProgressTracking(): void {
    this.stopProgressTracking();
    this.progressTimerId = setInterval(() => {
      if (this.avPlayer !== null && this._isPlaying) {
        this.currentPosition = this.avPlayer.currentTime;
        this.listener?.onProgressUpdate?.(this.currentPosition, this.currentDuration);
      }
    }, AudioPlayerHelper.PROGRESS_INTERVAL_MS);
  }

  private stopProgressTracking(): void {
    if (this.progressTimerId !== -1) {
      clearInterval(this.progressTimerId);
      this.progressTimerId = -1;
    }
  }

  private emitError(msg: string): void {
    console.error(`${AudioPlayerHelper.TAG} ${msg}`);
    this.listener?.onError?.(msg);
  }
}
