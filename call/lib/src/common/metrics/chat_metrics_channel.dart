import 'dart:io';

import 'package:tencent_calls_uikit/src/common/constants.dart';
import 'package:tencent_calls_uikit/src/common/platform/call_kit_platform_interface.dart';
import 'package:tencent_calls_uikit/src/common/utils/app_lifecycle.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import 'key_metrics.dart';

class ChatMetricsChannel {
  final String _tag = "IMMetrics";
  final String _apiReportRoomEngineEvent = "internal_operation_report_room_engine_event";

  void countEvent(EventId eventId) async {
    try {
      final extensionJson = await _buildExtensionJson();
      final payload = _buildEventPayload(eventId, extensionJson.toString());

      TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(
        api: _apiReportRoomEngineEvent,
        param: payload,
      );
    } catch (e) {
      print('$_tag: countUV exception: eventId=$eventId, error=$e');
    }
  }

  Future<Map<String, dynamic>> _buildExtensionJson() async {
    return {
      MetricsJsonKeys.basicInfo: _buildBasicInfoJson(),
      MetricsJsonKeys.platformInfo: await _buildPlatformInfoJson()
    };
  }

  Map<String, dynamic> _buildBasicInfoJson() {
    return {
      MetricsJsonKeys.callId: CallStore.shared.state.activeCall.value.callId ?? "",
      MetricsJsonKeys.intRoomId: 0,
      MetricsJsonKeys.strRoomId: CallStore.shared.state.activeCall.value.roomId ?? "",
      MetricsJsonKeys.uiKitVersion: Constants.pluginVersion
    };
  }

  Future<Map<String, dynamic>> _buildPlatformInfoJson() async {
    return {
      MetricsJsonKeys.platform: Platform.isAndroid ? "android" : "ios",
      MetricsJsonKeys.framework: 7,
      MetricsJsonKeys.deviceBrand: _getDeviceBrand(),
      MetricsJsonKeys.deviceModel: _getDeviceModel(),
      MetricsJsonKeys.androidVersion: Platform.isAndroid ? _getAndroidVersion() : "",
      MetricsJsonKeys.isForeground: await _isAppInForeground(),
      MetricsJsonKeys.isScreenLocked: await _isScreenLocked(),
      MetricsJsonKeys.hasFloatingWindowPermission: await _hasFloatingWindowPermission(),
      MetricsJsonKeys.hasBackgroundLaunchPermission: await _hasBackgroundLaunchPermission(),
      MetricsJsonKeys.hasNotificationPermission: await _hasNotificationPermission()
    };
  }

  Map<String, dynamic> _buildEventPayload(EventId eventId, String extensionMessage) {
    String prefix = "report_room_engine_event_param_";
    return {
      prefix + MetricsJsonKeys.eventId: eventId.value(),
      prefix + MetricsJsonKeys.eventCode: 0,
      prefix + MetricsJsonKeys.eventResult: 0,
      prefix + MetricsJsonKeys.eventMessage: Constants.pluginVersion,
      prefix + MetricsJsonKeys.moreMessage: "",
      prefix + MetricsJsonKeys.extensionMessage: extensionMessage
    };
  }

  String _getDeviceBrand() {
    if (Platform.isAndroid) {
      return Platform.environment['BRAND'] ?? 'Unknown';
    } else if (Platform.isIOS) {
      return 'Apple';
    }
    return 'Unknown';
  }

  String _getDeviceModel() {
    if (Platform.isAndroid) {
      return Platform.environment['MODEL'] ?? 'Unknown';
    } else if (Platform.isIOS) {
      return 'iPhone';
    }
    return 'Unknown';
  }

  String _getAndroidVersion() {
    if (Platform.isAndroid) {
      return Platform.environment['VERSION.RELEASE'] ?? 'Unknown';
    }
    return '';
  }

  Future<bool> _hasBackgroundLaunchPermission() async {
    try {
      final status = await Permission.check(PermissionType.systemAlertWindow);
      return status == PermissionStatus.granted || status == PermissionStatus.limited;
    } catch (e) {
      print('$_tag: check background launch permission exception: $e');
      return false;
    }
  }

  Future<bool> _hasFloatingWindowPermission() async {
    try {
      final status = await Permission.check(PermissionType.displayOverOtherApps);
      return status == PermissionStatus.granted || status == PermissionStatus.limited;
    } catch (e) {
      print('$_tag: check floating window permission exception: $e');
      return false;
    }
  }

  Future<bool> _isAppInForeground() async {
    return AppLifecycle.instance.isForeground;
  }

  Future<bool> _isScreenLocked() async {
    if (Platform.isAndroid) {
      try {
        return await TUICallKitPlatform.instance.isScreenLocked();
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<bool> _hasNotificationPermission() async {
    try {
      final status = await Permission.check(PermissionType.notification);
      return status == PermissionStatus.granted || status == PermissionStatus.limited;
    } catch (e) {
      print('$_tag: check notification permission exception: $e');
      return false;
    }
  }
}

