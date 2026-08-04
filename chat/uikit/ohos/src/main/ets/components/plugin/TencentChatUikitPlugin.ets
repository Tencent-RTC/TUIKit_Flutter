import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import AudioPlayer from '../../audioplayer/AudioPlayer';
import AudioRecorder from '../../audiorecorder/AudioRecorder';
import FilePicker from '../../filepicker/FilePicker';
import VideoRecorder from '../../videorecorder/VideoRecorder';

/**
 * TencentChatUikitPlugin
 *
 * OpenHarmony 侧的根插件类,对齐 pubspec.yaml 中 `ohos.pluginClass: TencentChatUikitPlugin`。
 * 与 Android 端保持一致的聚合模式:根类只做子模块生命周期编排 + AbilityAware 转发。
 *
 * 子模块清单(P0):
 *   [x] file_picker      -> filepicker/FilePicker.ets           (需要 UIAbilityContext)
 *   [x] audio_player     -> audioplayer/AudioPlayer.ets         (含 EventChannel)
 *   [x] audio_recorder   -> audiorecorder/AudioRecorder.ets     (含 EventChannel + UIAbilityContext)
 *   [x] video_recorder   -> videorecorder/VideoRecorder.ets     (cameraPicker + UIAbilityContext)
 *   [-] video_player     -> 用 Dart 降级方案:ohos 上 VideoPlayer.play 直接调
 *                            FilePicker.openFile 由系统视频播放器打开,不做 PlatformView。
 *                            见 chat/uikit/lib/src/video_player/video_player.dart。
 */
export default class TencentChatUikitPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private filePicker: FilePicker | null = null;
  private audioPlayer: AudioPlayer | null = null;
  private audioRecorder: AudioRecorder | null = null;
  private videoRecorder: VideoRecorder | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return 'TencentChatUikitPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'tencent_chat_uikit');
    this.channel.setMethodCallHandler(this);

    this.filePicker = new FilePicker(binding);
    this.audioPlayer = new AudioPlayer(binding);
    this.audioRecorder = new AudioRecorder(binding);
    this.videoRecorder = new VideoRecorder(binding);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.videoRecorder?.dispose();
    this.videoRecorder = null;
    this.audioRecorder?.dispose();
    this.audioRecorder = null;
    this.audioPlayer?.dispose();
    this.audioPlayer = null;
    this.filePicker?.dispose();
    this.filePicker = null;

    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }

  // ---- AbilityAware ----
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.filePicker?.onAttachedToAbility(binding);
    this.audioRecorder?.onAttachedToAbility(binding);
    this.videoRecorder?.onAttachedToAbility(binding);
  }

  onDetachedFromAbility(): void {
    this.filePicker?.onDetachedFromAbility();
    this.audioRecorder?.onDetachedFromAbility();
    this.videoRecorder?.onDetachedFromAbility();
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'getPlatformVersion') {
      result.success('OpenHarmony ^ ^ ');
      return;
    }
    result.notImplemented();
  }
}
