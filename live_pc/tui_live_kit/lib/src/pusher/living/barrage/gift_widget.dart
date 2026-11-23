import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../audience/level_badge.dart';
import '../../../l10n/language_store.dart';
import '../../../l10n/live_kit_localizations.dart';
import '../../../common/style/live_kit_style.dart';
import 'new_items_button.dart';

class ReceivedGift {
  final LiveUserInfo sender;
  final Gift gift;
  final int count;
  final DateTime updatedAt;

  const ReceivedGift({
    required this.sender,
    required this.gift,
    required this.count,
    required this.updatedAt,
  });
}

class GiftListNotifier extends ValueNotifier<List<ReceivedGift>> {
  GiftListNotifier({this.maxCount = 50}) : super(const []);

  final int maxCount;

  static const Duration mergeWindow = Duration(seconds: 2);

  /// Returns false when merged into an existing row within [mergeWindow].
  bool add(ReceivedGift gift, {bool trim = true}) {
    final list = [...value];
    for (var i = list.length - 1; i >= 0; i--) {
      final row = list[i];
      if (row.sender.userID != gift.sender.userID ||
          row.gift.giftID != gift.gift.giftID) {
        continue;
      }
      if (gift.updatedAt.difference(row.updatedAt) > mergeWindow) {
        break;
      }
      list[i] = ReceivedGift(
        sender: gift.sender,
        gift: gift.gift,
        count: _saturatingAdd(row.count, gift.count),
        updatedAt: gift.updatedAt,
      );
      value = list;
      return false;
    }
    list.add(gift);
    value = _trimmed(list, trim ? maxCount : maxCount * 4);
    return true;
  }

  void trim() {
    final list = _trimmed(value, maxCount);
    if (list.length != value.length) {
      value = list;
    }
  }

  List<ReceivedGift> _trimmed(List<ReceivedGift> list, int limit) {
    if (list.length <= limit) return list;
    return list.sublist(list.length - limit);
  }

  static int _saturatingAdd(int lhs, int rhs) {
    const maxInt = 0x7FFFFFFFFFFFFFFF;
    if (rhs > 0 && lhs > maxInt - rhs) {
      return maxInt;
    }
    return lhs + rhs;
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
  GiftStore? _store;
  GiftListener? _listener;
  final GiftListNotifier _giftList = GiftListNotifier();
  final ScrollController _scrollController = ScrollController();
  bool _isFollowingLatest = true;
  int _unreadCount = 0;
  static const double _bottomThreshold = 24;

  @override
  void initState() {
    super.initState();
    _attach();
    _scrollController.addListener(_onScroll);
    widget.isLiveStarted?.addListener(_onLiveStartedChanged);
    LanguageStore.locale.addListener(_applyGiftLanguage);
  }

  @override
  void dispose() {
    widget.isLiveStarted?.removeListener(_onLiveStartedChanged);
    LanguageStore.locale.removeListener(_applyGiftLanguage);
    _detach();
    _giftList.dispose();
    _scrollController.removeListener(_onScroll);
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
    _isFollowingLatest = true;
    _unreadCount = 0;
    if (widget.isLiveStarted?.value == true) {
      _detach();
      _attach();
    }
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.extentAfter <= _bottomThreshold;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _isAtBottom();
    if (atBottom == _isFollowingLatest && !(atBottom && _unreadCount > 0)) {
      return;
    }
    setState(() {
      _isFollowingLatest = atBottom;
      if (atBottom) _unreadCount = 0;
    });
    if (atBottom) _giftList.trim();
  }

  void _onReceiveGift(
    String liveID,
    Gift gift,
    int count,
    LiveUserInfo sender,
    LiveUserInfo? receiver,
  ) {
    if (count <= 0) {
      return;
    }
    if (widget.liveID.isNotEmpty && liveID != widget.liveID) {
      return;
    }
    final received = ReceivedGift(
      sender: sender,
      gift: gift,
      count: count,
      updatedAt: DateTime.now(),
    );
    if (!_isFollowingLatest) {
      final addedNewRow = _giftList.add(received, trim: false);
      if (addedNewRow) {
        setState(() => _unreadCount += 1);
      }
      return;
    }
    _giftList.add(received);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isFollowingLatest) return;
      _scrollToBottom(animated: true);
    });
  }

  void _followLatest() {
    setState(() {
      _isFollowingLatest = true;
      _unreadCount = 0;
    });
    _giftList.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom(animated: true);
    });
  }

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final distance = position.maxScrollExtent - position.pixels;
    if (distance <= 0) return;
    if (!animated || distance > position.viewportDimension) {
      _scrollController.jumpTo(position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isFollowingLatest) return;
        if (!_scrollController.hasClients) return;
        final next = _scrollController.position;
        if (next.pixels < next.maxScrollExtent) {
          _scrollController.jumpTo(next.maxScrollExtent);
        }
      });
      return;
    }
    _scrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
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
                color: LiveKitStyle.textHint,
                fontSize: 12,
              ),
            ),
          );
        }
        return Stack(
          children: [
            RepaintBoundary(
              child: ListView.builder(
                controller: _scrollController,
                addAutomaticKeepAlives: false,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                itemCount: gifts.length,
                itemBuilder: (_, i) => _GiftItem(receivedGift: gifts[i]),
              ),
            ),
            if (_unreadCount > 0)
              NewItemsButton(
                label:
                    LiveKitLocalizations.of(context).giftNewItems(_unreadCount),
                onTap: _followLatest,
              ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          _GiftIcon(url: gift.iconURL),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: LiveKitStyle.textSecondary,
                  fontSize: 12,
                ),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: LevelBadge(level: sender.level),
                    ),
                  ),
                  TextSpan(
                    text: '$displayName ',
                    style: TextStyle(
                      color: LiveKitStyle.barrageSenderColors(sender.userID),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: '${l10n.giftSent} '),
                  TextSpan(
                    text: gift.name,
                    style: const TextStyle(color: LiveKitStyle.gold),
                  ),
                  TextSpan(
                    text: ' x${receivedGift.count}',
                    style: const TextStyle(
                      color: LiveKitStyle.gold,
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
        color: LiveKitStyle.white8,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        RemixIcons.gift_2_line,
        size: 14,
        color: LiveKitStyle.textTertiary,
      ),
    );
  }
}
