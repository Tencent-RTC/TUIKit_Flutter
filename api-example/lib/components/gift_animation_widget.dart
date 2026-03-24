import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';

/// Gift animation display widget
///
/// Supports two gift animation effects:
/// 1. Full-screen SVGA animation — when `Gift.resourceURL` has a value, use `SVGAPlayer` to play a full-screen animation
/// 2. Barrage slide animation — when `Gift.resourceURL` is empty, slide in from the left side of the screen, stay for a while, and then disappear (similar to gift barrages in Douyin/TikTok live streams)
///
/// Usage:
/// Overlay `GiftAnimationWidget` on top of the live video view in full-screen mode, then call `playGiftAnimation`.
class GiftAnimationWidget extends StatefulWidget {
  const GiftAnimationWidget({super.key});

  @override
  State<GiftAnimationWidget> createState() => GiftAnimationWidgetState();
}

class GiftAnimationWidgetState extends State<GiftAnimationWidget> with TickerProviderStateMixin {
  // MARK: - Properties

  /// SVGA animation controller
  SVGAAnimationController? _svgaController;
  bool _svgaVisible = false;

  /// Barrage animation queue (prevents multiple barrages from overlapping)
  final List<_GiftBarrageItem> _barrageAnimationQueue = [];

  /// Active Y-axis slots for barrage display (up to 3 shown at the same time)
  final Map<int, _GiftBarrageItemData> _activeSlots = {};
  static const int _maxSlots = 3;

  @override
  void initState() {
    super.initState();
    _svgaController = SVGAAnimationController(vsync: this);
    _svgaController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _svgaVisible = false;
        });
        _svgaController?.reset();
      }
    });
  }

  @override
  void dispose() {
    _svgaController?.dispose();
    // Dispose animation controllers for all active slots
    for (final slotData in _activeSlots.values) {
      slotData.slideController.dispose();
      slotData.fadeController.dispose();
      slotData.countBounceController.dispose();
    }
    _activeSlots.clear();
    super.dispose();
  }

  // MARK: - Public API

  /// Play a gift animation
  void playGiftAnimation({required Gift gift, required int count, required LiveUserInfo sender}) {
    if (gift.resourceURL.isNotEmpty) {
      // `resourceURL` is available -> play the full-screen SVGA animation
      _playSVGAAnimation(gift.resourceURL);
    }

    // Show the barrage slide animation whether or not an SVGA animation exists
    final item = _GiftBarrageItem(gift: gift, count: count, sender: sender);
    _enqueueBarrageAnimation(item);
  }

  // MARK: - Full-screen SVGA animation

  void _playSVGAAnimation(String resourceURL) {
    if (resourceURL.isEmpty) return;

    setState(() {
      _svgaVisible = true;
    });

    SVGAParser.shared
        .decodeFromURL(resourceURL)
        .then((videoItem) {
          if (!mounted) return;
          _svgaController?.videoItem = videoItem;
          _svgaController?.forward();
        })
        .catchError((error) {
          if (!mounted) return;
          setState(() {
            _svgaVisible = false;
          });
        });
  }

  // MARK: - Barrage slide animation (similar to Douyin/TikTok live streams)

  /// Enqueue a barrage animation
  void _enqueueBarrageAnimation(_GiftBarrageItem item) {
    _barrageAnimationQueue.add(item);
    _processBarrageQueue();
  }

  /// Process the barrage queue and find an idle slot to display it
  void _processBarrageQueue() {
    if (_barrageAnimationQueue.isEmpty) return;

    // Find an idle slot
    for (int slot = 0; slot < _maxSlots; slot++) {
      if (_barrageAnimationQueue.isEmpty) break;
      if (!_activeSlots.containsKey(slot)) {
        final item = _barrageAnimationQueue.removeAt(0);
        _showBarrageItem(item, slot);
      }
    }
  }

  /// Display the barrage animation in the specified slot
  void _showBarrageItem(_GiftBarrageItem item, int slot) {
    // Create animation controllers
    final slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    final fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), value: 1.0);
    final countBounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    final slotData = _GiftBarrageItemData(
      item: item,
      slot: slot,
      slideController: slideController,
      fadeController: fadeController,
      countBounceController: countBounceController,
    );

    setState(() {
      _activeSlots[slot] = slotData;
    });

    // Phase 1: slide in from the left
    slideController.forward().then((_) {
      // Count bounce animation (delay 0.3s)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        countBounceController.forward();
      });

      // Phase 2: stay for 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        // Phase 3: fade upward and disappear
        fadeController.reverse().then((_) {
          if (!mounted) return;
          slideController.dispose();
          fadeController.dispose();
          countBounceController.dispose();
          setState(() {
            _activeSlots.remove(slot);
          });
          // Process the next item in the queue
          _processBarrageQueue();
        });
      });
    });
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Full-screen SVGA player
          if (_svgaVisible && _svgaController != null)
            Positioned.fill(child: SVGAImage(_svgaController!, fit: BoxFit.contain)),
          // Barrage slide animations
          ..._activeSlots.entries.map((entry) {
            final slotData = entry.value;
            final slotY = MediaQuery.of(context).size.height * 0.35 + entry.key * 56.0;

            return Positioned(
              left: 0,
              top: slotY,
              child: AnimatedBuilder(
                animation: Listenable.merge([slotData.slideController, slotData.fadeController]),
                builder: (context, child) {
                  // Slide-in animation: from -300 to 12
                  final slideValue = CurvedAnimation(parent: slotData.slideController, curve: Curves.easeOutBack).value;
                  final xOffset = -300.0 + (300.0 + 12.0) * slideValue;

                  // Fade-out phase: move up by 20
                  final fadeValue = slotData.fadeController.value;
                  final yOffset = fadeValue < 1.0 ? (1.0 - fadeValue) * -20.0 : 0.0;

                  return Transform.translate(
                    offset: Offset(xOffset, yOffset),
                    child: Opacity(
                      opacity: fadeValue,
                      child: _GiftBarrageItemView(
                        item: slotData.item,
                        countBounceController: slotData.countBounceController,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

// MARK: - GiftBarrageItem

/// Barrage animation data model
class _GiftBarrageItem {
  final Gift gift;
  final int count;
  final LiveUserInfo sender;

  _GiftBarrageItem({required this.gift, required this.count, required this.sender});
}

/// Barrage animation slot data
class _GiftBarrageItemData {
  final _GiftBarrageItem item;
  final int slot;
  final AnimationController slideController;
  final AnimationController fadeController;
  final AnimationController countBounceController;

  _GiftBarrageItemData({
    required this.item,
    required this.slot,
    required this.slideController,
    required this.fadeController,
    required this.countBounceController,
  });
}

// MARK: - GiftBarrageItemView

/// Barrage animation view — simulates the gift barrage style used in Douyin/TikTok live streams
/// Layout: [Avatar] [Sender name / sent gift name] [Gift icon] [xCount]
class _GiftBarrageItemView extends StatelessWidget {
  final _GiftBarrageItem item;
  final AnimationController countBounceController;

  const _GiftBarrageItemView({required this.item, required this.countBounceController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final senderName = item.sender.userName.isEmpty ? item.sender.userID : item.sender.userName;
    final sentText = l10n?.interactiveGiftSent ?? 'sent';

    return Container(
      width: 280,
      height: 48,
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          const SizedBox(width: 4),
          // Avatar
          ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child:
                  item.sender.avatarURL.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: item.sender.avatarURL,
                        placeholder: (context, url) => const Icon(Icons.account_circle, color: Colors.white, size: 32),
                        errorWidget:
                            (context, url, error) => const Icon(Icons.account_circle, color: Colors.white, size: 32),
                        fit: BoxFit.cover,
                      )
                      : const Icon(Icons.account_circle, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 6),
          // Text: sender name + "sent" + gift name
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$senderName\n',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  TextSpan(
                    text: '$sentText ${item.gift.name}',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ),
          // Gift icon
          SizedBox(
            width: 32,
            height: 32,
            child:
                item.gift.iconURL.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: item.gift.iconURL,
                      placeholder: (context, url) => const Icon(Icons.card_giftcard, color: Colors.pink, size: 24),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.card_giftcard, color: Colors.pink, size: 24),
                      fit: BoxFit.contain,
                    )
                    : const Icon(Icons.card_giftcard, color: Colors.pink, size: 24),
          ),
          const SizedBox(width: 2),
          // Count (bounce animation)
          ScaleTransition(
            scale: Tween<double>(
              begin: 0.1,
              end: 1.0,
            ).animate(CurvedAnimation(parent: countBounceController, curve: Curves.elasticOut)),
            child: Text(
              'x${item.count}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.yellow),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
