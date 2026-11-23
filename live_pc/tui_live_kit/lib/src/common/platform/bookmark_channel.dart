import 'package:atomic_x_core_media_mixing/api/scene/scene_bookmark_channel.dart';

import 'security_bookmark.dart';

class LiveKitBookmarkChannel extends SceneBookmarkChannel {
  const LiveKitBookmarkChannel();

  @override
  Future<String?> create(String path) => SecurityBookmark.create(path);

  @override
  Future<SceneBookmarkResolution?> resolve(String bookmark) async {
    final resolution = await SecurityBookmark.resolve(bookmark);
    if (resolution == null) {
      return null;
    }
    return SceneBookmarkResolution(path: resolution.path, refreshedBookmark: resolution.refreshedBookmark);
  }

  @override
  Future<void> release(String path) => SecurityBookmark.release(path);
}
