import 'support/listener_probe.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/pusher/living/music/pusher_music_view.dart';

class Music implements MusicStore, MusicState {
  @override
  final ValueProbe<String?> playURL = ValueProbe<String?>(null);
  @override
  final ValueProbe<MusicPlayStatus> playStatus =
      ValueProbe(MusicPlayStatus.idle);
  @override
  MusicState get musicState => this;
  int stopped = 0;
  @override
  Future<CompletionHandler> startPlay(AudioMusicParam param) async {
    playURL.value = param.path;
    playStatus.value = MusicPlayStatus.playing;
    return CompletionHandler();
  }

  @override
  void pausePlay() {
    playStatus.value = MusicPlayStatus.paused;
  }

  @override
  void resumePlay() {
    playStatus.value = MusicPlayStatus.playing;
  }

  @override
  void stopPlay() {
    stopped++;
    playStatus.value = MusicPlayStatus.idle;
  }

  @override
  void setPitch(double pitch) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('initial suspension blocks playback and restores only its track',
      (tester) async {
    final music = Music();
    const url =
        'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/PositiveHappyAdvertising.mp3';
    music.playURL.value = url;
    music.playStatus.value = MusicPlayStatus.playing;
    Widget view(bool suspended) => MaterialApp(
        home: PusherMusicView(
            liveID: 'r',
            isPresented: true,
            isSuspended: suspended,
            musicStore: music,
            onDismiss: () {}));
    await tester.pumpWidget(view(true));
    await tester.pumpAndSettle();
    expect(music.playStatus.value, MusicPlayStatus.paused);
    await tester.tap(find.text('06:06'));
    expect(music.playURL.value, url);
    await tester.pumpWidget(view(false));
    expect(music.playStatus.value, MusicPlayStatus.playing);
    await tester.pumpWidget(const SizedBox());
    expect(music.stopped, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suspension resumes only its own track and rejects late playback',
      (tester) async {
    final music = Music();
    final key = GlobalKey<PusherMusicViewState>();
    await tester.pumpWidget(MaterialApp(
        home: PusherMusicView(
            key: key,
            liveID: 'r',
            isPresented: true,
            musicStore: music,
            onDismiss: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.text('05:45'));
    key.currentState!.setSuspended(true);
    expect(music.playStatus.value, MusicPlayStatus.paused);
    music.playStatus.value = MusicPlayStatus.playing;
    expect(music.playStatus.value, MusicPlayStatus.paused);
    key.currentState!.setSuspended(false);
    expect(music.playStatus.value, MusicPlayStatus.playing);
    music.pausePlay();
    key.currentState!.setSuspended(true);
    key.currentState!.setSuspended(false);
    expect(music.playStatus.value, MusicPlayStatus.paused);
    music.resumePlay();
    key.currentState!.setSuspended(true);
    music.playURL.value = 'different track';
    key.currentState!.setSuspended(false);
    expect(music.playStatus.value, MusicPlayStatus.paused);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('four music dots move, pause, and resume after reopening',
      (tester) async {
    final music = Music();
    final key = GlobalKey<PusherMusicViewState>();
    Widget view(bool shown) => MaterialApp(
        home: PusherMusicView(
            key: key,
            liveID: 'r',
            isPresented: shown,
            musicStore: music,
            onDismiss: () {}));
    final dots = find.byWidgetPredicate((widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == const Color(0xFF7DE8FF));
    List<Offset> centers() => [
          for (int i = 0; i < 4; i++) tester.getCenter(dots.at(i)),
        ];
    Future<void> expectMoving() async {
      expect(dots, findsNWidgets(4));
      final before = centers();
      await tester.pump(const Duration(milliseconds: 110));
      final after = centers();
      for (int i = 0; i < 4; i++) {
        expect(after[i].dy, isNot(closeTo(before[i].dy, .001)));
      }
    }

    await tester.pumpWidget(view(true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('05:45'));
    await tester.pump();
    await expectMoving();
    music.pausePlay();
    await tester.pump();
    final paused = centers();
    await tester.pump(const Duration(milliseconds: 200));
    expect(centers(), paused);
    music.resumePlay();
    await tester.pump();
    await expectMoving();
    await tester.pumpWidget(view(false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(dots, findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    expect(music.stopped, 0);
    await tester.pumpWidget(view(true));
    await tester.pump(const Duration(milliseconds: 300));
    await expectMoving();
    await tester.pumpWidget(const SizedBox());
    expect(music.stopped, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'music survives panel dismissal and stops once on Living deactivation',
      (tester) async {
    final music = Music();
    final key = GlobalKey<PusherMusicViewState>();
    Widget view(bool shown) => MaterialApp(
        home: PusherMusicView(
            key: key,
            liveID: 'r',
            isPresented: shown,
            musicStore: music,
            onDismiss: () {}));
    await tester.pumpWidget(view(true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('05:45'));
    await tester.pump();
    expect(music.playStatus.value, MusicPlayStatus.playing);
    await tester.pumpWidget(view(false));
    await tester.pump(const Duration(milliseconds: 250));
    expect(music.stopped, 0);
    expect(music.playURL.isObserved, isTrue);
    key.currentState!.deactivateMusic();
    expect(music.stopped, 1);
    expect(music.playURL.isObserved, isFalse);
    await tester.pumpWidget(const SizedBox());
    expect(music.stopped, 1);
    expect(tester.takeException(), isNull);
  });
}
