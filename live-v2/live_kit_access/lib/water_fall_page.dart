/// 对应 iOS `LiveKitAccess/WaterfallViewController.swift`。
///
/// 接入 App 主界面：顶部栏 + 直播列表 + "开直播"入口。
library;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'live_list/live_select_list_view.dart';
import 'player_page.dart';
import 'pusher_page.dart';

class WaterfallPage extends StatefulWidget {
  const WaterfallPage({super.key});

  @override
  State<WaterfallPage> createState() => _WaterfallPageState();
}

class _WaterfallPageState extends State<WaterfallPage> {
  final ValueNotifier<int> _refreshTick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _refreshTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).padding.top + 15),
                const _LiveKitAccessTopBar(),
                const SizedBox(height: 10),
                Expanded(
                  child: LiveSelectListView(
                    refreshTrigger: _refreshTick,
                    onSelectLive: (LiveInfo liveInfo) => _onSelectLive(context, liveInfo),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Center(
                child: _StartLiveButton(onPressed: () => _createLive(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSelectLive(BuildContext context, LiveInfo liveInfo) async {
    if (liveInfo.liveID.isEmpty) {
      return;
    }
    final String loginUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    if (loginUserID.isNotEmpty && liveInfo.liveOwner.userID == loginUserID) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请点击开直播按钮去开播'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PlayerPage(liveID: liveInfo.liveID),
      ),
    );
    _refreshTick.value++;
  }

  Future<void> _createLive(BuildContext context) async {
    // 对应 iOS `createLive()`：一个账号一间房，避免与其他测试者或同一 ID 的历史房间冲突。
    final String userID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    if (userID.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            content: const Text('未获取到登录用户，请重新登录后开播'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('好'),
              ),
            ],
          );
        },
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PusherPage(liveID: 'live_$userID'),
      ),
    );
    _refreshTick.value++;
  }
}

/// "开直播"按钮，属于容器自身实现，不是模版工程的独立组件。
class _StartLiveButton extends StatelessWidget {
  const _StartLiveButton({required this.onPressed});

  final VoidCallback onPressed;

  /// UIColor(red: 0.20, green: 0.44, blue: 1.0, alpha: 1)
  static const Color _backgroundColor = Color(0xFF3370FF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _backgroundColor,
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        onTap: onPressed,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                'assets/app_ic_add.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                '开直播',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// 主界面顶部栏，属于容器自身实现，不是模版工程的独立组件。
class _LiveKitAccessTopBar extends StatelessWidget {
  const _LiveKitAccessTopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        children: <Widget>[
          const Center(
            child: Text(
              '在线直播',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _showVersion(context),
                child: Image.asset(
                  'assets/app_ic_version.png',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVersion(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: const Text('APP 版本：1.0'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('好'),
            ),
          ],
        );
      },
    );
  }
}
