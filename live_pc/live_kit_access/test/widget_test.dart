import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:live_kit_access/main.dart';
import 'package:tencent_live_kit_desktop/tui_live_kit.dart';

void main() {
  // 设计稿窗口为 1440×900，测试画布对齐该尺寸。
  void useDesignSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('PusherView 框架包含场景面板与各区域占位', (tester) async {
    useDesignSurface(tester);
    await tester.pumpWidget(const LiveKitAccessApp());

    expect(find.byType(PusherView), findsOneWidget);
    // 左侧场景面板：Tab 栏 + 场景切换 + 画面源列表
    expect(find.text('画面源'), findsOneWidget);
    expect(find.text('游戏直播'), findsOneWidget);
    expect(find.text('观影陪伴'), findsOneWidget);
    expect(find.text('休息中'), findsOneWidget);
    expect(find.text('连麦聊天'), findsNothing); // 竖屏场景在横屏模式下隐藏
    // 默认场景（游戏直播）的画面源
    expect(find.text('屏幕共享'), findsOneWidget);
    expect(find.text('摄像头画面'), findsOneWidget);
    expect(find.text('开播Logo'), findsOneWidget);
    // 顶部 / 中间 / 右侧占位
    expect(find.text('直播推流助手'), findsOneWidget);
    expect(find.text('开始直播'), findsOneWidget);
    expect(find.text('互动消息'), findsOneWidget);
  });

  testWidgets('切换场景后画面源列表联动更新', (tester) async {
    useDesignSurface(tester);
    await tester.pumpWidget(const LiveKitAccessApp());

    await tester.tap(find.text('观影陪伴'));
    await tester.pump();

    expect(find.text('影片播放窗口'), findsOneWidget);
    expect(find.text('屏幕共享'), findsNothing);
    // 当前场景高亮切换
    expect(find.text('横屏场景'), findsOneWidget);
  });
}
