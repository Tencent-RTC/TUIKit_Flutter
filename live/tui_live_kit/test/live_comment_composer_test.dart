import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_input_view.dart';
import 'package:tencent_live_uikit/src/common/barrage/emoji/barrage_emoji_converter.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/common/theme/live_theme.dart';

void main() {
  test('Emoji conversion preserves unknown tokens and truncates whole emoji',
      () {
    expect(BarrageEmoji.all, hasLength(62));
    expect(BarrageEmoji.all.map((emoji) => emoji.token).toList(), <String>[
      '[TUIEmoji_Smile]',
      '[TUIEmoji_Expect]',
      '[TUIEmoji_Blink]',
      '[TUIEmoji_Guffaw]',
      '[TUIEmoji_KindSmile]',
      '[TUIEmoji_Haha]',
      '[TUIEmoji_Cheerful]',
      '[TUIEmoji_Speechless]',
      '[TUIEmoji_Amazed]',
      '[TUIEmoji_Sorrow]',
      '[TUIEmoji_Complacent]',
      '[TUIEmoji_Silly]',
      '[TUIEmoji_Lustful]',
      '[TUIEmoji_Giggle]',
      '[TUIEmoji_Kiss]',
      '[TUIEmoji_Wail]',
      '[TUIEmoji_TearsLaugh]',
      '[TUIEmoji_Trapped]',
      '[TUIEmoji_Mask]',
      '[TUIEmoji_Fear]',
      '[TUIEmoji_BareTeeth]',
      '[TUIEmoji_FlareUp]',
      '[TUIEmoji_Yawn]',
      '[TUIEmoji_Tact]',
      '[TUIEmoji_Stareyes]',
      '[TUIEmoji_ShutUp]',
      '[TUIEmoji_Sigh]',
      '[TUIEmoji_Hehe]',
      '[TUIEmoji_Silent]',
      '[TUIEmoji_Surprised]',
      '[TUIEmoji_Askance]',
      '[TUIEmoji_Ok]',
      '[TUIEmoji_Shit]',
      '[TUIEmoji_Monster]',
      '[TUIEmoji_Daemon]',
      '[TUIEmoji_Rage]',
      '[TUIEmoji_Fool]',
      '[TUIEmoji_Pig]',
      '[TUIEmoji_Cow]',
      '[TUIEmoji_Ai]',
      '[TUIEmoji_Skull]',
      '[TUIEmoji_Bombs]',
      '[TUIEmoji_Coffee]',
      '[TUIEmoji_Cake]',
      '[TUIEmoji_Beer]',
      '[TUIEmoji_Flower]',
      '[TUIEmoji_Watermelon]',
      '[TUIEmoji_Rich]',
      '[TUIEmoji_Heart]',
      '[TUIEmoji_Moon]',
      '[TUIEmoji_Sun]',
      '[TUIEmoji_Star]',
      '[TUIEmoji_RedPacket]',
      '[TUIEmoji_Celebrate]',
      '[TUIEmoji_Bless]',
      '[TUIEmoji_Fortune]',
      '[TUIEmoji_Convinced]',
      '[TUIEmoji_Prohibit]',
      '[TUIEmoji_666]',
      '[TUIEmoji_857]',
      '[TUIEmoji_Knife]',
      '[TUIEmoji_Like]',
    ]);
    expect(BarrageEmoji.all.map((emoji) => emoji.token).toSet(), hasLength(62));
    expect(
        BarrageEmoji.all.map((emoji) => emoji.marker).toSet(), hasLength(62));
    final smile = BarrageEmoji.all.first;
    const unknown = '[TUIEmoji_NotRegistered]';
    final raw = 'A${smile.token}$unknown${smile.token}';
    final normalized = BarrageEmojiConverter.normalize(raw);
    expect(BarrageEmojiConverter.visibleLength(raw),
        3 + unknown.characters.length);
    expect(BarrageEmojiConverter.serialize(normalized), raw);
    final prefixed = BarrageEmojiConverter.visiblePrefix(
        '${'a' * 199}${smile.token}tail', 200);
    expect(BarrageEmojiConverter.visibleLength(prefixed), 200);
    expect(BarrageEmojiConverter.serialize(prefixed),
        '${'a' * 199}${smile.token}');
    expect(BarrageEmojiConverter.visibleLength('[TUIEmoji_Smile'),
        '[TUIEmoji_Smile'.length);
    expect(
        BarrageEmojiConverter.visibleLength('${smile.token}${smile.token}'), 2);
  });

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
        tester.getBottomLeft(find.byKey(const ValueKey('barrageInputBar'))).dy,
        600 - 34 - 10);
    field.onSubmitted!('draft');
    expect(sent, ['draft']);
    expect(dismissals, 1);
    expect(field.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Direct emoji mode pages, inserts and sends built-in tokens',
      (tester) async {
    final sent = <String>[];
    var dismissals = 0;
    await tester.pumpWidget(MaterialApp(
        home: BarrageInputView(
      initialInputMode: BarrageInputMode.emoji,
      onDismiss: () => dismissals++,
      onSend: sent.add,
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('barrageEmojiGrid')), findsOneWidget);
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, BarrageEmoji.all.first.marker);
    await tester.tap(find.bySemanticsLabel(LiveKitResources.localizedString(
        'tuilivekit.comment.emoji_page_down')));
    await tester.pumpAndSettle();
    expect(dismissals, 0);
    await tester.tap(
        find.text(LiveKitResources.localizedString('tuilivekit.common.send')));
    expect(sent, <String>[BarrageEmoji.all.first.token]);
    expect(dismissals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reopening emoji presentation reports geometry again',
      (tester) async {
    var presented = true;
    final bottoms = <double>[];
    Widget view() => MaterialApp(
          home: BarrageInputView(
            isPresented: presented,
            initialInputMode: BarrageInputMode.emoji,
            onDismiss: () {},
            onInputBarBottomChanged: bottoms.add,
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(bottoms, <double>[274]);
    expect(
        tester.getBottomLeft(find.byKey(const ValueKey('barrageInputBar'))).dy,
        600 - 274 - 10);
    presented = false;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    presented = true;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(bottoms, <double>[274, 274]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Composing text keeps offsets and blocks panel editing',
      (tester) async {
    final smile = BarrageEmoji.all.first;
    await tester.pumpWidget(MaterialApp(
      home: BarrageInputView(
          initialInputMode: BarrageInputMode.emoji, onDismiss: () {}),
    ));
    await tester.pumpAndSettle();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.value = TextEditingValue(
      text: smile.token,
      selection: TextSelection.collapsed(offset: smile.token.length),
      composing: TextRange(start: 0, end: smile.token.length),
    );
    await tester.pump();
    await tester.tap(find.byType(InkWell).first);
    await tester.tap(find.bySemanticsLabel(
        LiveKitResources.localizedString('tuilivekit.comment.emoji_delete')));
    expect(editable.controller.text, smile.token);
    expect(editable.controller.value.composing,
        TextRange(start: 0, end: smile.token.length));
    final span = editable.controller.buildTextSpan(
      context: tester.element(find.byType(EditableText)),
      style: const TextStyle(fontSize: 14),
      withComposing: true,
    );
    expect(span.toPlainText(), smile.token);
    expect(
        span.children!.whereType<TextSpan>().any((child) =>
            child.text == smile.token &&
            child.style?.decoration == TextDecoration.underline),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keyboard inset positions input directly at keyboard top',
      (tester) async {
    var keyboardInset = 0.0;
    Widget view() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: BarrageInputView(onDismiss: () {}),
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    keyboardInset = 300;
    await tester.pumpWidget(view());
    await tester.pump();
    expect(
        tester.getBottomLeft(find.byKey(const ValueKey('barrageInputBar'))).dy,
        290);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Emoji to keyboard keeps input in place until keyboard inset arrives',
      (tester) async {
    var keyboardInset = 0.0;
    Widget view() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: BarrageInputView(
                initialInputMode: BarrageInputMode.emoji, onDismiss: () {}),
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    final inputBar = find.byKey(const ValueKey('barrageInputBar'));
    expect(tester.getBottomLeft(inputBar).dy, 316);
    await tester.tap(find.bySemanticsLabel(
        LiveKitResources.localizedString('tuilivekit.comment.keyboard_input')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getBottomLeft(inputBar).dy, 316);
    keyboardInset = 100;
    await tester.pumpWidget(view());
    await tester.pump();
    expect(tester.getBottomLeft(inputBar).dy, 316);
    keyboardInset = 300;
    await tester.pumpWidget(view());
    await tester.pump();
    expect(tester.getBottomLeft(inputBar).dy, 290);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(inputBar).dy, 290);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Emoji to keyboard settles at a shorter final keyboard height',
      (tester) async {
    var keyboardInset = 0.0;
    Widget view() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: BarrageInputView(
                initialInputMode: BarrageInputMode.emoji, onDismiss: () {}),
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    final inputBar = find.byKey(const ValueKey('barrageInputBar'));
    await tester.tap(find.bySemanticsLabel(
        LiveKitResources.localizedString('tuilivekit.comment.keyboard_input')));
    await tester.pump();
    keyboardInset = 250;
    await tester.pumpWidget(view());
    await tester.pump();
    expect(tester.getBottomLeft(inputBar).dy, 316);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(tester.getBottomLeft(inputBar).dy, 340);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Emoji presentation keeps the whole input bar in a short window',
      (tester) async {
    final bottoms = <double>[];
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 240,
          child: BarrageInputView(
              initialInputMode: BarrageInputMode.emoji,
              onDismiss: () {},
              onInputBarBottomChanged: bottoms.add),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final inputBar = find.byKey(const ValueKey('barrageInputBar'));
    final outerBar =
        tester.element(inputBar).findAncestorWidgetOfExactType<ColoredBox>()!;
    expect(tester.getTopLeft(find.byWidget(outerBar)).dy, 360);
    expect(bottoms, <double>[188]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Emoji mode reuses the last keyboard height without safe area jumps',
      (tester) async {
    var keyboardInset = 0.0;
    var bottomSafeArea = 42.0;
    Widget view() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              viewPadding: EdgeInsets.only(bottom: bottomSafeArea),
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: BarrageInputView(
                initialInputMode: BarrageInputMode.emoji, onDismiss: () {}),
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    final inputBar = find.byKey(const ValueKey('barrageInputBar'));
    expect(tester.getBottomLeft(inputBar).dy, 600 - 274 - 10 - 42);
    await tester.tap(find.bySemanticsLabel(
        LiveKitResources.localizedString('tuilivekit.comment.keyboard_input')));
    await tester.pump();
    keyboardInset = 319;
    bottomSafeArea = 0;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(inputBar).dy, 271);
    await tester.tap(find.bySemanticsLabel(
        LiveKitResources.localizedString('tuilivekit.comment.emoji_input')));
    await tester.pump();
    expect(tester.getBottomLeft(inputBar).dy, 271);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(inputBar).dy, 271);
    bottomSafeArea = 42;
    keyboardInset = 0;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(inputBar).dy, 271);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Emoji mode ignores intermediate keyboard insets while closing',
      (tester) async {
    var keyboardInset = 300.0;
    Widget view() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: BarrageInputView(onDismiss: () {}),
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    final inputBar = find.byKey(const ValueKey('barrageInputBar'));
    expect(tester.getBottomLeft(inputBar).dy, 290);
    await tester.tap(find.bySemanticsLabel(
        LiveKitResources.localizedString('tuilivekit.comment.emoji_input')));
    await tester.pump();
    expect(tester.getBottomLeft(inputBar).dy, 290);
    keyboardInset = 150;
    await tester.pumpWidget(view());
    await tester.pump();
    expect(tester.getBottomLeft(inputBar).dy, 290);
    keyboardInset = 0;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(inputBar).dy, 290);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty send keeps visible keyboard ready for dismissal',
      (tester) async {
    var keyboardInset = 300.0;
    var dismissals = 0;
    Widget view() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: BarrageInputView(onDismiss: () => dismissals++),
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    tester.widget<TextField>(find.byType(TextField)).onSubmitted!('');
    keyboardInset = 0;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(dismissals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping the text field in emoji mode switches to keyboard mode',
      (tester) async {
    var keyboardInset = 0.0;
    Widget view() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: BarrageInputView(
                initialInputMode: BarrageInputMode.emoji, onDismiss: () {}),
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(
        find.bySemanticsLabel(
            LiveKitResources.localizedString('tuilivekit.comment.emoji_input')),
        findsOneWidget);
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue);
    keyboardInset = 300;
    await tester.pumpWidget(view());
    await tester.pump();
    expect(
        tester.getBottomLeft(find.byKey(const ValueKey('barrageInputBar'))).dy,
        290);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reopening emoji presentation resets the panel to the first page',
      (tester) async {
    var presented = true;
    Widget view() => MaterialApp(
          home: BarrageInputView(
            isPresented: presented,
            initialInputMode: BarrageInputMode.emoji,
            onDismiss: () {},
          ),
        );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(LiveKitResources.localizedString(
        'tuilivekit.comment.emoji_page_down')));
    await tester.pumpAndSettle();
    final grid = find.byKey(const ValueKey('barrageEmojiGrid'));
    expect(tester.widget<GridView>(grid).controller!.offset, greaterThan(0));
    presented = false;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    presented = true;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(tester.widget<GridView>(grid).controller!.offset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Emoji loading and error fallbacks use the configured size',
      (tester) async {
    final smile = BarrageEmoji.all.first;
    for (final size in <double>[32, 20]) {
      final image =
          BarrageEmojiConverter.buildImage(smile, size: size) as Image;
      expect(image.frameBuilder, isNotNull);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Column(
            children: <Widget>[
              image.frameBuilder!(
                  context, const SizedBox.shrink(), null, false),
              image.errorBuilder!(context, Object(), null),
            ],
          ),
        ),
      ));
      final fallbacks = find.descendant(
          of: find.byType(Column), matching: find.byType(SizedBox));
      expect(fallbacks, findsNWidgets(2));
      expect(tester.getSize(fallbacks.at(0)), Size(size, size));
      expect(tester.getSize(fallbacks.at(1)), Size(size, size));
      expect(find.text(smile.token), findsNWidgets(2));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Emoji action controls match Ardot dimensions and fills',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BarrageInputView(
          initialInputMode: BarrageInputMode.emoji, onDismiss: () {}),
    ));
    await tester.pumpAndSettle();
    final deleteContainer = find.descendant(
      of: find.bySemanticsLabel(
          LiveKitResources.localizedString('tuilivekit.comment.emoji_delete')),
      matching: find.byType(Container),
    );
    expect(deleteContainer, findsOneWidget);
    expect(tester.getSize(deleteContainer), const Size(44, 32));
    final deleteDecoration =
        tester.widget<Container>(deleteContainer).decoration as BoxDecoration;
    expect(deleteDecoration.color, const Color(0xFFE4E6EB));
    expect(deleteDecoration.borderRadius, BorderRadius.circular(8));

    final sendText =
        find.text(LiveKitResources.localizedString('tuilivekit.common.send'));
    final sendButton =
        tester.element(sendText).findAncestorWidgetOfExactType<Container>()!;
    final sendContainer = find.byWidget(sendButton);
    expect(sendContainer, findsOneWidget);
    expect(tester.getSize(sendContainer), const Size(64, 32));
    final sendDecoration = sendButton.decoration as BoxDecoration;
    expect(sendDecoration.borderRadius, BorderRadius.circular(8));
    expect(sendDecoration.color, LiveTheme.brandBlue);
    final background = sendDecoration.image!;
    expect(background.fit, BoxFit.fill);
    expect((background.image as AssetImage).assetName,
        'assets/livekit_comment_send_background.png');
    expect(
        tester
            .widget<Text>(find.text(
                LiveKitResources.localizedString('tuilivekit.common.send')))
            .style
            ?.fontWeight,
        FontWeight.w500);
    expect(tester.takeException(), isNull);
  });
}
