library;

import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../live_kit_resources.dart';
import '../../theme/bottom_sheet_background_view.dart';
import '../../theme/bottom_sheet_view.dart';
import 'gift_grid_page_view.dart';
import 'gift_send_combo_button.dart';

typedef GiftPresentationChanged = void Function(
  bool isPresented,
  double heightAboveSafeArea,
);

class GiftSendPanelView extends StatefulWidget {
  const GiftSendPanelView({
    super.key,
    this.onPresentationChanged,
  });

  /// Geometry contract for host layout avoidance. All gift business logic is
  /// owned by this widget; hosts only call present / dismiss.
  final GiftPresentationChanged? onPresentationChanged;

  @override
  State<GiftSendPanelView> createState() => GiftSendPanelViewState();
}

class GiftSendPanelViewState extends State<GiftSendPanelView> {
  static const double _contentHeightAboveSafeArea = 348;
  static const double _floatingComboBottomInset = 72;

  final BottomSheetController _sheetController = BottomSheetController();
  final PageController _pageController = PageController();
  final GiftSendComboButtonController _comboController = GiftSendComboButtonController();

  bool _visible = false;
  bool _presentationReported = false;
  bool _presentationNotificationPending = false;
  double _heightAboveSafeArea = _contentHeightAboveSafeArea;
  double? _reportedHeightAboveSafeArea;
  int _selectedCategoryIndex = 0;
  Object? _pageAnimation;
  String? _selectedGiftID;
  String? _comboGiftID;

  List<GiftCategory> _categories = <GiftCategory>[];
  bool _isLoading = false;
  String _liveID = '';
  GiftStore? _giftStore;
  VoidCallback? _usableGiftsListener;
  int _activationID = 0;
  Gift? _floatingComboGift;

  bool get isPresented => _visible;

  void present(String liveID) {
    _activate(liveID);
    if (_visible) return;
    setState(() {
      _visible = true;
      _presentationReported = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPageOffset(animated: false);
    });
  }

  Future<void> dismiss() async {
    _endFloatingCombo();
    _deactivate();
    await _dismissSheet();
  }

  Future<void> _dismissSheet() async {
    if (!_visible) return;
    await _sheetController.dismiss();
  }

  void _activate(String liveID) {
    if (_liveID == liveID && _giftStore != null) return;
    _deactivate();
    if (liveID.isEmpty) return;
    _liveID = liveID;
    final int activationID = _activationID;
    _updateCatalog(<GiftCategory>[], isLoading: true);
    final GiftStore store = GiftStore.create(liveID);
    _giftStore = store;
    store.setLanguage(LiveKitResources.giftLanguageCode);
    void sync() {
      if (activationID != _activationID) return;
      final List<GiftCategory> current = store.giftState.usableGifts.value;
      _updateCatalog(_snapshotCategories(current), isLoading: current.isEmpty && _isLoading);
    }

    _usableGiftsListener = sync;
    store.giftState.usableGifts.addListener(sync);
    sync();
    unawaited(_refresh(store, activationID));
  }

  Future<void> _refresh(GiftStore store, int activationID) async {
    try {
      await store.refreshUsableGifts();
    } on Object {
      // A failed refresh keeps any previously received catalog.
    } finally {
      if (activationID == _activationID) {
        _updateCatalog(_categories, isLoading: false);
      }
    }
  }

  void _deactivate() {
    _activationID++;
    final VoidCallback? listener = _usableGiftsListener;
    if (listener != null) {
      _giftStore?.giftState.usableGifts.removeListener(listener);
    }
    _giftStore = null;
    _usableGiftsListener = null;
    _liveID = '';
  }

  void _updateCatalog(List<GiftCategory> categories, {required bool isLoading}) {
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _isLoading = isLoading;
      if (_selectedCategoryIndex >= categories.length) {
        _selectedCategoryIndex = 0;
      }
      if (_selectedGiftID != null && !_containsGift(_selectedGiftID!)) {
        _selectedGiftID = null;
      }
      if (_comboGiftID != null && !_containsGift(_comboGiftID!)) {
        _comboGiftID = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPageOffset(animated: false);
    });
  }

  static List<GiftCategory> _snapshotCategories(List<GiftCategory> categories) {
    return List<GiftCategory>.unmodifiable(categories.map((GiftCategory category) {
      return GiftCategory(
        categoryID: category.categoryID,
        name: category.name,
        desc: category.desc,
        extensionInfo: Map<String, String>.unmodifiable(category.extensionInfo),
        giftList: List<Gift>.unmodifiable(category.giftList.map((Gift gift) => Gift(
              giftID: gift.giftID,
              name: gift.name,
              desc: gift.desc,
              iconURL: gift.iconURL,
              resourceURL: gift.resourceURL,
              level: gift.level,
              coins: gift.coins,
              extensionInfo: Map<String, String>.unmodifiable(gift.extensionInfo),
            ))),
      );
    }));
  }

  void _sendGift(Gift gift, int count) {
    final GiftStore? store = _giftStore;
    if (store == null) return;
    unawaited(store.sendGift(giftID: gift.giftID, count: count < 1 ? 1 : count).then((_) {}).catchError((Object _) {}));
  }

  void _startFloatingCombo(Gift gift) {
    setState(() {
      _floatingComboGift = gift;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _comboController.onSendOnce = () {
        final Gift? current = _floatingComboGift;
        if (current != null) _sendGift(current, 1);
      };
      _comboController.onExpired = _endFloatingCombo;
      _comboController.begin(gift);
    });
  }

  void _endFloatingCombo() {
    _comboController.end();
    _comboController.onSendOnce = null;
    _comboController.onExpired = null;
    if (_floatingComboGift != null) {
      setState(() {
        _floatingComboGift = null;
      });
    }
  }

  @override
  void dispose() {
    _deactivate();
    _endFloatingCombo();
    _comboController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _containsGift(String id) {
    for (final GiftCategory group in _categories) {
      for (final Gift gift in group.giftList) {
        if (gift.giftID == id) return true;
      }
    }
    return false;
  }

  Future<void> _syncPageOffset({required bool animated}) async {
    if (!mounted || !_pageController.hasClients) return;
    if (_categories.isEmpty) return;
    if (animated) {
      // Intermediate pages must not replace the category the user tapped.
      final animation = Object();
      _pageAnimation = animation;
      await _pageController.animateToPage(
        _selectedCategoryIndex,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
      if (!mounted || _pageAnimation != animation) return;
      _pageAnimation = null;
      if (_pageController.hasClients) {
        _handlePageChanged(_pageController.page!.round());
      }
    } else {
      _pageAnimation = null;
      _pageController.jumpToPage(_selectedCategoryIndex);
    }
  }

  void _handleCategoryTap(int index) {
    if (index < 0 || index >= _categories.length) return;
    if (index == _selectedCategoryIndex) {
      _syncPageOffset(animated: true);
      return;
    }
    setState(() {
      _selectedCategoryIndex = index;
      _comboGiftID = null;
      _selectedGiftID = null;
    });
    _syncPageOffset(animated: true);
  }

  void _handlePageChanged(int index) {
    if (_pageAnimation != null) return;
    if (index == _selectedCategoryIndex) return;
    if (index < 0 || index >= _categories.length) return;
    setState(() {
      _selectedCategoryIndex = index;
      _comboGiftID = null;
      _selectedGiftID = null;
    });
  }

  void _handleCellTapped(Gift gift) {
    if (_comboGiftID != null) {
      setState(() {
        _comboGiftID = null;
      });
    }
    if (_selectedGiftID == gift.giftID) {
      if (gift.resourceURL.isNotEmpty) {
        setState(() {
          _selectedGiftID = null;
        });
        _startFloatingCombo(gift);
        unawaited(_dismissSheet());
      } else {
        setState(() {
          _selectedGiftID = null;
          _comboGiftID = gift.giftID;
        });
      }
    } else {
      setState(() {
        _selectedGiftID = gift.giftID;
      });
    }
  }

  void _handleComboSend(Gift gift) {
    _sendGift(gift, 1);
  }

  void _handleComboExpired() {
    final String? current = _comboGiftID;
    if (current == null) return;
    setState(() {
      _comboGiftID = null;
      _selectedGiftID = current;
    });
  }

  void _handleDismissed() {
    if (!_visible) return;
    setState(() {
      _visible = false;
      _selectedGiftID = null;
      _comboGiftID = null;
    });
    _presentationReported = false;
    widget.onPresentationChanged?.call(false, _heightAboveSafeArea);
  }

  void _reportPanelHeightAfterLayout(double height) {
    _heightAboveSafeArea = height;
    if (_presentationReported && _reportedHeightAboveSafeArea == height) return;
    if (_presentationNotificationPending) return;
    _presentationNotificationPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _presentationNotificationPending = false;
      if (!mounted || !_visible) return;
      _presentationReported = true;
      _reportedHeightAboveSafeArea = _heightAboveSafeArea;
      widget.onPresentationChanged?.call(true, _heightAboveSafeArea);
    });
  }

  GiftGridSelectionState _resolveSelection() {
    if (_comboGiftID != null) {
      return GiftGridSelectionState.combo(_comboGiftID!);
    }
    if (_selectedGiftID != null) {
      return GiftGridSelectionState.selected(_selectedGiftID!);
    }
    return const GiftGridSelectionState.none();
  }

  @override
  Widget build(BuildContext context) {
    final Gift? comboGift = _floatingComboGift;
    if (!_visible && comboGift == null) {
      return const SizedBox.shrink();
    }
    final media = MediaQuery.of(context);
    final double bottomSafe = media.padding.bottom;
    final double preferredHeight = _contentHeightAboveSafeArea + bottomSafe;
    return LayoutBuilder(builder: (context, constraints) {
      final double keyboardInset = BottomSheetTheme.isEnabled(context) ? media.viewInsets.bottom : 0;
      final double sheetHeight = preferredHeight
          .clamp(0.0, (constraints.maxHeight - media.padding.top - keyboardInset).clamp(0.0, double.infinity))
          .toDouble();
      _reportPanelHeightAfterLayout((sheetHeight - bottomSafe).clamp(0.0, double.infinity).toDouble());
      final double titleHeight = (media.textScaler.scale(16) * 1.2).clamp(32.0, double.infinity).toDouble();
      final double chromeHeight = 14 + titleHeight + 10 + GiftPanelStyle.categoryHeight(context) + 10 + 20;
      // Normal screens keep the template's 348 pt panel. Short containers
      // shrink the scrollable grid; an exceptionally short viewport can scroll
      // the whole panel while retaining reachable header and category tabs.
      final double minimumHeight = chromeHeight + bottomSafe + GiftPanelStyle.rowHeight(context) + 20;
      final double contentHeight =
          sheetHeight < minimumHeight ? preferredHeight.clamp(minimumHeight, double.infinity).toDouble() : sheetHeight;
      final content = SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 14),
            SizedBox(
              height: titleHeight,
              child: Center(
                child: Text(
                  LiveKitResources.localizedString('tuilivekit.player.gift.title'),
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.94),
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildCategoryTabs(),
            const SizedBox(height: 10),
            Expanded(child: _buildContent()),
            const SizedBox(height: 20),
          ],
        ),
      );
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_visible)
            BottomSheetView(
              controller: _sheetController,
              sheetHeight: sheetHeight,
              onDismiss: _handleDismissed,
              child: contentHeight > sheetHeight
                  ? SingleChildScrollView(child: SizedBox(height: contentHeight, child: content))
                  : content,
            ),
          if (comboGift != null)
            Positioned(
              key: const ValueKey('floatingGiftCombo'),
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + _floatingComboBottomInset,
              width: 72,
              child: GiftSendComboButton(controller: _comboController),
            ),
        ],
      );
    });
  }

  Widget _buildCategoryTabs() {
    final List<String> names = _categories.map((GiftCategory group) => group.name).toList(growable: false);
    if (names.isEmpty) {
      return SizedBox(height: GiftPanelStyle.categoryHeight(context));
    }
    return _GiftCategoryTabsView(
      categories: names,
      selectedIndex: _selectedCategoryIndex,
      onSelect: _handleCategoryTap,
    );
  }

  Widget _buildContent() {
    if (_isLoading && _categories.isEmpty) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      );
    }
    if (_categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            LiveKitResources.localizedString(
              'tuilivekit.player.gift.empty',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    final GiftGridSelectionState selection = _resolveSelection();
    return NotificationListener<ScrollStartNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 && notification.dragDetails != null) {
          _pageAnimation = null;
          _handlePageChanged(_pageController.page!.round());
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        onPageChanged: _handlePageChanged,
        itemBuilder: (BuildContext context, int index) {
          final GiftCategory group = _categories[index];
          return GiftGridPageView(
            key: ValueKey(group.categoryID),
            gifts: group.giftList,
            selection: selection,
            onCellTapped: _handleCellTapped,
            onComboSend: _handleComboSend,
            onComboExpired: _handleComboExpired,
          );
        },
      ),
    );
  }
}

class _GiftCategoryTabsView extends StatefulWidget {
  const _GiftCategoryTabsView({
    required this.categories,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  State<_GiftCategoryTabsView> createState() => _GiftCategoryTabsViewState();
}

class _GiftCategoryTabsViewState extends State<_GiftCategoryTabsView> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _keys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedIntoView(animated: false);
    });
  }

  @override
  void didUpdateWidget(covariant _GiftCategoryTabsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories.length != widget.categories.length) {
      _syncKeys();
    }
    if (oldWidget.selectedIndex != widget.selectedIndex || oldWidget.categories.length != widget.categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollSelectedIntoView(animated: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncKeys() {
    if (_keys.length == widget.categories.length) return;
    _keys
      ..clear()
      ..addAll(List<GlobalKey>.generate(
        widget.categories.length,
        (_) => GlobalKey(),
      ));
  }

  void _scrollSelectedIntoView({required bool animated}) {
    if (!mounted || !_scrollController.hasClients) return;
    final int index = widget.selectedIndex;
    if (index < 0 || index >= _keys.length) return;
    final BuildContext? tabContext = _keys[index].currentContext;
    if (tabContext == null) return;
    final RenderBox? tabBox = tabContext.findRenderObject() as RenderBox?;
    final RenderBox? viewportBox = context.findRenderObject() as RenderBox?;
    if (tabBox == null || viewportBox == null) return;
    final double tabLeft = tabBox.localToGlobal(Offset.zero, ancestor: viewportBox).dx;
    final double tabWidth = tabBox.size.width;
    final double viewportWidth = viewportBox.size.width;
    final double currentOffset = _scrollController.offset;
    final double target;
    if (tabLeft < 16) {
      target = currentOffset + tabLeft - 16;
    } else if (tabLeft + tabWidth > viewportWidth - 16) {
      target = currentOffset + (tabLeft + tabWidth) - (viewportWidth - 16);
    } else {
      return;
    }
    final double clamped = target.clamp(0, _scrollController.position.maxScrollExtent).toDouble();
    if ((clamped - currentOffset).abs() < 0.5) return;
    if (animated) {
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = GiftPanelStyle.categoryHeight(context);
    return SizedBox(
      height: height,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 17),
        itemCount: widget.categories.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 24),
        itemBuilder: (BuildContext context, int index) {
          final bool selected = index == widget.selectedIndex;
          return _CategoryTab(
            key: _keys[index],
            name: widget.categories[index],
            selected: selected,
            onTap: () => widget.onSelect(index),
          );
        },
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(
          const TextStyle(fontSize: 14, height: 1.2),
        );
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    );
    double labelWidth = 0;
    for (final weight in [FontWeight.w400, FontWeight.w700]) {
      painter.text = TextSpan(text: name, style: style.copyWith(fontWeight: weight));
      painter.layout();
      if (painter.width > labelWidth) labelWidth = painter.width;
    }
    painter.dispose();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        // Switching the selected font must not move neighboring tabs.
        width: labelWidth + 2,
        height: GiftPanelStyle.categoryHeight(context),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Text(
                name,
                maxLines: 1,
                softWrap: false,
                style: style.copyWith(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.5),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 0,
              height: 2,
              child: Visibility(
                visible: selected,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        GiftPanelStyle.blue,
                        GiftPanelStyle.deepBlue,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class GiftPanelStyle {
  static const blue = Color(0xFF4A9EFF);
  static const deepBlue = Color(0xFF0052D9);
  static const coin = Color(0xFFFFCA4C);

  // UIKit uses fixed system fonts here. Keep its base measurements while
  // letting larger Flutter accessibility text enlarge rows, not overflow them.
  static double categoryHeight(BuildContext context) =>
      (_lineHeight(context, 14, FontWeight.w700) + 8).clamp(32.0, double.infinity).toDouble();

  static double sendButtonHeight(BuildContext context) =>
      (_lineHeight(context, 12, FontWeight.w600) + 4).clamp(22.0, double.infinity).toDouble();

  static double rowHeight(BuildContext context) {
    final double nameHeight = _lineHeight(context, 12, FontWeight.w600);
    final double priceHeight = _lineHeight(context, 10, FontWeight.w600);
    final double normalHeight = 10 + 44 + 4 + nameHeight + 2 + priceHeight + 6;
    final double selectedHeight = 10 + 44 + 4 + priceHeight + 4 + sendButtonHeight(context) + 6;
    return normalHeight.clamp(selectedHeight, double.infinity).clamp(104.0, double.infinity).toDouble();
  }

  static double _lineHeight(BuildContext context, double fontSize, FontWeight weight) {
    final painter = TextPainter(
      text: TextSpan(
        text: '0',
        style: DefaultTextStyle.of(context).style.merge(TextStyle(fontSize: fontSize, height: 1.2, fontWeight: weight)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}
