import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:live_kit_access/main.dart';

void main() {
  // 设计稿窗口为 1440×900，测试画布对齐该尺寸。
  void useDesignSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('首屏为登录页', (tester) async {
    useDesignSurface(tester);
    await tester.pumpWidget(const LiveKitAccessApp());
    await tester.pump();

    expect(find.text('直播推流助手'), findsOneWidget);
    expect(find.text('用户名登录'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });
}
