import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_live_uikit/src/pusher/living/coguest/control_panel/pusher_coguest_user_section_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/common/theme/bottom_sheet_view.dart' as kit;
import 'package:tencent_live_uikit/src/pusher/living/coguest/pusher_coguest_store.dart';
import 'package:tencent_live_uikit/src/pusher/living/coguest/control_panel/pusher_coguest_settings_view.dart';

class _Actions implements PusherCoGuestActionHandling {
  final List<Symbol> calls = [];
  final List<Invocation> invocations = [];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    invocations.add(invocation);
    if (invocation.memberName == #disconnect || invocation.memberName == #toggleRemoteMicrophone) {
      return Future<void>.value();
    }
    return null;
  }
}

void main() {
  testWidgets('English layout captions fit two lines with bounded shrinking', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    for (final width in [320.0, 390.0, 430.0]) {
      await tester.pumpWidget(MaterialApp(
          home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                  width: width,
                  height: 568,
                  child: PusherCoGuestSettingsView(
                      state: PusherCoGuestState(), actionHandler: _Actions(), onDismiss: () {})))));
      await tester.pumpAndSettle();
      for (final layout in pusherCoGuestLayouts) {
        final label = tester.widget<Text>(find.text(layout.title));
        expect(label.maxLines, 2);
        expect(label.style!.fontSize, inInclusiveRange(13 * 0.85, 13));
        expect(find.ancestor(of: find.text(layout.title), matching: find.byType(FittedBox)), findsNothing);
      }
      final slots = [
        for (final layout in pusherCoGuestLayouts)
          tester.getRect(find.ancestor(of: find.text(layout.title), matching: find.byType(GestureDetector)).first)
      ];
      expect(slots.map((rect) => rect.height), everyElement(48));
      expect(slots.map((rect) => rect.width), everyElement(closeTo((width - 72) / 2, 0.01)));
      expect(slots[1].left - slots[0].right, closeTo(8, 0.01));
      expect(slots[2].top - slots[0].bottom, closeTo(8, 0.01));
      expect(slots[2].left, slots[0].left);
      expect(slots[3].left, slots[1].left);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('CoGuest drawer respects host bounds and disables all-pending bulk action', (tester) async {
    final actions = _Actions();
    final state =
        PusherCoGuestState(connected: [const PusherCoGuestUser(userID: 'g', userName: 'Guest', avatarURL: '')]);
    Widget view() => MaterialApp(
        home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
                width: 320,
                height: 500,
                child: PusherCoGuestSettingsView(state: state, actionHandler: actions, onDismiss: () {}))));
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(tester.widget<kit.BottomSheetView>(find.byType(kit.BottomSheetView)).sheetHeight, lessThanOrEqualTo(420));
    final endAll = find.text(LiveKitResources.localizedString('tuilivekit.pusher.coguest.end_all'));
    await tester.tap(endAll);
    expect(actions.calls, [#endAllConnections]);
    state.pendingUserIDs.add('g');
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    await tester.tap(endAll);
    expect(actions.calls, [#endAllConnections]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Member rows survive device changes and reorder by user identity', (tester) async {
    PusherCoGuestRow row(String id, {DeviceStatus mic = DeviceStatus.off, String? name}) => PusherCoGuestRow(
        user: PusherCoGuestUser(userID: id, userName: name ?? id, avatarURL: '', microphoneStatus: mic),
        actionTitle: 'End',
        actionStyle: PusherCoGuestActionStyle.destructive,
        isPending: false,
        isEnabled: true);
    Widget view(List<PusherCoGuestRow> rows) => MaterialApp(
        home: SizedBox(
            height: 240,
            child: PusherCoGuestUserSectionView(title: 'Members', emptyText: '', rows: rows, onAction: (_) {})));
    await tester.pumpWidget(view([row('a'), row('b')]));
    final original = tester.widget(find.byKey(const ValueKey('a')));
    final element = tester.element(find.byKey(const ValueKey('a')));
    await tester.pumpWidget(view([row('a', mic: DeviceStatus.on), row('b')]));
    expect(identical(tester.widget(find.byKey(const ValueKey('a'))), original), isTrue);
    await tester.pumpWidget(view([row('b'), row('a', name: 'Renamed')]));
    expect(identical(tester.element(find.byKey(const ValueKey('a'))), element), isTrue);
    expect(find.text('Renamed'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const ValueKey('a'))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('b'))).dy));
    expect(tester.takeException(), isNull);
  });
  testWidgets('member actions preserve grouping, full-capacity and pending rules after rebuild', (tester) async {
    PusherCoGuestUser user(String id) => PusherCoGuestUser(userID: id, userName: id, avatarURL: '');
    final actions = _Actions();
    final state = PusherCoGuestState(
      layout: CoGuestLayoutTemplate.floatLayout,
      connected: List.generate(6, (index) => user('c$index')),
      applicants: [user('applicant')],
      invitees: [user('invitee')],
      candidates: [user('candidate')],
      pendingUserIDs: {'c0', 'invitee'},
    );
    Widget view() => MaterialApp(
            home: PusherCoGuestSettingsView(
          state: state,
          actionHandler: actions,
          onDismiss: () {},
        ));
    List<PusherCoGuestUserSectionView> sections() => tester
        .widgetList<PusherCoGuestUserSectionView>(
          find.byType(PusherCoGuestUserSectionView),
        )
        .toList();
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    final groups = sections();
    expect(groups, hasLength(3));
    expect(groups[0].rows.first.isPending, isTrue);
    expect(groups[0].rows.first.actionStyle, PusherCoGuestActionStyle.destructive);
    expect(groups[1].rows.single.isEnabled, isFalse);
    expect(groups[1].rows.single.actionStyle, PusherCoGuestActionStyle.primary);
    expect(groups[2].rows.map((row) => row.user.userID), ['invitee', 'candidate']);
    expect(groups[2].rows.map((row) => row.isEnabled), [true, false]);
    expect(groups[2].rows.map((row) => row.isPending), [true, false]);
    expect(groups[2].rows.map((row) => row.actionStyle), [
      PusherCoGuestActionStyle.destructive,
      PusherCoGuestActionStyle.primary,
    ]);
    expect(groups[2].rows.map((row) => row.actionTitle), [
      LiveKitResources.localizedString('tuilivekit.pusher.coguest.cancel_invitation'),
      LiveKitResources.localizedString('tuilivekit.pusher.coguest.invite'),
    ]);

    state.connected = [user('c0')];
    state.pendingUserIDs.clear();
    state.isUpdatingLayout = true;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    final updated = sections();
    expect(updated[1].rows.single.isEnabled, isTrue);
    expect(updated[2].rows.last.isEnabled, isTrue);
    updated[0].onAction('c0');
    updated[1].onAction('applicant');
    updated[2].onAction('invitee');
    updated[2].onAction('candidate');
    expect(actions.calls, [#disconnect, #acceptApplication, #cancelInvitation, #invite]);
    expect(actions.invocations.map((call) => call.positionalArguments.single),
        ['c0', 'applicant', 'invitee', 'candidate']);
    for (final layout in pusherCoGuestLayouts) {
      final button = tester.widget<GestureDetector>(find
          .ancestor(
            of: find.text(layout.title),
            matching: find.byType(GestureDetector),
          )
          .first);
      expect(button.onTap, isNull);
    }
    state.isUpdatingLayout = false;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    await tester.tap(find.text(CoGuestLayoutTemplate.gridLayout.title));
    expect(actions.calls.last, #selectLayout);
    expect(actions.invocations.last.positionalArguments, [CoGuestLayoutTemplate.gridLayout]);
    expect(tester.takeException(), isNull);
  });
}
