import 'dart:io';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:tencent_live_kit_desktop/tencent_live_kit_desktop.dart';

import 'window_control.dart';
import 'window_controls_bar.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageStore.locale,
      builder: (context, locale, _) => _build(context, locale.languageCode == 'zh'),
    );
  }

  Widget _build(BuildContext context, bool zh) {
    // macOS titlebarless: left clearance for the system traffic lights;
    // Windows frameless: control buttons hug the top-right corner
    // (right padding 0).
    final leftPadding = Platform.isMacOS ? 88.0 : 16.0;
    final rightPadding = Platform.isWindows ? 0.0 : 16.0;
    return Container(
      height: 44,
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LiveKitStyle.white6)),
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
                  color: LiveKitStyle.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  RemixIcons.broadcast_line,
                  size: 12,
                  color: LiveKitStyle.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                zh ? '直播推流助手' : 'Live Streaming Assistant',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LiveKitStyle.titleStrong,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LiveKitStyle.white5,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'v0.0.1',
                  style: TextStyle(fontSize: 10, color: LiveKitStyle.text3),
                ),
              ),
            ],
          ),
          // Middle blank area: window drag zone (left/right interactive
          // elements don't participate — no conflicts by construction);
          // double-click = maximize/restore on Windows (desktop convention).
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => WindowControl.startDragging(),
                onDoubleTap: () => WindowControl.toggleMaximize(),
                child: const SizedBox.expand(),
              ),
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
                  final name =
                      (user?.nickname?.isNotEmpty ?? false)
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
                          color: LiveKitStyle.textMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          if (Platform.isWindows) ...[
            const SizedBox(width: 16),
            const WindowControlsBar(),
          ],
        ],
      ),
    );
  }
}

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
        color: LiveKitStyle.white10,
        border: Border.all(color: LiveKitStyle.white10),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: LiveKitStyle.textMuted,
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

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageStore.locale,
      builder: (context, current, _) {
        return PopupMenuButton<Locale>(
          tooltip: current.languageCode == 'zh' ? '语言' : 'Language',
          initialValue: current,
          onSelected: (locale) => LanguageStore.locale.value = locale,
          color: const Color(0xFF2A2536),
          itemBuilder:
              (context) => [
                _localeItem('中文', const Locale('zh'), current),
                _localeItem('English', const Locale('en'), current),
              ],
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LiveKitStyle.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                RemixIcons.global_line,
                size: 13,
                color: LiveKitStyle.textMuted,
              ),
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<Locale> _localeItem(
    String label,
    Locale value,
    Locale current,
  ) {
    final selected = value == current;
    return PopupMenuItem<Locale>(
      value: value,
      height: 32,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Icon(
              RemixIcons.check_line,
              size: 12,
              color: selected ? LiveKitStyle.brand2 : Colors.transparent,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: LiveKitStyle.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
