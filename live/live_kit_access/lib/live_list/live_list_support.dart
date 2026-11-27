/// 对应 iOS `LiveKitAccess/LiveList/LiveListSupport.swift`。
///
/// 接入层直播选择列表的自带支撑：数据源映射、调色、错误文案、图片加载与资源入口。
/// 接入 App 自包含这些能力，图片素材通过 `package:tui_live_kit` 复用组件库打包资源。
library;

import 'dart:ui' as ui;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import 'live_select_list_item_view.dart';

/// 只负责把直播列表数据映射为列表项，不持有请求或分页状态。
class LiveSelectListDataSource {
  List<LiveInfo> liveList = <LiveInfo>[];

  int get numberOfItems => liveList.length;

  Widget buildItem(BuildContext context, int index) {
    return LiveSelectListItemView(liveInfo: liveList[index]);
  }
}

/// 接入层列表复用的基础颜色，与组件库 `LiveKitPalette` 对齐。
class LiveSelectListPalette {
  LiveSelectListPalette._();

  static const Color background = Color(0xFF0F121A);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xADFFFFFF);
}

/// 错误文案统一入口。
class LiveSelectListErrorText {
  LiveSelectListErrorText._();

  static String message(CompletionHandler handler) {
    final String detail = (handler.errorMessage ?? '').trim();
    return detail.isEmpty ? 'AtomicXCore error (${handler.errorCode})' : detail;
  }
}

/// 网络图片加载入口，空/非法 URL 返回 null 交由默认素材兜底。
class LiveSelectListImageLoader {
  LiveSelectListImageLoader._();

  static ImageProvider? provider(String urlString) {
    if (urlString.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }
    return NetworkImage(urlString);
  }
}

/// 资源与文案入口，图片素材复用组件库 `tui_live_kit` package 打包资源。
class LiveSelectListResources {
  LiveSelectListResources._();

  static const String packageName = 'tui_live_kit';

  static const String defaultCoverURL =
      'https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/live/live_cover1.png';

  static ImageProvider image(String name) {
    return AssetImage('assets/$name.png', package: packageName);
  }

  static String localizedString(String key) {
    final Map<String, String> table = _isChinese ? _zhHans : _en;
    return table[key] ?? key;
  }

  static bool get _isChinese {
    return ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase() ==
        'zh';
  }

  static const Map<String, String> _zhHans = <String, String>{
    'tuilivekit.live_list.viewers': '%d人看过',
  };

  static const Map<String, String> _en = <String, String>{
    'tuilivekit.live_list.viewers': '%d people viewed',
  };
}
