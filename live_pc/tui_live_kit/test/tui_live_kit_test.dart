import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_kit_desktop/tui_live_kit.dart';
import 'package:tencent_live_kit_desktop/tui_live_kit_platform_interface.dart';
import 'package:tencent_live_kit_desktop/tui_live_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTuiLiveKitPlatform
    with MockPlatformInterfaceMixin
    implements TuiLiveKitPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TuiLiveKitPlatform initialPlatform = TuiLiveKitPlatform.instance;

  test('$MethodChannelTuiLiveKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTuiLiveKit>());
  });

  test('getPlatformVersion', () async {
    TuiLiveKit tuiLiveKitPlugin = TuiLiveKit();
    MockTuiLiveKitPlatform fakePlatform = MockTuiLiveKitPlatform();
    TuiLiveKitPlatform.instance = fakePlatform;

    expect(await tuiLiveKitPlugin.getPlatformVersion(), '42');
  });
}
