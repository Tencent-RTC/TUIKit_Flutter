import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_input_view.dart';

void main() {
  testWidgets(
      'Composer keeps draft when hidden and enforces grapheme insertion limit',
      (tester) async {
    final sent = <String>[];
    int dismissals = 0;
    bool presented = true;
    Widget view() => MaterialApp(
        home: MediaQuery(
            data:
                const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 34)),
            child: BarrageInputView(
                isPresented: presented,
                onSend: sent.add,
                onDismiss: () => dismissals++)));
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    final formatter = field.inputFormatters!.single;
    final emoji = '👨‍👩‍👧‍👦' * 201;
    final limited = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
            text: emoji,
            selection: TextSelection.collapsed(offset: emoji.length)));
    expect(limited.text.characters.length, 200);
    final old = TextEditingValue(
        text: '${'a' * 198}Z',
        selection: const TextSelection.collapsed(offset: 198));
    final pasted = formatter.formatEditUpdate(
        old,
        TextEditingValue(
            text: '${'a' * 198}123Z',
            selection: const TextSelection.collapsed(offset: 201)));
    expect(pasted.text, '${'a' * 198}1Z');
    final composing = TextEditingValue(
        text: emoji, composing: TextRange(start: 0, end: emoji.length));
    expect(formatter.formatEditUpdate(TextEditingValue.empty, composing),
        composing);
    expect(
        formatter
            .formatEditUpdate(
                composing, composing.copyWith(composing: TextRange.empty))
            .text
            .characters
            .length,
        200);
    await tester.enterText(find.byType(TextField), 'draft');
    presented = false;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    presented = true;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'draft');
    expect(
        tester
            .getBottomLeft(find.byWidgetPredicate((widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color ==
                    const Color(0xE00C0D12)))
            .dy,
        600 - 34 - 4);
    field.onSubmitted!('draft');
    expect(sent, ['draft']);
    expect(dismissals, 1);
    expect(field.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
