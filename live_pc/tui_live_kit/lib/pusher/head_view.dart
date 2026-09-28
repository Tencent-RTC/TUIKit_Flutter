import 'package:atomic_x_core/atomicxcore.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../l10n/language_store.dart';
import '../l10n/live_kit_localizations.dart';
import 'pusher_style.dart';
import 'window_control.dart';

/// 主播端顶部信息栏（h44）：Logo / 标题 / 版本 + CPU / 内存 / 语言切换 /
/// 用户信息。
///
/// macOS 为无标题栏窗口，系统交通灯浮在左上角并垂直居中于本栏，
/// 故左侧留白避让；中间空白区作为窗口拖拽热区（见 [WindowControl]）。
class PusherHeadView extends StatelessWidget {
  const PusherHeadView({super.key});

  @override
  Widget build(BuildContext context) {
    // macOS 无标题栏，左侧为系统交通灯预留避让空间。
    final leftPadding = Platform.isMacOS ? 88.0 : 16.0;
    return Container(
      height: 44,
      padding: EdgeInsets.only(left: leftPadding, right: 16),
      decoration: const BoxDecoration(
        color: Color(0x8014151C), // rgba(20,21,28,0.5)
        border: Border(bottom: BorderSide(color: PusherStyle.white6)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PusherStyle.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  RemixIcons.broadcast_line,
                  size: 12,
                  color: PusherStyle.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                LiveKitLocalizations.of(context).loginBrandTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PusherStyle.textEmphasis,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PusherStyle.white5,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'v0.0.1',
                  style: TextStyle(
                    fontSize: 10,
                    color: PusherStyle.textHint,
                  ),
                ),
              ),
            ],
          ),
          // 中间空白区：窗口拖拽热区（左右可交互元素不参与，天然无冲突）。
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => WindowControl.startDragging(),
              child: const SizedBox.expand(),
            ),
          ),
          Row(
            children: [
              const _LanguageButton(),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: LoginStore.shared,
                builder: (context, _) {
                  final user = LoginStore.shared.loginState.loginUserInfo;
                  final name = (user?.nickname?.isNotEmpty ?? false)
                      ? user!.nickname!
                      : (user?.userID.isNotEmpty ?? false)
                          ? user!.userID
                          : '—';
                  final avatarUrl = user?.avatarURL ?? '';
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _UserAvatar(url: avatarUrl, name: name),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PusherStyle.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 用户头像：优先网络图，无 URL 时回退到首字符圆形。
class _UserAvatar extends StatelessWidget {
  final String url;
  final String name;

  const _UserAvatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final fallback = Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PusherStyle.white10,
        border: Border.all(color: PusherStyle.white10),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: PusherStyle.textPrimary,
        ),
      ),
    );
    if (url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

/// 语言切换入口：地球图标 → 弹出菜单（跟随系统 / 中文 / English），
/// 当前项打勾；写入 LanguageStore.locale，MaterialApp 监听重建生效。
class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    return ValueListenableBuilder<Locale?>(
      valueListenable: LanguageStore.locale,
      builder: (context, current, _) {
        return PopupMenuButton<Locale?>(
          tooltip: strings.languageSwitch,
          initialValue: current,
          onSelected: (locale) => LanguageStore.locale.value = locale,
          color: const Color(0xFF2A2536),
          itemBuilder: (context) => [
            _localeItem(strings.languageFollowSystem, null, current),
            _localeItem('中文', const Locale('zh'), current),
            _localeItem('English', const Locale('en'), current),
          ],
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PusherStyle.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              RemixIcons.global_line,
              size: 13,
              color: PusherStyle.textSecondary,
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<Locale?> _localeItem(
    String label,
    Locale? value,
    Locale? current,
  ) {
    final selected = value == current;
    return PopupMenuItem<Locale?>(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(
            RemixIcons.check_line,
            size: 12,
            color: selected ? PusherStyle.brand2 : Colors.transparent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: PusherStyle.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
