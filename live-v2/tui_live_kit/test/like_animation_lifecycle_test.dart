import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/like/like_animation_view.dart';

void main() {
  _testLikeSending();
  testWidgets('replacement controller starts its own animation timeline', (tester) async {
    final first = LikeAnimationController();
    final second = LikeAnimationController();
    Widget view(LikeAnimationController controller) => MaterialApp(home: LikeAnimationView(controller: controller));
    await tester.pumpWidget(view(first));
    first.showStageLike(point: const Offset(80, 100), auxiliaryOrigin: const Offset(200, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    second.showStageLike(point: const Offset(80, 100), auxiliaryOrigin: const Offset(200, 300));
    await tester.pumpWidget(view(second));
    await tester.pump(const Duration(milliseconds: 180));
    final mainImage =
        find.byWidgetPredicate((widget) => widget is Positioned && widget.width == 52 && widget.height == 52);
    expect(mainImage, findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
    expect(mainImage, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    second.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('remount does not resume reactions queued before removal', (tester) async {
    final controller = LikeAnimationController();
    Widget view() => MaterialApp(home: LikeAnimationView(controller: controller));
    await tester.pumpWidget(view());
    controller.showReceivedLikes(count: 6, auxiliaryOrigin: const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(Image), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(Image), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('replacing incoming stream cancels the previous pending burst', (tester) async {
    final controller = LikeAnimationController();
    final oldCounts = StreamController<int>();
    final newCounts = StreamController<int>();
    Widget view(Stream<int> counts) => MaterialApp(
          home: LikeAnimationView(
            controller: controller,
            receivedLikeCounts: counts,
            auxiliaryOriginProvider: () => const Offset(200, 300),
          ),
        );
    await tester.pumpWidget(view(oldCounts.stream));
    oldCounts.add(6);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(Image), findsWidgets);
    await tester.pumpWidget(view(newCounts.stream));
    oldCounts.add(6);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(Image), findsNothing);
    newCounts.add(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(Image), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await oldCounts.close();
      await newCounts.close();
    });
    controller.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Clearing likes cancels delayed reactions before and during burst', (tester) async {
    final controller = LikeAnimationController();
    await tester.pumpWidget(MaterialApp(home: LikeAnimationView(controller: controller)));
    controller.showReceivedLikes(count: 6, auxiliaryOrigin: const Offset(200, 300));
    controller.removeAllAnimations();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Image), findsNothing);
    controller.showReceivedLikes(count: 6, auxiliaryOrigin: const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(Image), findsWidgets);
    controller.removeAllAnimations();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Image), findsNothing);
    controller.showLocalLike(point: const Offset(100, 100), auxiliaryOrigin: const Offset(200, 300));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    expect(tester.takeException(), isNull);
  });
}

class _ScheduledTimer implements Timer {
  _ScheduledTimer(this.deadline, this.callback);
  final Duration deadline;
  final void Function() callback;
  @override
  bool isActive = true;
  @override
  int tick = 0;
  @override
  void cancel() => isActive = false;

  // A platform callback may already be queued when cancellation happens.
  void deliver() {
    isActive = false;
    tick++;
    callback();
  }
}

class _Clock {
  Duration now = Duration.zero;
  final timers = <_ScheduledTimer>[];
  LikeSender sender() => LikeSender(now: () => now);
  void run(void Function() body) =>
      runZoned(body, zoneSpecification: ZoneSpecification(createTimer: (self, parent, zone, delay, callback) {
        final timer = _ScheduledTimer(now + delay, callback);
        timers.add(timer);
        return timer;
      }));
}

void _testLikeSending() {
  test('first send is immediate; bursts share the original six-second deadline', () {
    final clock = _Clock();
    clock.run(() {
      final sent = <int>[];
      final sender = clock.sender();
      sender.sendLike();
      sender.activate(sent.add);
      sender.sendLike();
      expect(sent, [1]);
      clock.now = const Duration(seconds: 1);
      sender.sendLike();
      clock.now = const Duration(seconds: 5);
      sender.sendLike();
      expect(clock.timers, hasLength(1));
      expect(clock.timers.single.deadline, const Duration(seconds: 6));
      clock.now = const Duration(seconds: 6);
      clock.timers.single.deliver();
      expect(sent, [1, 2]);
      sender.deactivate();
    });
  });

  test('exact boundary sends immediately and invalidates a queued timer in the same activation', () {
    final clock = _Clock();
    clock.run(() {
      final sent = <int>[];
      final sender = clock.sender()..activate(sent.add);
      sender.sendLike();
      clock.now = const Duration(seconds: 1);
      sender.sendLike();
      final queued = clock.timers.single;
      clock.now = const Duration(seconds: 6);
      sender.sendLike();
      expect(sent, [1, 2]);
      sender.sendLike();
      queued.deliver();
      expect(sent, [1, 2]);
      expect(clock.timers.last.deadline, const Duration(seconds: 12));
      clock.now = const Duration(seconds: 12);
      clock.timers.last.deliver();
      expect(sent, [1, 2, 1]);
      sender.deactivate();
    });
  });

  test('switching rooms flushes only the old room and ordinary exit flushes once', () {
    final clock = _Clock();
    clock.run(() {
      final oldRoom = <int>[];
      final newRoom = <int>[];
      final sender = clock.sender()..activate(oldRoom.add);
      sender.sendLike();
      sender.sendLike();
      sender.activate(newRoom.add);
      expect(oldRoom, [1, 1]);
      sender.sendLike();
      sender.sendLike();
      sender.deactivate();
      sender.deactivate();
      sender.sendLike();
      for (final timer in clock.timers) {
        timer.deliver();
      }
      expect(newRoom, [1, 1]);
      expect(oldRoom, [1, 1]);
    });
  });

  test('start failure discards pending likes and stale callbacks cannot affect reactivation', () {
    final clock = _Clock();
    clock.run(() {
      final sent = <int>[];
      final sender = clock.sender()..activate(sent.add);
      sender.sendLike();
      sender.sendLike();
      final oldTask = clock.timers.single;
      sender.deactivate(discardPending: true);
      sender.activate(sent.add); // Same room and same action, different activation.
      sender.sendLike();
      sender.sendLike();
      oldTask.deliver();
      expect(sent, [1, 1]);
      clock.now = const Duration(seconds: 6);
      clock.timers.last.deliver();
      expect(sent, [1, 1, 1]);
      sender.deactivate();
    });
  });

  test('exit clears state before invoking SDK action, including reentrant deactivation', () {
    final clock = _Clock();
    clock.run(() {
      final sent = <int>[];
      final sender = clock.sender();
      sender.activate((count) {
        sent.add(count);
        if (sent.length > 1) sender.deactivate();
      });
      sender.sendLike();
      sender.sendLike();
      sender.deactivate();
      expect(sent, [1, 1]);
    });
  });

  test('Pusher and Player instances have independent counts and windows', () {
    final clock = _Clock();
    clock.run(() {
      final host = <int>[];
      final viewer = <int>[];
      final pusher = clock.sender()..activate(host.add);
      final player = clock.sender()..activate(viewer.add);
      pusher.sendLike();
      pusher.sendLike();
      clock.now = const Duration(seconds: 2);
      player.sendLike();
      player.sendLike();
      expect(clock.timers.map((timer) => timer.deadline), [const Duration(seconds: 6), const Duration(seconds: 8)]);
      pusher.deactivate(discardPending: true);
      player.deactivate();
      expect(host, [1]);
      expect(viewer, [1, 1]);
    });
  });
}
