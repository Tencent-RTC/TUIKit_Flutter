import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import notificationManager from '@ohos.notificationManager';

/**
 * OHOS 端 permission 业务逻辑,对齐 Android 版
 * io.trtc.tuikit.atomicx.permission.PermissionHandler.kt。
 *
 * Dart 契约(见 permission.dart):
 *   PermissionType.identifier(camera/microphone/photos/storage/notification/
 *     systemAlertWindow/displayOverOtherApps)
 *   PermissionStatus.value(granted/denied/permanentlyDenied/limited/notDetermined)
 *
 * 与 Android 差异,提前说清楚:
 *   1. 鸿蒙 abilityAccessCtrl.checkAccessToken 只返回 GRANTED/DENIED,
 *      没有 shouldShowRationale 概念,所以 checkPermissionStatus 无法区分
 *      "从未请求过" 和 "永久拒绝",一律返回 denied。permanentlyDenied 仅在
 *      requestPermissionsFromUser 之后靠 dialogShownResults 判定。
 *   2. 鸿蒙没有 partial photos 权限,因此不会返回 limited。
 *   3. SYSTEM_FLOAT_WINDOW 是 restricted 权限,普通应用申请必失败,直接返回 denied。
 */
export default class PermissionHandler {
  private static readonly TAG = 'AtomicX.PermissionHandler';

  // Dart 侧 PermissionType.identifier
  private static readonly TYPE_CAMERA = 'camera';
  private static readonly TYPE_MICROPHONE = 'microphone';
  private static readonly TYPE_PHOTOS = 'photos';
  private static readonly TYPE_STORAGE = 'storage';
  private static readonly TYPE_NOTIFICATION = 'notification';
  private static readonly TYPE_SYSTEM_ALERT_WINDOW = 'systemAlertWindow';
  private static readonly TYPE_DISPLAY_OVER_OTHER_APPS = 'displayOverOtherApps';

  // Dart 侧 PermissionStatus.value
  private static readonly STATUS_GRANTED = 'granted';
  private static readonly STATUS_DENIED = 'denied';
  private static readonly STATUS_PERMANENTLY_DENIED = 'permanentlyDenied';

  // ohos 权限枚举值
  private static readonly PERM_CAMERA: Permissions = 'ohos.permission.CAMERA';
  private static readonly PERM_MIC: Permissions = 'ohos.permission.MICROPHONE';
  private static readonly PERM_READ_MEDIA: Permissions = 'ohos.permission.READ_IMAGEVIDEO';
  private static readonly PERM_WRITE_MEDIA: Permissions = 'ohos.permission.WRITE_IMAGEVIDEO';

  private uiAbilityContext: common.UIAbilityContext | null = null;

  setAbilityContext(ctx: common.UIAbilityContext | null): void {
    this.uiAbilityContext = ctx;
  }

  /**
   * 把 Dart PermissionType.identifier 映射成鸿蒙 Permissions 数组。
   * 单个 Dart 权限可能对应鸿蒙多个 permission(如 storage 覆盖读写)。
   * 返回空数组:表示该类型无 runtime 权限或走特殊分支处理。
   */
  private mapToOhosPermissions(type: string): Permissions[] {
    switch (type) {
      case PermissionHandler.TYPE_CAMERA:
        return [PermissionHandler.PERM_CAMERA];
      case PermissionHandler.TYPE_MICROPHONE:
        return [PermissionHandler.PERM_MIC];
      case PermissionHandler.TYPE_PHOTOS:
        // 鸿蒙上读相册应使用 photoAccessHelper.PhotoViewPicker,由系统临时授权,
        // READ_IMAGEVIDEO 属于受限权限(仅克隆/备份/同步场景可申请)。
        // 这里返回空数组 -> 上层判定为 granted,让业务直接调 PhotoViewPicker。
        return [];
      case PermissionHandler.TYPE_STORAGE:
        // 同理,读走 picker 免权限;仅保留写权限用于"保存到相册"场景。
        return [PermissionHandler.PERM_WRITE_MEDIA];
      default:
        // notification / systemAlertWindow / displayOverOtherApps 走特殊分支
        return [];
    }
  }

  /**
   * checkPermissionStatus (Dart -> ArkTS 单权限查询)。
   * @returns 'granted' | 'denied'  (鸿蒙 checkAccessToken 无 rationale,不返回 permanentlyDenied)
   */
  async checkPermissionStatus(type: string): Promise<string> {
    if (type === PermissionHandler.TYPE_NOTIFICATION) {
      return await this.checkNotification();
    }
    if (
      type === PermissionHandler.TYPE_SYSTEM_ALERT_WINDOW ||
      type === PermissionHandler.TYPE_DISPLAY_OVER_OTHER_APPS
    ) {
      // 鸿蒙上普通应用无法拥有 SYSTEM_FLOAT_WINDOW,直接 denied
      return PermissionHandler.STATUS_DENIED;
    }

    const ohosPerms = this.mapToOhosPermissions(type);
    if (ohosPerms.length === 0) {
      return PermissionHandler.STATUS_GRANTED;
    }

    const tokenId = await this.getSelfTokenId();
    if (tokenId === 0) {
      return PermissionHandler.STATUS_DENIED;
    }
    const atManager = abilityAccessCtrl.createAtManager();
    for (const p of ohosPerms) {
      try {
        const r = await atManager.checkAccessToken(tokenId, p);
        if (r !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          return PermissionHandler.STATUS_DENIED;
        }
      } catch (e) {
        console.warn(`${PermissionHandler.TAG} checkAccessToken(${p}) failed`, (e as BusinessError).message);
        return PermissionHandler.STATUS_DENIED;
      }
    }
    return PermissionHandler.STATUS_GRANTED;
  }

  /**
   * requestPermissions (Dart -> ArkTS 批量申请)。
   * @returns Map<Dart identifier, status>
   */
  async requestPermissions(types: string[]): Promise<Record<string, string>> {
    const result: Record<string, string> = {};

    const runtimeTypes: string[] = [];
    const runtimePerms: Permissions[] = [];
    const perm2type: Map<string, string> = new Map();

    for (const t of types) {
      if (t === PermissionHandler.TYPE_NOTIFICATION) {
        result[t] = await this.requestNotification();
        continue;
      }
      if (
        t === PermissionHandler.TYPE_SYSTEM_ALERT_WINDOW ||
        t === PermissionHandler.TYPE_DISPLAY_OVER_OTHER_APPS
      ) {
        result[t] = PermissionHandler.STATUS_DENIED;
        continue;
      }
      const mapped = this.mapToOhosPermissions(t);
      if (mapped.length === 0) {
        result[t] = PermissionHandler.STATUS_GRANTED;
        continue;
      }
      runtimeTypes.push(t);
      for (const p of mapped) {
        if (!runtimePerms.includes(p)) {
          runtimePerms.push(p);
        }
        // 允许多个 Dart 权限映射到同一 ohos 权限,取先注册的
        if (!perm2type.has(p)) {
          perm2type.set(p, t);
        }
      }
    }

    if (runtimePerms.length === 0) {
      return result;
    }

    const ctx = this.uiAbilityContext;
    if (ctx === null) {
      console.warn(`${PermissionHandler.TAG} requestPermissions called but no UIAbilityContext`);
      for (const t of runtimeTypes) {
        result[t] = PermissionHandler.STATUS_DENIED;
      }
      return result;
    }

    // 权限级别的状态,以最保守的结果作为 Dart type 的最终状态
    const permStatus: Map<string, string> = new Map();
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const req = await atManager.requestPermissionsFromUser(ctx, runtimePerms);
      for (let i = 0; i < req.permissions.length; i++) {
        const p = req.permissions[i];
        const auth = req.authResults[i];
        const shown = req.dialogShownResults ? req.dialogShownResults[i] : true;
        if (auth === 0) {
          permStatus.set(p, PermissionHandler.STATUS_GRANTED);
        } else if (!shown) {
          // 用户之前勾了"不再询问"或系统禁止 -> 永久拒绝
          permStatus.set(p, PermissionHandler.STATUS_PERMANENTLY_DENIED);
        } else {
          permStatus.set(p, PermissionHandler.STATUS_DENIED);
        }
      }
    } catch (e) {
      console.error(`${PermissionHandler.TAG} requestPermissionsFromUser failed`, (e as BusinessError).message);
      for (const t of runtimeTypes) {
        result[t] = PermissionHandler.STATUS_DENIED;
      }
      return result;
    }

    // 一个 Dart type 可能对应多个 ohos permission(如 storage),
    // 取"最差"状态: permanentlyDenied > denied > granted
    const rank: Record<string, number> = {};
    rank[PermissionHandler.STATUS_GRANTED] = 0;
    rank[PermissionHandler.STATUS_DENIED] = 1;
    rank[PermissionHandler.STATUS_PERMANENTLY_DENIED] = 2;
    for (const t of runtimeTypes) {
      let worst = PermissionHandler.STATUS_GRANTED;
      const ohosPerms = this.mapToOhosPermissions(t);
      for (const p of ohosPerms) {
        const s = permStatus.get(p) ?? PermissionHandler.STATUS_DENIED;
        if (rank[s] > rank[worst]) {
          worst = s;
        }
      }
      result[t] = worst;
    }
    return result;
  }

  /**
   * openAppSettings — 跳转到系统设置里的本 app 详情页。
   */
  openAppSettings(): boolean {
    const ctx = this.uiAbilityContext;
    if (ctx === null) {
      console.warn(`${PermissionHandler.TAG} openAppSettings called but no UIAbilityContext`);
      return false;
    }
    try {
      ctx.startAbility({
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          pushParams: ctx.abilityInfo.bundleName,
        },
      });
      return true;
    } catch (e) {
      console.warn(`${PermissionHandler.TAG} openAppSettings failed`, (e as BusinessError).message);
      return false;
    }
  }

  private async getSelfTokenId(): Promise<number> {
    try {
      const info = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
      );
      return info.appInfo.accessTokenId;
    } catch (e) {
      console.error(`${PermissionHandler.TAG} getBundleInfoForSelf failed`, (e as BusinessError).message);
      return 0;
    }
  }

  private async checkNotification(): Promise<string> {
    try {
      const enabled = await notificationManager.isNotificationEnabled();
      return enabled ? PermissionHandler.STATUS_GRANTED : PermissionHandler.STATUS_DENIED;
    } catch (e) {
      console.warn(`${PermissionHandler.TAG} isNotificationEnabled failed`, (e as BusinessError).message);
      return PermissionHandler.STATUS_DENIED;
    }
  }

  private async requestNotification(): Promise<string> {
    const ctx = this.uiAbilityContext;
    if (ctx === null) {
      return await this.checkNotification();
    }
    try {
      await notificationManager.requestEnableNotification(ctx);
      return PermissionHandler.STATUS_GRANTED;
    } catch (e) {
      const err = e as BusinessError;
      // 1600004: user rejected in the dialog(非永久,可再次请求)
      // 其他错误码基本都视作 denied
      console.warn(`${PermissionHandler.TAG} requestEnableNotification failed code=${err.code}, msg=${err.message}`);
      return PermissionHandler.STATUS_DENIED;
    }
  }
}
