import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import PermissionHandler from './PermissionHandler';

/**
 * OHOS 端 permission channel bridge。
 * 对齐 Android 版 io.trtc.tuikit.atomicx.permission.Permission.kt:
 *   - Permission          -> 只做 channel + Ability 生命周期
 *   - PermissionHandler   -> 业务(权限映射 / check / request / openSettings)
 *
 * Ability 生命周期由 AtomicXPlugin 转发过来(见 AtomicXPlugin.onAttachedToAbility)。
 */
export default class Permission implements MethodCallHandler {
  private static readonly TAG = 'AtomicX.Permission';
  private static readonly CHANNEL_NAME = 'atomic_x/permission';

  private channel: MethodChannel | null = null;
  private handler: PermissionHandler = new PermissionHandler();

  constructor(binding: FlutterPluginBinding) {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), Permission.CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  /** 由 root plugin(AtomicXPlugin)在 onAttachedToAbility 转发调用。 */
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.handler.setAbilityContext(binding.getAbility().context);
  }

  /** 由 root plugin(AtomicXPlugin)在 onDetachedFromAbility 转发调用。 */
  onDetachedFromAbility(): void {
    this.handler.setAbilityContext(null);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'checkPermissionStatus': {
        const perm = call.argument('permission') as string | null;
        if (perm === null || perm === undefined) {
          result.error('INVALID_ARGUMENT', 'Permission is required', null);
          return;
        }
        this.handler.checkPermissionStatus(perm).then((status: string) => {
          result.success(status);
        }).catch((e: Error) => {
          console.error(`${Permission.TAG} checkPermissionStatus failed`, e.message);
          result.success('denied');
        });
        return;
      }
      case 'requestPermissions': {
        const perms = call.argument('permissions') as string[] | null;
        if (perms === null || perms === undefined || perms.length === 0) {
          result.error('INVALID_ARGUMENT', 'Permissions are required', null);
          return;
        }
        this.handler.requestPermissions(perms).then((map: Record<string, string>) => {
          result.success(map);
        }).catch((e: Error) => {
          console.error(`${Permission.TAG} requestPermissions failed`, e.message);
          result.success({} as Record<string, string>);
        });
        return;
      }
      case 'openAppSettings': {
        result.success(this.handler.openAppSettings());
        return;
      }
      default:
        result.notImplemented();
    }
  }

  dispose(): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.handler.setAbilityContext(null);
  }
}
