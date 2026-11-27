///
/// 负责 LiveList、Player 共用的网络图片加载与缓存。
/// Flutter 侧的下载、内存缓存与请求取消由 `NetworkImage` + `ImageCache` 提供，
/// 这里只保留同等职责的统一入口和空 URL 处理。
library;

import 'package:flutter/widgets.dart';

class LiveImageLoader {
  LiveImageLoader._();

  /// URL 为空或非法时返回 null，由调用方使用默认素材。
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
