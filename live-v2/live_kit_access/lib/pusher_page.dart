/// 对应 iOS `LiveKitAccess/PusherViewController.swift`。
///
/// 只做 `PusherView` 的承载与退出，不持有直播业务状态。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

class PusherPage extends StatelessWidget {
  const PusherPage({super.key, required this.liveID});

  final String liveID;

  static const SystemUiOverlayStyle _systemUiOverlayStyle =
      SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // edge-to-edge 让 Flutter 背景延伸到手势导航区；透明导航栏与关闭
      // contrast scrim 避免 Android/OEM 再叠一层黑色背景。
      value: _systemUiOverlayStyle,
      child: Scaffold(
        backgroundColor: Colors.black,
        // 对应 iOS 全屏 VC：底部安全区与键盘避让都由组件自身处理
        // （评论输入条监听键盘上移，Scaffold 不得压缩 body、不得抹掉底部安全区）。
        resizeToAvoidBottomInset: false,
        body: PusherView(
          liveID: liveID,
          onExit: () => _goBack(context),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
