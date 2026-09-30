import 'dart:io';

class AtomicPlatform {
  AtomicPlatform._();

  static final bool isOhos = !(Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux);

  static final bool isDesktop = Platform.isMacOS || Platform.isWindows;
}

class ViewIdCodec {
  ViewIdCodec._();

  static String encode(int viewId) {
    if (viewId == 0) {
      return '';
    }
    if (AtomicPlatform.isOhos) {
      return 'liteav_surface_$viewId';
    }
    return viewId.toString();
  }
}
