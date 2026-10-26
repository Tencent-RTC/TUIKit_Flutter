import { StreamHandler, EventSink } from '@ohos/flutter_ohos';
import thermal from '@ohos.thermal';
import hilog from '@ohos.hilog';

const TAG = 'TuilivekitPlugin.ThermalManager';
const DOMAIN = 0x0000;

/**
 * OHOS 端手机温度监听。
 *
 * ThermalLevel 映射：
 *   COOL(0)/NORMAL(1)              -> 0 (nominal)
 *   WARM(2)                        -> 1 (fair)
 *   HOT(3)                         -> 2 (serious)
 *   OVERHEATED(4)/WARNING(5)/
 *   EMERGENCY(6)                   -> 3 (critical)
 */
export default class ThermalManager implements StreamHandler {
  private eventSink: EventSink | null = null;
  private subscribed: boolean = false;

  onListen(_args: ESObject, events: EventSink): void {
    this.eventSink = events;
    try {
      thermal.registerThermalLevelCallback((level: thermal.ThermalLevel) => {
        const normalized = ThermalManager.mapThermalLevel(level);
        if (this.eventSink !== null) {
          this.eventSink.success(normalized);
        }
      });
      this.subscribed = true;
      try {
        const current = thermal.getLevel();
        events.success(ThermalManager.mapThermalLevel(current));
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'getLevel failed: %{public}s', JSON.stringify(e));
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'registerThermalLevelCallback failed: %{public}s', JSON.stringify(e));
    }
  }

  onCancel(_args: ESObject): void {
    if (this.subscribed) {
      try {
        thermal.unregisterThermalLevelCallback();
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'unregisterThermalLevelCallback failed: %{public}s', JSON.stringify(e));
      }
      this.subscribed = false;
    }
    this.eventSink = null;
  }

  private static mapThermalLevel(level: thermal.ThermalLevel): number {
    switch (level) {
      case thermal.ThermalLevel.COOL:
      case thermal.ThermalLevel.NORMAL:
        return 0;
      case thermal.ThermalLevel.WARM:
        return 1;
      case thermal.ThermalLevel.HOT:
        return 2;
      case thermal.ThermalLevel.OVERHEATED:
      case thermal.ThermalLevel.WARNING:
      case thermal.ThermalLevel.EMERGENCY:
        return 3;
      default:
        return 0;
    }
  }
}
