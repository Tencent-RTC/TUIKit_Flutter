import 'package:flutter/widgets.dart';

import 'live_kit_localizations.dart';

/// 全局语言设置（内存态，重启后回归跟随系统）。
///
/// null = 跟随系统。宿主 App 在 MaterialApp 上监听并接 `locale:` 参数：
///
/// ```dart
/// ValueListenableBuilder<Locale?>(
///   valueListenable: LanguageStore.locale,
///   builder: (context, locale, _) => MaterialApp(locale: locale, ...),
/// );
/// ```
class LanguageStore {
  LanguageStore._();

  /// 当前语言覆盖；null 表示跟随系统。
  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);
}

/// 无 BuildContext 场景（Store / 引擎桥接层）取当前文案：
/// 按 LanguageStore.locale ?? 系统 locale 查表，不支持的语言回退中文。
LiveKitLocalizations currentLiveKitStrings() {
  final locale = LanguageStore.locale.value ??
      WidgetsBinding.instance.platformDispatcher.locale;
  return lookupLiveKitLocalizations(locale);
}
