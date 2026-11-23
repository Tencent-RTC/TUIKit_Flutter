import 'package:flutter/foundation.dart';

List<String> get getTargetPlatformTextFont {
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => const ['Microsoft YaHei'],
    TargetPlatform.macOS => const ['PingFang SC'],
    TargetPlatform.linux => const ['Noto Sans CJK SC', 'Source Han Sans SC'],
    _ => const [],
  };
}
