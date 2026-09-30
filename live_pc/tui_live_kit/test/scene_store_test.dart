import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';

import 'package:tencent_live_kit_desktop/pusher/scene/scene_store.dart';

void main() {
  test('默认数据（const 列表）下场景增删改不抛异常', () {
    final store = SceneStore();
    expect(store.scenes.length, 5);

    store.addScene('自定义1', RemixIcons.star_line);
    expect(store.scenes.length, 6);
    expect(store.currentScene?.name, '自定义1');

    store.renameScene(store.currentSceneKey, '改名的场景');
    expect(store.currentScene?.name, '改名的场景');

    store.duplicateScene(store.currentSceneKey);
    expect(store.scenes.length, 7);
    // 复制不切换当前场景，副本插入在原场景之后。
    expect(store.currentScene?.name, '改名的场景');
    expect(store.scenes.map((s) => s.name), contains('改名的场景 副本'));

    store.deleteScene(store.currentSceneKey);
    expect(store.scenes.length, 6);
    expect(store.currentScene, isNotNull);
  });

  test('nextCustomSceneName 跳过已占用序号', () {
    final store = SceneStore();
    expect(store.nextCustomSceneName(), '自定义1');
    store.addScene('自定义1', RemixIcons.star_line);
    expect(store.nextCustomSceneName(), '自定义2');
  });

  test('切换场景后选中顶层可见画面源', () {
    final store = SceneStore();
    // game 场景顶层为 game-logo。
    expect(store.selectedLayerId, 'game-logo');
    store.setCurrentScene('movie');
    expect(store.selectedLayerId, 'movie-logo');
    // 删除选中项后回退选中新的顶层可见项。
    store.removeLayer('movie-logo');
    expect(store.selectedLayerId, 'movie-cam');
  });
}
