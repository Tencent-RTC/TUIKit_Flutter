import deviceInfo from '@ohos.deviceInfo';
import {
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

/**
 * OHOS 端 device_info channel handler。
 *
 * 与 Android 版 io.trtc.tuikit.atomicx.device_info.Device.kt 一一对齐:
 *   Android Build.VERSION.SDK_INT   -> deviceInfo.sdkApiVersion (number)
 *   Android Build.VERSION.RELEASE   -> deviceInfo.osFullName    (string, 形如 "OpenHarmony 6.0.0.115")
 *   Android Build.MODEL             -> deviceInfo.productModel  (string)
 *   Android Build.MANUFACTURER      -> deviceInfo.manufacture   (string; 鸿蒙 API 拼写少一个 r)
 *
 * Dart 侧 device_channel.dart 直接消费这个 Map,字段名不能改,否则 Android/iOS 会跟着挂。
 */
export default class Device implements MethodCallHandler {
  private static readonly CHANNEL_NAME = 'atomic_x/device_info';
  private channel: MethodChannel | null = null;

  constructor(binding: FlutterPluginBinding) {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), Device.CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'getDeviceInfo') {
      this.getDeviceInfo(result);
      return;
    }
    result.notImplemented();
  }

  private getDeviceInfo(result: MethodResult): void {
    try {
      const info: Record<string, Object> = {
        'sdkInt': deviceInfo.sdkApiVersion,
        'version': deviceInfo.osFullName,
        'model': deviceInfo.productModel,
        'manufacturer': deviceInfo.manufacture,
      };
      result.success(info);
    } catch (e) {
      const message: string = (e as Error)?.message ?? 'Unknown error';
      result.error('DEVICE_INFO_ERROR', 'Failed to get device info', message);
    }
  }

  dispose(): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }
}
