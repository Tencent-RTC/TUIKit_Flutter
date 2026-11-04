import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/pusher/living/coguest/seat/pusher_coguest_seat_view_provider.dart';
import 'package:tencent_live_uikit/src/pusher/living/coguest/pusher_coguest_store.dart';
import 'package:tencent_live_uikit/src/pusher/video/pusher_video_view.dart';

class _Controller implements PusherVideoController {
  @override
  final widget = AtomicLiveWidget(controller: AtomicLiveController.create(AtomicLiveViewType.pushView));
  @override
  final coGuestVideoStateNotifier = ValueNotifier(
    const PusherCoGuestVideoState(isLiving: false, showsEmptySeats: false, connectedGuestCount: 0),
  );
  @override
  bool get isCoGuestStageVisible {
    final state = coGuestVideoStateNotifier.value;
    return state.isLiving && (state.showsEmptySeats || state.connectedGuestCount > 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('co-guest background is visible for empty grid2 but not empty floating', () {
    for (final layout in pusherCoGuestLayouts) {
      expect(PusherVideoController.showsCoGuestStage(isLiving: false, layout: layout, connectedGuestCount: 1), isFalse);
      expect(PusherVideoController.showsCoGuestStage(isLiving: true, layout: layout, connectedGuestCount: 1), isTrue);
      expect(PusherVideoController.showsCoGuestStage(isLiving: true, layout: layout, connectedGuestCount: 0),
          layout != CoGuestLayoutTemplate.floatLayout);
    }
    // Empty-seat placeholders stay disabled for grid2; that is independent
    // from letting the underlying live background show through.
    expect(CoGuestLayoutTemplate.dynamicLayout.showsEmptySeats, isFalse);
  });

  testWidgets('owner seat arrival preserves preview; co-guest uses SDK layout', (tester) async {
    // Evaluate composition without mounting mobile-only native video views.
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    final controller = _Controller();
    final view = PusherVideoView(controller: controller);
    Widget renderer() {
      final stage = view.build(context) as ValueListenableBuilder<PusherCoGuestVideoState>;
      final background = stage.builder(context, controller.coGuestVideoStateNotifier.value, stage.child) as ColoredBox;
      return background.child!;
    }

    final preview = renderer();
    controller.coGuestVideoStateNotifier.value =
        const PusherCoGuestVideoState(isLiving: true, showsEmptySeats: false, connectedGuestCount: 0);
    expect(identical(renderer(), preview), isTrue);
    controller.coGuestVideoStateNotifier.value =
        const PusherCoGuestVideoState(isLiving: true, showsEmptySeats: false, connectedGuestCount: 1);
    expect(identical(renderer(), preview), isTrue);
    controller.coGuestVideoStateNotifier.value =
        const PusherCoGuestVideoState(isLiving: true, showsEmptySeats: true, connectedGuestCount: 0);
    expect(identical(renderer(), preview), isTrue);
    controller.coGuestVideoStateNotifier.dispose();
  });
}
