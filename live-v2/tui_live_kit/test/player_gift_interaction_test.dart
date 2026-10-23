import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_display_view.dart';
import 'package:tencent_live_uikit/src/common/gift/send/gift_send_combo_button.dart';
import 'package:tencent_live_uikit/src/common/gift/send/gift_send_panel_view.dart';
import 'package:tencent_live_uikit/src/player/living/living_view.dart';

// Mount the real Living gift layers and callbacks without the unrelated room
// SDK views. Their conditional ordering still comes from LivingView.build.
class _GiftLivingView extends LivingView {
  _GiftLivingView({super.key})
      : super(liveInfo: LiveInfo(), safeAreaInsets: EdgeInsets.zero);

  @override
  State<LivingView> createState() => _GiftLivingState();
}

class _GiftLivingState extends LivingViewState {
  int sentCount = 0;

  @override
  void initState() {
    super.initState();
    floatingComboController.onSendOnce = () => sentCount++;
  }

  @override
  void ensureCommentInfrastructure() {}

  @override
  void ensureLikeInfrastructure() {}

  @override
  void bindChildren() {}

  @override
  void ensureGiftInfrastructure() {
    giftDisplayController = GiftDisplayController(liveID: '');
    giftCategories = [
      GiftCategory(categoryID: 'effects', name: 'Effects', giftList: [
        Gift(
          giftID: 'rocket',
          name: 'Rocket',
          resourceURL: 'https://example.com/rocket.svga',
        ),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final living = super.build(context) as GestureDetector;
    final content = living.child! as AnimatedBuilder;
    return AnimatedBuilder(
      animation: content.animation,
      builder: (context, _) {
        final stack = content.builder(context, null) as Stack;
        return Stack(
          fit: stack.fit,
          children: stack.children.where((child) {
            if (child is GiftSendPanelView) return true;
            return child is Positioned &&
                (child.child is GiftDisplayView ||
                    child.child is GiftSendComboButton);
          }).toList(),
        );
      },
    );
  }
}

void main() {
  testWidgets('advanced combo survives the send panel closing and layer move',
      (tester) async {
    final key = GlobalKey<_GiftLivingState>();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: _GiftLivingView(key: key)));
    final state = key.currentState!;
    state.giftPanelKey.currentState!.present();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rocket'));
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.pump();
    final combo = find.byWidgetPredicate((widget) =>
        widget is GiftSendComboButton &&
        identical(widget.controller, state.floatingComboController));
    final originalState = tester.state(combo);
    expect(state.sentCount, 1);
    expect(state.floatingComboController.isRunning, isTrue);

    // The sheet finishes closing well before the two-second combo expires.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(state.isGiftPanelPresented, isFalse);
    expect(identical(tester.state(combo), originalState), isTrue);
    expect(state.floatingComboController.isRunning, isTrue);
    expect(
        find.descendant(of: combo, matching: find.text('1')), findsOneWidget);

    await tester.tap(
        find.descendant(of: combo, matching: find.byType(Listener)).first);
    await tester.pump();
    expect(state.sentCount, 2);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(state.floatingComboController.isRunning, isTrue);
    await tester.pump(const Duration(milliseconds: 600));
    expect(state.floatingComboGift, isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
