import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../l10n/language_store.dart';
import '../../../l10n/live_kit_localizations.dart';
import '../../pusher_style.dart';

class ReceivedGift {
  final LiveUserInfo sender;
  final Gift gift;
  final int count;

  const ReceivedGift({
    required this.sender,
    required this.gift,
    required this.count,
  });
}

class GiftListNotifier extends ValueNotifier<List<ReceivedGift>> {
  GiftListNotifier({this.maxCount = 50}) : super(const []);

  final int maxCount;

  void add(ReceivedGift gift) {
    final list = [...value];
    if (list.length >= maxCount) {
      list.removeAt(0);
    }
    list.add(gift);
    value = list;
  }

  void clear() {
    value = <ReceivedGift>[];
  }
}

class GiftWidget extends StatefulWidget {
  final String liveID;
  final ValueListenable<bool>? isLiveStarted;

  const GiftWidget({super.key, this.liveID = '', this.isLiveStarted});

  @override
  State<GiftWidget> createState() => _GiftWidgetState();
}

class _GiftWidgetState extends State<GiftWidget> {
  static const double _itemHeight = 38;

  GiftStore? _store;
  GiftListener? _listener;
  final GiftListNotifier _giftList = GiftListNotifier();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _attach();
    widget.isLiveStarted?.addListener(_onLiveStartedChanged);
    LanguageStore.locale.addListener(_applyGiftLanguage);
  }

  @override
  void dispose() {
    widget.isLiveStarted?.removeListener(_onLiveStartedChanged);
    LanguageStore.locale.removeListener(_applyGiftLanguage);
    _detach();
    _giftList.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _attach() {
    _store = GiftStore.create(widget.liveID);
    _applyGiftLanguage();
    _listener = GiftListener(onReceiveGiftWithReceiver: _onReceiveGift);
    _store!.addGiftListener(_listener!);
  }

  void _applyGiftLanguage() {
    final locale = LanguageStore.locale.value ??
        WidgetsBinding.instance.platformDispatcher.locale;
    _store?.setLanguage(locale.languageCode == 'zh' ? 'zh-Hans' : 'en');
  }

  void _detach() {
    if (_listener != null) {
      _store?.removeGiftListener(_listener!);
    }
    _listener = null;
    _store = null;
  }

  void _onLiveStartedChanged() {
    _giftList.clear();
    if (widget.isLiveStarted?.value == true) {
      _detach();
      _attach();
    }
  }

  void _onReceiveGift(
    String liveID,
    Gift gift,
    int count,
    LiveUserInfo sender,
    LiveUserInfo? receiver,
  ) {
    _giftList.add(ReceivedGift(sender: sender, gift: gift, count: count));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ReceivedGift>>(
      valueListenable: _giftList,
      builder: (context, gifts, _) {
        if (gifts.isEmpty) {
          return Center(
            child: Text(
              LiveKitLocalizations.of(context).giftEmpty,
              style: const TextStyle(
                color: PusherStyle.textHint,
                fontSize: 12,
              ),
            ),
          );
        }
        return RepaintBoundary(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            itemCount: gifts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (_, i) => _GiftItem(receivedGift: gifts[i]),
          ),
        );
      },
    );
  }
}

class _GiftItem extends StatelessWidget {
  final ReceivedGift receivedGift;

  const _GiftItem({required this.receivedGift});

  @override
  Widget build(BuildContext context) {
    final l10n = LiveKitLocalizations.of(context);
    final sender = receivedGift.sender;
    final gift = receivedGift.gift;
    final displayName =
        sender.userName.isNotEmpty ? sender.userName : sender.userID;
    return Container(
      height: _GiftWidgetState._itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _GiftIcon(url: gift.iconURL),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(
                  color: PusherStyle.textSecondary,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '$displayName ',
                    style: const TextStyle(
                      color: PusherStyle.brand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: '${l10n.giftSent} '),
                  TextSpan(
                    text: gift.name,
                    style: const TextStyle(color: PusherStyle.gold),
                  ),
                  TextSpan(
                    text: ' x${receivedGift.count}',
                    style: const TextStyle(
                      color: PusherStyle.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftIcon extends StatelessWidget {
  final String url;

  const _GiftIcon({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: 22,
        height: 22,
        fit: BoxFit.cover,
        cacheWidth: 64,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: PusherStyle.white8,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        RemixIcons.gift_2_line,
        size: 14,
        color: PusherStyle.textTertiary,
      ),
    );
  }
}
