import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/gift/send/gift_send_panel_view.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_live_uikit/src/common/gift/send/gift_send_combo_button.dart';
import 'package:tencent_live_uikit/src/common/gift/send/gift_grid_page_view.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/common/theme/bottom_sheet_background_view.dart';

Gift _gift(String id, {String resourceURL = '', int coins = 99}) => Gift(
      giftID: id,
      name: 'A very long gift name 礼物名称 $id',
      coins: coins,
      iconURL: '',
      resourceURL: resourceURL,
    );

GiftCategory _category(String id, List<Gift> gifts) =>
    GiftCategory(categoryID: id, name: 'Category $id', giftList: gifts);

Finder _cell(String id) => find.descendant(
      of: find.byType(GiftGridPageView),
      matching: find.byKey(ValueKey(id)),
    );

Widget _frame(Widget child,
        {Size size = const Size(390, 844),
        EdgeInsets padding = const EdgeInsets.only(top: 59, bottom: 34),
        double scale = 1}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
          viewPadding: padding,
          textScaler: TextScaler.linear(scale),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    );

void main() {
  testWidgets(
      'panel uses 348 plus one bottom safe area and four relative columns',
      (tester) async {
    final key = GlobalKey<GiftSendPanelViewState>();
    final presentations = <(bool, double)>[];
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_frame(GiftSendPanelView(
      key: key,
      categories: [_category('one', List.generate(8, (i) => _gift('$i')))],
      isLoading: false,
      onSendGift: (_, __) {},
      onAdvancedComboStart: (_) {},
      onPresentationChanged: (visible, height) =>
          presentations.add((visible, height)),
    )));
    key.currentState!.present();
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.byType(BottomSheetBackgroundView));
    expect(sheet, const Rect.fromLTWH(0, 462, 390, 382));
    expect(presentations, [(true, 348.0)]);
    expect(tester.getSize(_cell('0')), const Size(89, 104));
    expect(tester.getTopLeft(_cell('1')).dx - tester.getTopLeft(_cell('0')).dx,
        93);
    expect(tester.getTopLeft(_cell('4')).dy - tester.getTopLeft(_cell('0')).dy,
        106);
    final tabs = tester.getRect(find.ancestor(
      of: find.text('Category one'),
      matching: find.byType(ListView),
    ));
    expect(tester.getCenter(find.text('Category one')).dy, tabs.center.dy);
    final icon = find.descendant(
      of: _cell('0'),
      matching: find.byWidgetPredicate((widget) =>
          widget is SizedBox && widget.width == 44 && widget.height == 44),
    );
    expect(tester.getTopLeft(icon).dy - tester.getTopLeft(_cell('0')).dy, 10);
    await tester.tap(_cell('0'));
    await tester.pump();
    final button = find.ancestor(
      of: find.descendant(of: _cell('0'), matching: find.text('Send')),
      matching: find.descendant(
        of: _cell('0'),
        matching: find.byType(Container),
      ),
    );
    final buttonRect = tester.getRect(button);
    expect(tester.getRect(_cell('0')).bottom - buttonRect.bottom, 6);
    expect(tester.getTopLeft(icon).dy - tester.getTopLeft(_cell('0')).dy, 10);
    final price = find.descendant(of: _cell('0'), matching: find.text('99'));
    expect(buttonRect.top - tester.getRect(price).bottom, 4);
    expect(tester.takeException(), isNull);
  });

  for (final (size, padding, scale) in [
    (const Size(320, 320), const EdgeInsets.only(top: 24, bottom: 20), 1.3),
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34), 2.0),
    (const Size(320, 200), const EdgeInsets.only(top: 24), 1.0),
  ]) {
    testWidgets('panel remains scrollable in $size at text scale $scale',
        (tester) async {
      final key = GlobalKey<GiftSendPanelViewState>();
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_frame(
        GiftSendPanelView(
          key: key,
          categories: [
            _category('long category name',
                List.generate(20, (i) => _gift('$i', coins: 1234567890123)))
          ],
          isLoading: false,
          onSendGift: (_, __) {},
          onAdvancedComboStart: (_) {},
          onPresentationChanged: (_, __) {},
        ),
        size: size,
        padding: padding,
        scale: scale,
      ));
      key.currentState!.present();
      await tester.pumpAndSettle();
      final sheet = tester.getRect(find.byType(BottomSheetBackgroundView));
      expect(sheet.top, greaterThanOrEqualTo(padding.top));
      expect(sheet.bottom, size.height);
      expect(tester.takeException(), isNull);
      if (size.height > 200) {
        await tester.tap(_cell('0'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(PageView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('presentation reports measured short-panel height after layout',
      (tester) async {
    final key = GlobalKey<GiftSendPanelViewState>();
    final events = <(bool, double)>[];
    var ownerHeight = 0.0;
    await tester.binding.setSurfaceSize(const Size(320, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_frame(
      StatefulBuilder(
          builder: (context, updateOwner) => Stack(children: [
                Text('height $ownerHeight'),
                GiftSendPanelView(
                  key: key,
                  categories: [
                    _category('one', [_gift('one')])
                  ],
                  isLoading: false,
                  onSendGift: (_, __) {},
                  onAdvancedComboStart: (_) {},
                  onPresentationChanged: (visible, height) {
                    events.add((visible, height));
                    updateOwner(() => ownerHeight = height);
                  },
                ),
              ])),
      size: const Size(320, 320),
      padding: const EdgeInsets.only(top: 24, bottom: 20),
    ));
    key.currentState!.present();
    await tester.pumpAndSettle();
    final sheet = tester.getRect(find.byType(BottomSheetBackgroundView));
    expect(events, [(true, sheet.height - 20)]);
    expect(ownerHeight, 276);
    expect(tester.takeException(), isNull);
    final dismiss = key.currentState!.dismiss();
    await tester.pumpAndSettle();
    await dismiss;
    expect(events.last, (false, 276.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'category taps keep the target selected during paging and swipes take over',
      (tester) async {
    final key = GlobalKey<GiftSendPanelViewState>();
    final names = ['A', 'B', 'C', 'D'];
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_frame(GiftSendPanelView(
      key: key,
      categories: [
        for (final name in names)
          GiftCategory(
            categoryID: name,
            name: name,
            giftList: [_gift(name)],
          ),
      ],
      isLoading: false,
      onSendGift: (_, __) {},
      onAdvancedComboStart: (_) {},
      onPresentationChanged: (_, __) {},
    )));
    key.currentState!.present();
    await tester.pumpAndSettle();

    void expectSelected(String name) {
      for (final tab in names) {
        expect(tester.widget<Text>(find.text(tab)).style!.fontWeight,
            tab == name ? FontWeight.w700 : FontWeight.w400);
      }
    }

    Rect tabRect(String name) => tester.getRect(find
        .ancestor(of: find.text(name), matching: find.byType(GestureDetector))
        .first);
    final initialRects = [for (final name in names) tabRect(name)];
    final page = tester.widget<PageView>(find.byType(PageView)).controller!;
    await tester.tap(find.text('D'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump();
    expect(page.page, greaterThan(0.5));
    expect(page.page, lessThan(2.5));
    expectSelected('D');
    expect([for (final name in names) tabRect(name)], initialRects);

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expectSelected('C');
    expect(page.page, 2);

    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expectSelected('B');
    expect(page.page, 1);

    await tester.tap(find.text('D'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(page.page, lessThan(3));
    expectSelected(names[page.page!.round()]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'category change cancels combo and a refreshed catalog resets its page',
      (tester) async {
    final key = GlobalKey<GiftSendPanelViewState>();
    var groups = [
      _category('one', [_gift('one')]),
      _category('two', [_gift('two')]),
      _category('three', [_gift('three')]),
    ];
    final sent = <String>[];
    Widget view() => _frame(GiftSendPanelView(
          key: key,
          categories: groups,
          isLoading: false,
          onSendGift: (gift, _) => sent.add(gift.giftID),
          onAdvancedComboStart: (_) {},
          onPresentationChanged: (_, __) {},
        ));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(view());
    key.currentState!.present();
    await tester.pumpAndSettle();
    await tester.tap(_cell('one'));
    await tester.pump();
    await tester.tap(_cell('one'));
    await tester.pump();
    expect(sent, ['one']);
    await tester.tap(find.text('Category two'));
    await tester.pumpAndSettle();
    expect(sent, ['one']);
    expect(_cell('two').hitTestable(), findsOneWidget);
    await tester.drag(find.text('Category two'), const Offset(-240, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category three'));
    await tester.pumpAndSettle();
    groups = [
      _category('new', [_gift('new')])
    ];
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 0);
    expect(_cell('new').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('advanced selection hands combo to owner and dismisses the panel',
      (tester) async {
    final key = GlobalKey<GiftSendPanelViewState>();
    final started = <String>[];
    final sent = <String>[];
    await tester.pumpWidget(_frame(GiftSendPanelView(
      key: key,
      categories: [
        _category('one', [_gift('advanced', resourceURL: 'gift.svga')])
      ],
      isLoading: false,
      onSendGift: (gift, _) => sent.add(gift.giftID),
      onAdvancedComboStart: (gift) => started.add(gift.giftID),
      onPresentationChanged: (_, __) {},
    )));
    key.currentState!.present();
    await tester.pumpAndSettle();
    await tester.tap(_cell('advanced'));
    await tester.pump();
    await tester.tap(_cell('advanced'));
    await tester.pumpAndSettle();
    expect(started, ['advanced']);
    expect(sent, isEmpty);
    expect(key.currentState!.isPresented, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('combo uses immediate touch, 300ms hold scheduling and 2s expiry',
      (tester) async {
    final controller = GiftSendComboButtonController();
    var sent = 0;
    var expired = 0;
    controller.onSendOnce = () => sent++;
    controller.onExpired = () => expired++;
    await tester.pumpWidget(_frame(Center(
        child: SizedBox(
      width: 90,
      height: 110,
      child: GiftSendComboButton(controller: controller),
    ))));
    controller.begin(_gift('one'));
    await tester.pump();
    expect(sent, 1);
    final face = find.descendant(
        of: find.byType(GiftSendComboButton), matching: find.byType(Listener));
    final press = await tester.startGesture(tester.getCenter(face.first));
    expect(sent, 2);
    await tester.pump(const Duration(milliseconds: 300));
    expect(sent, 2);
    await tester.pump(const Duration(milliseconds: 299));
    expect(sent, 2);
    await tester.pump(const Duration(milliseconds: 1));
    expect(sent, 3);
    await tester.pump(const Duration(milliseconds: 300));
    expect(sent, 4);
    await press.up();
    await tester.pump(const Duration(milliseconds: 1999));
    expect(expired, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(expired, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('switching combo gifts does not transfer an old held pointer',
      (tester) async {
    final controller = GiftSendComboButtonController();
    final sent = <String>[];
    controller.onSendOnce = () => sent.add(controller.gift!.giftID);
    await tester.pumpWidget(_frame(Center(
        child: SizedBox(
      width: 90,
      height: 110,
      child: GiftSendComboButton(controller: controller),
    ))));
    controller.begin(_gift('one'));
    await tester.pump();
    final face = find.descendant(
        of: find.byType(GiftSendComboButton), matching: find.byType(Listener));
    final press = await tester.startGesture(tester.getCenter(face.first));
    await tester.pump(const Duration(milliseconds: 300));
    controller.begin(_gift('two'));
    await tester.pump(const Duration(milliseconds: 900));
    expect(sent, ['one', 'one', 'two']);
    await press.up();
    controller.end();
    await tester.pump(const Duration(seconds: 3));
    expect(sent, ['one', 'one', 'two']);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('scrolling a combo cancels held repeats after the initial touch',
      (tester) async {
    final controller = GiftSendComboButtonController();
    var sent = 0;
    controller.onSendOnce = () => sent++;
    await tester.pumpWidget(_frame(Center(
      child: SizedBox(
        width: 110,
        height: 180,
        child: SingleChildScrollView(
          child: SizedBox(
            height: 600,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 90,
                height: 110,
                child: GiftSendComboButton(controller: controller),
              ),
            ),
          ),
        ),
      ),
    )));
    controller.begin(_gift('one'));
    await tester.pump();
    final face = find.descendant(
        of: find.byType(GiftSendComboButton), matching: find.byType(Listener));
    final press = await tester.startGesture(tester.getCenter(face.first));
    expect(sent, 2);
    await press.moveBy(const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 900));
    expect(sent, 2);
    await press.up();
    controller.end();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
      'gift language matches simplified and traditional Chinese variants',
      (tester) async {
    for (final (locale, expected) in [
      (const Locale('zh'), 'zh-Hans'),
      (const Locale('zh', 'CN'), 'zh-Hans'),
      (const Locale('zh', 'SG'), 'zh-Hans'),
      (
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        'zh-Hans'
      ),
      (
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        'zh-Hant'
      ),
      (const Locale('zh', 'TW'), 'zh-Hant'),
      (const Locale('zh', 'HK'), 'zh-Hant'),
      (const Locale('en'), 'en'),
      (const Locale('ja'), 'en'),
    ]) {
      expect(LiveKitResources.giftLanguageCodeForLocale(locale), expected);
    }
  });
}
