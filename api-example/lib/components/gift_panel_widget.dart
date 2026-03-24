import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_example/components/localized_manager.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';

/// Gift panel widget (paginated swipe)
///
/// Related APIs:
/// - `GiftStore.create(liveID)` - Create the gift management instance (positional parameter)
/// - `GiftStore.setLanguage(language)` - Set the gift display language (positional parameter)
/// - `GiftStore.refreshUsableGifts()` - Refresh the available gift list (no parameters, returns `Future`)
/// - `GiftStore.sendGift(giftID:, count:)` - Send a gift (named parameters, returns `Future`)
/// - `GiftStore.giftState` - Gift state (`GiftState`)
/// - `GiftStore.addGiftListener / removeGiftListener` - Gift event listeners (`Listener` pattern)
///
/// Fields in `GiftState` (`ValueListenable`):
/// - `usableGifts`: `ValueListenable` of `List<GiftCategory>`
///
/// Features:
/// - Display available gifts in pages (2 rows x 4 columns = 8 items per page)
/// - Swipe left and right to switch pages, with a page indicator at the bottom
/// - Select and send gifts
/// - Listen for received gift events
class GiftPanelWidget extends StatefulWidget {
  final String liveID;

  /// Callback when a gift is received (for external toast display and similar uses)
  final void Function(Gift gift, int count, LiveUserInfo sender)? onReceiveGift;

  /// Callback for the gift sending result
  final void Function(dynamic result)? onSendGiftResult;

  const GiftPanelWidget({super.key, required this.liveID, this.onReceiveGift, this.onSendGiftResult});

  @override
  State<GiftPanelWidget> createState() => _GiftPanelWidgetState();
}

class _GiftPanelWidgetState extends State<GiftPanelWidget> {
  // MARK: - Properties

  late final GiftStore _giftStore;
  late final GiftListener _giftListener;
  int? _selectedGiftIndex;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  /// Rows per page
  static const int _rowsPerPage = 2;

  /// Columns per page
  static const int _columnsPerPage = 4;

  /// Number of gifts per page
  static const int _itemsPerPage = _rowsPerPage * _columnsPerPage;

  @override
  void initState() {
    super.initState();
    _giftStore = GiftStore.create(widget.liveID);
    _setupBindings();
    _loadGifts();
  }

  @override
  void dispose() {
    _giftStore.removeGiftListener(_giftListener);
    _pageController.dispose();
    super.dispose();
  }

  // MARK: - Setup

  void _setupBindings() {
    // Use `GiftListener` to listen for received gift events
    _giftListener = GiftListener(
      onReceiveGift: (liveID, gift, count, sender) {
        if (!mounted) return;
        widget.onReceiveGift?.call(gift, count, sender);
      },
    );
    _giftStore.addGiftListener(_giftListener);
  }

  // MARK: - Data Loading

  /// Load the available gift list
  void _loadGifts() {
    // Set the display language
    final language = LocalizedManager.shared.isChinese ? "zh-Hans" : "en";
    _giftStore.setLanguage(language);

    // Refresh the gift list (no parameters, returns `Future`)
    _giftStore.refreshUsableGifts().then((result) {
      // Notify the external callback on failure
      if (!result.isSuccess) {
        widget.onSendGiftResult?.call(result);
      }
    });
  }

  // MARK: - Actions

  /// Send the selected gift
  void _sendGiftTapped() {
    final gifts = _giftStore.giftState.usableGifts.value.expand((group) => group.giftList).toList();
    if (_selectedGiftIndex == null || _selectedGiftIndex! >= gifts.length) return;
    final gift = gifts[_selectedGiftIndex!];

    _giftStore.sendGift(giftID: gift.giftID, count: 1).then((result) {
      widget.onSendGiftResult?.call(result);
    });
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<List<GiftCategory>>(
      valueListenable: _giftStore.giftState.usableGifts,
      builder: (context, giftCategories, _) {
        final gifts = giftCategories.expand((group) => group.giftList).toList();
        final totalPages = (gifts.length / _itemsPerPage).ceil().clamp(1, 999);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Gift grid list (paginated swipe)
            SizedBox(
              height: 270,
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, pageIndex) {
                  return _buildGiftPage(pageIndex, gifts);
                },
              ),
            ),
            // Page indicator
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage ? Colors.pink : Colors.white.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            // Send button
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 80,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _sendGiftTapped,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    child: Text(l10n.interactiveGiftSend),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build a single gift grid page (2 rows x 4 columns)
  Widget _buildGiftPage(int pageIndex, List<Gift> gifts) {
    final startIndex = pageIndex * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, gifts.length);
    final pageGifts = gifts.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: _columnsPerPage,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        childAspectRatio: 0.8,
        children: List.generate(pageGifts.length, (index) {
          final actualIndex = startIndex + index;
          final gift = pageGifts[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedGiftIndex = actualIndex;
              });
            },
            child: _GiftCell(gift: gift, isSelected: actualIndex == _selectedGiftIndex),
          );
        }),
      ),
    );
  }
}

// MARK: - GiftCell

/// Gift cell - displays the gift icon, name, and price
class _GiftCell extends StatelessWidget {
  final Gift gift;
  final bool isSelected;

  const _GiftCell({required this.gift, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.pink.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: Colors.pink, width: 1.5) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gift icon
          SizedBox(
            width: 40,
            height: 40,
            child:
                gift.iconURL.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: gift.iconURL,
                      placeholder: (context, url) => const Icon(Icons.card_giftcard, color: Colors.white54, size: 24),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.card_giftcard, color: Colors.white54, size: 24),
                      fit: BoxFit.contain,
                    )
                    : const Icon(Icons.card_giftcard, color: Colors.white54, size: 24),
          ),
          const SizedBox(height: 4),
          // Gift name
          Text(
            gift.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Price (coin icon + price text)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, size: 12, color: Color.fromRGBO(255, 214, 0, 1.0)),
              const SizedBox(width: 2),
              Text(
                '${gift.coins}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(255, 214, 0, 1.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
