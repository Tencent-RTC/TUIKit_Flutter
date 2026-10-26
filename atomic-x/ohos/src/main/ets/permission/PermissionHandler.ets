import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
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
 *   1. 鸿蒙 abilityAccessCtrl.checkAccessToken 只返回 GRANTED/DENIED,没有
 *      shouldShowRationale 概念;dialogShownResults 又是 API 12+ 的可选字段,
 *      实测部分设备拿不到。因此 permanentlyDenied 靠本类自己持久化的
 *      "曾被用户拒绝过" 标记推导,见 hasBeenDeniedOnce。
 *   2. 鸿蒙没有 partial photos 权限,因此不会返回 limited。
 *   3. SYSTEM_FLOAT_WINDOW 是 restricted 权限,普通应用申请必失败,直接返回 denied。
 *
 * 为什么 "拒绝过一次" 就等于 permanentlyDenied:
 * 鸿蒙的 requestPermissionsFromUser 在用户点过 "不允许" 之后就再也不会拉起弹框
 * (系统机制,防骚扰),用户只能去设置里改。这一点与 Android 需要连续拒绝两次才
 * 进入 "不再询问" 不同,所以标记语义是 "被拒绝过" 而非 Android 的 "被请求过"。
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

  // "曾被拒绝过" 标记的持久化位置,对齐 Android 的 SharedPreferences 方案
  private static readonly PREFS_NAME = 'atomic_x_permissions';
  private static readonly KEY_DENIED_ONCE_PREFIX = 'denied_once_';
  // 通知不是 runtime permission,没有对应的 ohos.permission.* 名字,单独占一个 key
  private static readonly PSEUDO_PERM_NOTIFICATION = 'notification';

  private uiAbilityContext: common.UIAbilityContext | null = null;
  private prefsStore: preferences.Preferences | null = null;
  // 进程内缓存,同时兼作 preferences 不可用时的降级存储
  private deniedOnceCache: Set<string> = new Set<string>();

  setAbilityContext(ctx: common.UIAbilityContext | null): void {
    this.uiAbilityContext = ctx;
  }

  private async getPrefs(): Promise<preferences.Preferences | null> {
    if (this.prefsStore !== null) {
      return this.prefsStore;
    }
    const ctx = this.uiAbilityContext;
    if (ctx === null) {
      return null;
    }
    try {
      const options: preferences.Options = { name: PermissionHandler.PREFS_NAME };
      this.prefsStore = await preferences.getPreferences(ctx, options);
      return this.prefsStore;
    } catch (e) {
      console.warn(`${PermissionHandler.TAG} getPreferences failed`, (e as BusinessError).message);
      return null;
    }
  }

  /**
   * 该权限是否曾被用户拒绝过。鸿蒙上这等价于 "系统不会再弹框,只能去设置改",
   * 也就是 Dart 侧的 permanentlyDenied。
   */
  private async hasBeenDeniedOnce(perm: string): Promise<boolean> {
    if (this.deniedOnceCache.has(perm)) {
      return true;
    }
    const store = await this.getPrefs();
    if (store === null) {
      return false;
    }
    try {
      const v = store.getSync(`${PermissionHandler.KEY_DENIED_ONCE_PREFIX}${perm}`, false);
      const denied = typeof v === 'boolean' ? v : false;
      if (denied) {
        this.deniedOnceCache.add(perm);
      }
      return denied;
    } catch (e) {
      console.warn(`${PermissionHandler.TAG} read deniedOnce(${perm}) failed`, (e as BusinessError).message);
      return false;
    }
  }

  /**
   * 写入/清除 "曾被拒绝过" 标记。
   *
   * 授权成功时必须清除:鸿蒙的 "仅本次使用允许" 也会返回 authResults=0,
   * 这次授权过期后应当能重新拉起系统弹框,而不是直接把用户送去设置页。
   */
  private async setDeniedOnce(perm: string, denied: boolean): Promise<void> {
    if (denied) {
      this.deniedOnceCache.add(perm);
    } else {
      this.deniedOnceCache.delete(perm);
    }
    const store = await this.getPrefs();
    if (store === null) {
      return;
    }
    try {
      const key = `${PermissionHandler.KEY_DENIED_ONCE_PREFIX}${perm}`;
      if (denied) {
        store.putSync(key, true);
      } else {
        store.deleteSync(key);
      }
      await store.flush();
    } catch (e) {
      console.warn(`${PermissionHandler.TAG} write deniedOnce(${perm}) failed`, (e as BusinessError).message);
    }
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
   * @returns 'granted' | 'denied' | 'permanentlyDenied'
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
          // checkAccessToken 分不出 "从未请求过" 和 "已拒绝",靠持久化标记补上
          return (await this.hasBeenDeniedOnce(p))
            ? PermissionHandler.STATUS_PERMANENTLY_DENIED
            : PermissionHandler.STATUS_DENIED;
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

    // 必须在发起请求 "之前" 取快照:请求之后标记会被本次结果覆盖,
    // 就无法判断用户是首次被弹框拒绝还是早就拒绝过了。
    const deniedBefore: Set<string> = new Set<string>();
    for (const p of runtimePerms) {
      if (await this.hasBeenDeniedOnce(p)) {
        deniedBefore.add(p);
      }
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
          await this.setDeniedOnce(p, false);
        } else if (auth === 2) {
          // 请求无效(权限未在 module.json5 声明 / 权限名非法 / 未满足特殊申请条件)。
          // 这是应用自身的配置问题,把用户引到设置页也解决不了,所以不打标记。
          permStatus.set(p, PermissionHandler.STATUS_DENIED);
          console.error(`${PermissionHandler.TAG} requestPermissions(${p}) invalid, check module.json5`);
        } else if (!shown || deniedBefore.has(p)) {
          // 系统没弹框(!shown),或此前已经拒绝过 -> 只能去设置页改
          permStatus.set(p, PermissionHandler.STATUS_PERMANENTLY_DENIED);
          await this.setDeniedOnce(p, true);
        } else {
          // 用户在本次弹框里点了 "不允许"。本次返回 denied 而非 permanentlyDenied,
          // 以免刚拒绝就立刻弹引导框骚扰用户(与 Android / iOS 行为一致);
          // 但要打上标记,下次触发时 check 与 request 都会返回 permanentlyDenied。
          permStatus.set(p, PermissionHandler.STATUS_DENIED);
          await this.setDeniedOnce(p, true);
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
      if (enabled) {
        return PermissionHandler.STATUS_GRANTED;
      }
      return (await this.hasBeenDeniedOnce(PermissionHandler.PSEUDO_PERM_NOTIFICATION))
        ? PermissionHandler.STATUS_PERMANENTLY_DENIED
        : PermissionHandler.STATUS_DENIED;
    } catch (e) {
      console.warn(`${PermissionHandler.TAG} isNotificationEnabled failed`, (e as BusinessError).message);
      return PermissionHandler.STATUS_DENIED;
    }
  }

  /**
   * requestEnableNotification 与 requestPermissionsFromUser 同理:弹框只会展示一次,
   * 用户拒绝之后再调用会直接失败,所以同样用 "曾被拒绝过" 标记推导 permanentlyDenied。
   */
  private async requestNotification(): Promise<string> {
    const ctx = this.uiAbilityContext;
    if (ctx === null) {
      return await this.checkNotification();
    }
    const deniedBefore = await this.hasBeenDeniedOnce(PermissionHandler.PSEUDO_PERM_NOTIFICATION);
    try {
      await notificationManager.requestEnableNotification(ctx);
      await this.setDeniedOnce(PermissionHandler.PSEUDO_PERM_NOTIFICATION, false);
      return PermissionHandler.STATUS_GRANTED;
    } catch (e) {
      const err = e as BusinessError;
      // 1600004: 用户在弹框里拒绝,或弹框此前已展示过不再重复展示
      console.warn(`${PermissionHandler.TAG} requestEnableNotification failed code=${err.code}, msg=${err.message}`);
      await this.setDeniedOnce(PermissionHandler.PSEUDO_PERM_NOTIFICATION, true);
      return deniedBefore ? PermissionHandler.STATUS_PERMANENTLY_DENIED : PermissionHandler.STATUS_DENIED;
    }
  }
}
