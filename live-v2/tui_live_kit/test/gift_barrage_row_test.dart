import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_stream_view.dart';
import 'package:tencent_live_uikit/src/common/gift/gift_barrage_store.dart';

void main() {
  testWidgets('Failed gift image collapses both image and spacing',
      (tester) async {
    Widget view(String url) => MaterialApp(
        home: Center(
            child: GiftCommentRow(
                comment: LiveGiftBarrage(
                    giftID: 'g',
                    giftName: 'Rose',
                    giftIconURL: url,
                    count: 2,
                    senderID: 'u',
                    senderName: 'U',
                    senderLevel: 2))));
    await tester.pumpWidget(view(''));
    await tester.pumpAndSettle();
    final noImageSize = tester.getSize(find.byType(GiftCommentRow));
    await tester.pumpWidget(view('https://example.invalid/gift.png'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(GiftCommentRow)), noImageSize);
    expect(noImageSize.height, 28);
    expect(noImageSize.width, lessThanOrEqualTo(300));
    expect(tester.takeException(), isNull);
  });
}
