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
import AlbumPicker from '../../albumpicker/AlbumPicker';
import Device from '../../device_info/Device';
import Permission from '../../permission/Permission';

/**
 * AtomicXPlugin
 *
 * OpenHarmony 侧的根插件类,对齐 pubspec.yaml 中 `ohos.pluginClass: AtomicXPlugin`。
 * 与 Android 端 io.trtc.tuikit.atomicx.AtomicXPlugin.kt 保持相同的聚合思路:
 * 本类只做子模块的生命周期编排 + AbilityAware 生命周期转发,
 * 业务逻辑放在各子模块自己的 handler 类里。
 *
 * 子模块清单(P0):
 *   [x] device_info    -> device_info/Device.ets
 *   [x] permission     -> permission/Permission.ets           (需要 UIAbilityContext)
 *   [x] album_picker   -> albumpicker/AlbumPicker.ets         (含 EventChannel)
 * 主动跳过:
 *   [-] pip            (Android-only)
 *   [-] image_uploader (由 IMSDK 内部处理,Flutter 层不需要)
 */
export default class AtomicXPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private device: Device | null = null;
  private permission: Permission | null = null;
  private albumPicker: AlbumPicker | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return 'AtomicXPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'tuikit_atomic_x');
    this.channel.setMethodCallHandler(this);

    this.device = new Device(binding);
    this.permission = new Permission(binding);
    this.albumPicker = new AlbumPicker(binding);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.device?.dispose();
    this.device = null;
    this.permission?.dispose();
    this.permission = null;
    this.albumPicker?.dispose();
    this.albumPicker = null;

    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }

  // ---- AbilityAware ----
  // 将 UIAbilityContext 转发给所有需要它的子模块(目前只有 permission 用)。
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.permission?.onAttachedToAbility(binding);
  }

  onDetachedFromAbility(): void {
    this.permission?.onDetachedFromAbility();
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
  }
}
