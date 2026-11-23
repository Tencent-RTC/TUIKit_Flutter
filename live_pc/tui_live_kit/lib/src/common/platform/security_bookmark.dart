import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Only needed under the macOS App Sandbox (persists file access across launches); no-op elsewhere.
class SecurityBookmark {
  SecurityBookmark._();

  static const _channel = MethodChannel('tui_live_kit');

  static Future<String?> create(String path) async {
    if (!Platform.isMacOS) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>('createBookmark', path);
    } on MissingPluginException {
      // Plugin not linked (e.g. non-macOS host without the native side);
      // degrade to null silently — the raw path remains usable.
      return null;
    } on PlatformException catch (e) {
      debugPrint('SecurityBookmark.create failed: $e');
      return null;
    }
  }

  /// Null on failure (callers fall back to the raw path); a stale bookmark yields a refreshed one to persist.
  static Future<BookmarkResolution?> resolve(String base64) async {
    if (!Platform.isMacOS || base64.isEmpty) {
      return null;
    }
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'resolveBookmark',
        base64,
      );
      final path = result?['path'] as String?;
      if (path == null || path.isEmpty) {
        return null;
      }
      return BookmarkResolution(
        path: path,
        refreshedBookmark: result?['refreshedBookmark'] as String?,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('SecurityBookmark.resolve failed: $e');
      return null;
    }
  }

  /// Best-effort; failures are ignored.
  static Future<void> release(String path) async {
    if (!Platform.isMacOS || path.isEmpty) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('releaseAccess', path);
    } on MissingPluginException {
      // Plugin not linked; nothing to release.
    } on PlatformException catch (e) {
      debugPrint('SecurityBookmark.release failed: $e');
    }
  }
}

class BookmarkResolution {
  const BookmarkResolution({required this.path, this.refreshedBookmark});

  final String path;
  final String? refreshedBookmark;
}
