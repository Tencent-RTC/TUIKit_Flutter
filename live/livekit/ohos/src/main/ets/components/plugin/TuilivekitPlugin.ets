import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  EventChannel,
} from '@ohos/flutter_ohos';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import ThermalManager from '../../utils/ThermalManager';
import { AVSessionManager } from '../../utils/AVSessionManager';

/**
 * TuilivekitPlugin
 *
 *   MethodChannel: `tuilivekit`
 *   EventChannel:  `tuilivekit_thermal_events`
 */

const TAG = 'TuilivekitPlugin';
const DOMAIN = 0x0000;

export default class TuilivekitPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private methodChannel: MethodChannel | null = null;
  private thermalEventChannel: EventChannel | null = null;

  private avSessionManager = new AVSessionManager();
  private thermalHandler: ThermalManager = new ThermalManager();

  private uiAbilityContext: common.UIAbilityContext | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return 'TuilivekitPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    const messenger = binding.getBinaryMessenger();

    this.methodChannel = new MethodChannel(messenger, 'tuilivekit');
    this.methodChannel.setMethodCallHandler(this);

    this.thermalEventChannel = new EventChannel(messenger, 'tuilivekit_thermal_events');
    this.thermalEventChannel.setStreamHandler(this.thermalHandler);
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    if (this.methodChannel !== null) {
      this.methodChannel.setMethodCallHandler(null);
      this.methodChannel = null;
    }
    if (this.thermalEventChannel !== null) {
      this.thermalEventChannel.setStreamHandler(null);
      this.thermalEventChannel = null;
    }
  }

  // ---- AbilityAware ----
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.uiAbilityContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.uiAbilityContext = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const method: string = call.method;
    const argsObj: Record<string, Object> = {};
    call.args.forEach((value: Object, key: string) => {
      argsObj[key] = value;
    });
    hilog.info(DOMAIN, TAG, 'onMethodCall: method=%{public}s, args=%{public}s',
        method, JSON.stringify(argsObj));
    try {
      switch (method) {
        case 'enableWakeLock':
          this.enableWakeLock(call, result);
          break;
        case 'startForegroundService':
          this.avSessionManager.start();
          break;
        case 'stopForegroundService':
          this.avSessionManager.stop();
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'onMethodCall error: method=%{public}s, err=%{public}s',
        method, JSON.stringify(e));
      result.error('livekit_ohos_error', `method ${method} failed`, JSON.stringify(e));
    }
  }

  private enableWakeLock(call: MethodCall, result: MethodResult): void {
    const enable: boolean = call.argument('enable') as boolean ?? false;
    const ctx = this.uiAbilityContext;
    if (ctx === null) {
      hilog.error(DOMAIN, TAG, 'enableWakeLock failed: UIAbilityContext is null');
      result.error('enableWakeLock error', 'UIAbilityContext is null', null);
      return;
    }
    window.getLastWindow(ctx).then((win: window.Window) => {
      win.setWindowKeepScreenOn(enable).then(() => {
        hilog.info(DOMAIN, TAG, 'enableWakeLock success: %{public}s', String(enable));
        result.success(0);
      }).catch((err: Error) => {
        hilog.error(DOMAIN, TAG, 'setWindowKeepScreenOn failed: %{public}s', JSON.stringify(err));
        result.error('enableWakeLock error', 'setWindowKeepScreenOn failed', JSON.stringify(err));
      });
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, 'getLastWindow failed: %{public}s', JSON.stringify(err));
      result.error('enableWakeLock error', 'getLastWindow failed', JSON.stringify(err));
    });
  }

}
