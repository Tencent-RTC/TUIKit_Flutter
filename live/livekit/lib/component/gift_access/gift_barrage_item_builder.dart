import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/widget/display/custom_barrage_builder.dart';
import 'package:tencent_live_uikit/common/screen/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import '../../common/constants/constants.dart';
import '../../common/language/index.dart';
import '../../common/resources/colors.dart';

class GiftBarrageItemBuilder extends CustomBarrageBuilder {
  final String selfUserId;

  List<Color> giftMessageColor = [
    LiveColors.barrageColorMsg1,
    LiveColors.barrageColorMsg2,
    LiveColors.barrageColorMsg3,
    LiveColors.barrageColorMsg4,
    LiveColors.barrageColorMsg5,
    LiveColors.barrageColorMsg6,
    LiveColors.barrageColorMsg7
  ];

  GiftBarrageItemBuilder({required this.selfUserId});

  @override
  Widget buildWidget(BuildContext context, Barrage barrage) {
    String receiverUserId = barrage.extensionInfo[Constants.keyGiftReceiverUserId] ?? '';
    String receiverUserName =
        barrage.extensionInfo[Constants.keyGiftReceiverUsername] ?? '';
    String giftUrl = barrage.extensionInfo[Constants.keyGiftImage] ?? '';
    String giftName = barrage.extensionInfo[Constants.keyGiftName] ?? '';
    int giftCount = int.tryParse(barrage.extensionInfo[Constants.keyGiftCount] ?? '0') ?? 0;
    String senderUserId = barrage.sender.userID;
    String senderUserName = barrage.sender.userName;
    if (senderUserId == selfUserId) {
      senderUserName = LiveKitLocalizations.of(context)!.common_gift_me;
    }
    if (receiverUserId == selfUserId) {
      receiverUserName = LiveKitLocalizations.of(context)!.common_gift_me;
    }
    return Wrap(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3, bottom: 3),
          padding: const EdgeInsets.only(left: 6, top: 4, right: 6, bottom: 4),
          decoration: BoxDecoration(
            color: LiveColors.notStandard40G1,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 4.width),
              Text(
                senderUserName,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LiveColors.barrageUserNameColor),
              ),
              SizedBox(width: 4.width),
              Text(
                LiveKitLocalizations.of(context)!.common_sent,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              SizedBox(width: 4.width),
              Text(
                receiverUserName,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LiveColors.barrageUserNameColor),
              ),
              SizedBox(width: 4.width),
              Text(
                giftName,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: giftMessageColor[Random().nextInt(7)]),
              ),
              SizedBox(width: 4.width),
              Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: CachedNetworkImage(
                  width: 13,
                  height: 13,
                  imageUrl: giftUrl,
                  fit: BoxFit.fitWidth,
                  placeholder: (context, url) => _buildDefaultGift(),
                  errorWidget: (context, url, error) => _buildDefaultGift(),
                ),
              ),
              SizedBox(width: 4.width),
              Text(
                "x$giftCount",
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool shouldCustomizeBarrageItem(Barrage barrage) {
    if (barrage.extensionInfo.containsKey(Constants.keyGiftViewType)) {
      return true;
    }
    return false;
  }

  _buildDefaultGift() {
    return Container(color: LiveColors.designStandardTransparent);
  }
}
