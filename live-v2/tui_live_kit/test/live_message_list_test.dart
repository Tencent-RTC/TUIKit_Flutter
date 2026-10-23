import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_stream_view.dart';

void main() {
  testWidgets('Long nicknames keep 20 complete characters and wrap with badges',
      (tester) async {
    const emoji = '👨‍👩‍👧‍👦';
    final names = [
      '',
      '短名',
      '昵称\n换行',
      emoji * 30,
      for (final length in [20, 25, 30]) ...[
        '测' * length,
        'a' * length,
        '1' * length,
      ],
    ];
    final rowFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan != null);
    for (final scale in [1.0, 1.5]) {
      for (final host in [false, true]) {
        for (final level in <int?>[null, 25]) {
          for (final name in names) {
            final message = LiveMessage(
                id: 'm',
                userName: name,
                content: 'ok',
                level: level,
                isHost: host);
            for (final width in [
              314.0,
              216.0,
              scale == 1 ? 136.0 : 176.0,
              314.0
            ]) {
              await tester.pumpWidget(MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Center(
                      child: SizedBox(
                    width: width,
                    height: 132,
                    child: BarrageStreamView(messages: [message]),
                  )),
                ),
              ));
              await tester.pumpAndSettle();
              final text = tester.widget<Text>(rowFinder);
              final span = text.textSpan! as TextSpan;
              final badgeCount = (level == null ? 0 : 1) + (host ? 1 : 0);
              expect(span.children!.whereType<WidgetSpan>().length, badgeCount);
              final visible = span.toPlainText().replaceAll('\u200B', '');
              expect(visible, endsWith('：ok'));
              expect(visible, isNot(contains('\n')));
              expect(text.semanticsLabel, '$name：ok');
              expect(message.userName, name);
              if (name == '短名' && width >= 216) {
                expect(visible, contains('短名：'));
              }
              if (name == emoji * 30) {
                final nickname = span.children![badgeCount] as TextSpan;
                expect(nickname.text!.replaceAll('\u200B', ''), endsWith('…：'));
                expect(
                    nickname.text!
                        .replaceAll('\u200B', '')
                        .replaceAll(emoji, ''),
                    '…：');
                expect(
                    nickname.text!.replaceAll('\u200B', '').characters.length,
                    22);
              }
              expect(
                  tester.getBottomLeft(rowFinder).dy,
                  lessThanOrEqualTo(tester
                          .getBottomLeft(find.byType(SingleChildScrollView))
                          .dy +
                      0.5));
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    }
  });

  testWidgets(
      'Message display truncates at 200 graphemes without mutating input',
      (tester) async {
    const emoji = '👨‍👩‍👧‍👦';
    final raw = '${'a' * 199}${emoji}tail';
    final message = LiveMessage(id: 'm', userName: 'U', content: raw, level: 0);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: SizedBox(
                width: 300,
                height: 500,
                child: BarrageStreamView(messages: [message])))));
    await tester.pumpAndSettle();
    final row = tester.widget<Text>(find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan != null));
    expect(row.textSpan!.toPlainText().replaceAll('\u200B', ''),
        endsWith('${'a' * 199}$emoji...'));
    expect(message.content, raw);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Width reflow keeps the reading row and follows newest at bottom',
      (tester) async {
    final messages = List.generate(
        30,
        (i) => LiveMessage(
            id: '$i',
            level: null,
            userName: 'U',
            content: 'long comment ' * 8));
    Widget view(double width) => MaterialApp(
        home: Center(
            child: SizedBox(
                width: width,
                height: 240,
                child: BarrageStreamView(messages: messages))));
    await tester.pumpWidget(view(360));
    await tester.pumpAndSettle();
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    final rows = find.byWidgetPredicate((w) => w is Text && w.textSpan != null);
    final wideHeight = tester.getSize(rows.last).height;
    expect(tester.getSize(rows.last).width, greaterThan(284));
    await tester.pumpWidget(view(200));
    await tester.pumpAndSettle();
    expect(tester.getSize(rows.last).height, greaterThan(wideHeight));
    expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, .5));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 617));
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final visible = rows
        .evaluate()
        .where((e) =>
            tester.getRect(find.byElementPredicate((x) => x == e)).bottom >=
            viewport.top)
        .first;
    final anchor = find.byElementPredicate((e) => e == visible);
    final oldTop = tester.getTopLeft(anchor).dy;
    await tester.pumpWidget(view(312));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(anchor).dy, closeTo(oldTop, .5));
    expect(tester.takeException(), isNull);
  });
}
