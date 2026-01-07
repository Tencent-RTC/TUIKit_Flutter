import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/avatar.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/button.dart' as atomicx;
import 'package:tuikit_atomic_x/base_component/localizations/atomic_localizations.dart';
import 'package:tuikit_atomic_x/base_component/theme/color_scheme.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';

class UserPickerData {
  final String key;
  final String label;
  final String? avatarURL;
  final dynamic extraData;
  final bool isPreSelected;

  const UserPickerData({
    required this.key,
    required this.label,
    this.avatarURL,
    this.extraData,
    this.isPreSelected = false,
  });
}

class SelectableItemModel extends ISuspensionBean {
  final UserPickerData item;
  String tagIndex = '';
  String namePinyin = '';

  SelectableItemModel({required this.item});

  @override
  String getSuspensionTag() => tagIndex;

  @override
  bool isShowSuspension = true;
}

class UserPicker extends StatefulWidget {
  final List<UserPickerData> dataSource;
  final List<String>? defaultSelectedItems;
  final List<String>? lockedItems;
  final int? maxCount;
  final Function(List<UserPickerData>)? onSelectedChanged;
  final Function(List<UserPickerData>)? onMaxCountExceed;
  final String? title;
  final String? confirmText;
  final bool showSelectedList;
  final VoidCallback? onReachEnd;
  final Function(List<UserPickerData>)? onConfirm;
  
  /// Optional widget to display at the top of the list (before the sorted items)
  final Widget? headerWidget;

  const UserPicker({
    super.key,
    required this.dataSource,
    this.defaultSelectedItems,
    this.lockedItems,
    this.onSelectedChanged,
    this.onMaxCountExceed,
    this.title,
    this.confirmText,
    this.onConfirm,
    this.showSelectedList = false,
    this.onReachEnd,
    this.maxCount,
    this.headerWidget,
  });

  @override
  State<UserPicker> createState() => _UserPickerState();
}

class _UserPickerState extends State<UserPicker> {
  List<SelectableItemModel> _itemList = [];
  List<UserPickerData> _selectedItems = [];
  ItemPositionsListener? _itemPositionsListener;
  bool _isLoadingMore = false;

  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _initItemList();

    if (widget.onReachEnd != null) {
      _itemPositionsListener = ItemPositionsListener.create();
      _itemPositionsListener!.itemPositions.addListener(_positionListener);
    }
  }

  @override
  void dispose() {
    _itemPositionsListener?.itemPositions.removeListener(_positionListener);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void didUpdateWidget(UserPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dataSource != oldWidget.dataSource) {
      _initItemList();
      _isLoadingMore = false;
    }
  }

  void _initItemList() {
    final List<SelectableItemModel> showList = [];

    // Preserve currently selected items by key when dataSource updates
    final previousSelectedKeys = _selectedItems.map((item) => item.key).toSet();
    
    _selectedItems = [];
    final defaultKeys = widget.defaultSelectedItems ?? [];
    final lockedKeys = widget.lockedItems ?? [];

    for (var item in widget.dataSource) {
      if (defaultKeys.contains(item.key)) {
        _selectedItems.add(item);
      }
    }

    for (var item in widget.dataSource) {
      final model = SelectableItemModel(item: item);
      final name = item.label;

      model.namePinyin = PinyinHelper.getPinyinE(name);

      if (name.isNotEmpty) {
        String firstChar = name[0].toUpperCase();
        if (RegExp(r'^[A-Z]$').hasMatch(firstChar)) {
          model.tagIndex = firstChar;
        } else {
          String pinyin = PinyinHelper.getFirstWordPinyin(name);
          if (pinyin.isNotEmpty) {
            model.tagIndex = pinyin[0].toUpperCase();
          } else {
            model.tagIndex = '#';
          }
        }
      } else {
        model.tagIndex = '#';
      }

      showList.add(model);

      if ((item.isPreSelected || lockedKeys.contains(item.key)) &&
          !_selectedItems.any((selected) => selected.key == item.key)) {
        _selectedItems.add(item);
      }
      
      // Restore previously selected items that exist in new dataSource
      if (previousSelectedKeys.contains(item.key) &&
          !_selectedItems.any((selected) => selected.key == item.key)) {
        _selectedItems.add(item);
      }
    }

    showList.sort((a, b) {
      if (a.tagIndex == '#' && b.tagIndex != '#') return 1;
      if (a.tagIndex != '#' && b.tagIndex == '#') return -1;
      if (a.tagIndex == b.tagIndex) {
        return a.item.label.compareTo(b.item.label);
      }
      return a.tagIndex.compareTo(b.tagIndex);
    });

    SuspensionUtil.setShowSuspensionStatus(showList);

    setState(() {
      _itemList = showList;
    });
  }

  void _notifySelectionChanged() {
    if (widget.onSelectedChanged != null) {
      final lockedKeys = widget.lockedItems ?? [];

      final selectedByUser = _selectedItems.where((item) {
        return !item.isPreSelected && !lockedKeys.contains(item.key);
      }).toList();

      widget.onSelectedChanged!(selectedByUser);
    }
  }

  void _onItemTap(SelectableItemModel itemModel) {
    final item = itemModel.item;
    final lockedKeys = widget.lockedItems ?? [];

    if (item.isPreSelected || lockedKeys.contains(item.key)) {
      return;
    }

    setState(() {
      if (widget.maxCount == 1) {
        _selectedItems.removeWhere((selected) => !selected.isPreSelected && !lockedKeys.contains(selected.key));
        _selectedItems.add(item);
      } else {
        final isSelected = _selectedItems.any((selected) => selected.key == item.key);
        if (isSelected) {
          _selectedItems.removeWhere((selected) => selected.key == item.key);
        } else {
          if (widget.maxCount != null) {
            if (_selectedItems.length >= widget.maxCount!) {
              if (widget.onMaxCountExceed != null) {
                widget.onMaxCountExceed!(_selectedItems);
              }
              return;
            }
          }

          _selectedItems.add(item);
        }
      }

      _notifySelectionChanged();
    });
  }

  void _positionListener() {
    if (_itemPositionsListener == null || _isLoadingMore || widget.onReachEnd == null) {
      return;
    }

    final positions = _itemPositionsListener!.itemPositions.value;
    if (positions.isEmpty) return;

    final lastVisibleItem = positions.reduce((a, b) => a.index > b.index ? a : b);

    if (lastVisibleItem.itemTrailingEdge > 0.8 && lastVisibleItem.index >= _itemList.length - 3) {
      _isLoadingMore = true;
      widget.onReachEnd!();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

  void _onConfirm() async {
    final lockedKeys = widget.lockedItems ?? [];

    final newSelectedItems = _selectedItems.where((item) {
      return !item.isPreSelected && !lockedKeys.contains(item.key);
    }).toList();

    if (widget.onConfirm != null) {
      try {
        await widget.onConfirm!(newSelectedItems);
      } catch (e) {
        debugPrint('onConfirm callback error: $e');
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop(newSelectedItems);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockedKeys = widget.lockedItems ?? [];

    final newSelectedCount = _selectedItems.where((item) {
      return !item.isPreSelected && !lockedKeys.contains(item.key);
    }).length;

    final hasSelection = widget.maxCount == 1 ? _selectedItems.isNotEmpty : newSelectedCount > 0;

    return Scaffold(
      backgroundColor: colorsTheme.bgColorOperate,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: atomicx.IconButton.buttonContent(
          content: atomicx.IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
          type: atomicx.ButtonType.noBorder,
          size: atomicx.ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title ?? '',
          style: TextStyle(
            color: colorsTheme.textColorPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: hasSelection ? _onConfirm : null,
            child: Text(
              widget.confirmText ?? atomicLocale.confirm,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: hasSelection ? colorsTheme.buttonColorPrimaryActive : colorsTheme.buttonColorPrimaryDisabled,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          if (widget.showSelectedList) _buildSelectedListWidget(),
          if (widget.headerWidget != null) widget.headerWidget!,
          Expanded(
            child: _itemList.isEmpty
                ? const Center()
                : AzListView(
                    data: _itemList,
                    itemCount: _itemList.length,
                    itemPositionsListener: _itemPositionsListener,
                    itemBuilder: (context, index) {
                      final itemModel = _itemList[index];
                      return _buildItemWidget(itemModel);
                    },
                    physics: const BouncingScrollPhysics(),
                    susItemBuilder: (context, index) {
                      final itemModel = _itemList[index];
                      return _buildSuspensionWidget(itemModel.getSuspensionTag());
                    },
                    indexBarData: SuspensionUtil.getTagIndexList(_itemList).where((element) => element != "#").toList(),
                    indexBarOptions: IndexBarOptions(
                      needRebuild: true,
                      ignoreDragCancel: true,
                      downTextStyle: TextStyle(fontSize: 12, color: colorsTheme.textColorButton),
                      downItemDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorsTheme.buttonColorPrimaryDefault,
                      ),
                      indexHintWidth: 40,
                      indexHintHeight: 40,
                      indexHintDecoration: BoxDecoration(
                        color: colorsTheme.buttonColorPrimaryDefault,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      indexHintAlignment: Alignment.centerRight,
                      indexHintChildAlignment: Alignment.center,
                      indexHintOffset: const Offset(-20, 0),
                      indexHintTextStyle: TextStyle(
                        fontSize: 20,
                        color: colorsTheme.textColorButton,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedListWidget() {
    final lockedKeys = widget.lockedItems ?? [];

    final selectedByUser =
        _selectedItems.where((item) => !item.isPreSelected && !lockedKeys.contains(item.key)).toList();

    if (selectedByUser.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: colorsTheme.listColorDefault,
        border: Border(
          bottom: BorderSide(
            color: colorsTheme.strokeColorPrimary,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: selectedByUser.length,
        itemBuilder: (context, index) {
          final item = selectedByUser[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Avatar.image(
                      name: item.label,
                      url: item.avatarURL,
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedItems.removeWhere((selected) => selected.key == item.key);
                          });
                          _notifySelectionChanged();
                        },
                        child: SvgPicture.asset(
                          'chat_assets/icon/close.svg',
                          width: 18,
                          height: 18,
                          package: 'tuikit_atomic_x',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 50,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorsTheme.textColorPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemWidget(SelectableItemModel itemModel) {
    final item = itemModel.item;
    final lockedKeys = widget.lockedItems ?? [];

    final isSelected = _selectedItems.any((selected) => selected.key == item.key);
    final isDisabled = item.isPreSelected || lockedKeys.contains(item.key);

    return InkWell(
      onTap: () => _onItemTap(itemModel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: colorsTheme.bgColorOperate,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12, bottom: 8),
              child: _buildCheckBox(isSelected, isDisabled),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              margin: const EdgeInsets.only(right: 12),
              child: Avatar.image(
                name: item.label,
                url: item.avatarURL,
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(top: 10, bottom: 20, right: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isDisabled ? colorsTheme.textColorDisable : colorsTheme.textColorPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckBox(bool isSelected, bool isDisabled) {
    Color backgroundColor;
    Color borderColor;

    if (isDisabled) {
      backgroundColor = colorsTheme.textColorDisable;
      borderColor = colorsTheme.textColorDisable;
    } else if (isSelected) {
      backgroundColor = colorsTheme.checkboxColorSelected;
      borderColor = colorsTheme.checkboxColorSelected;
    } else {
      backgroundColor = colorsTheme.bgColorOperate;
      borderColor = colorsTheme.textColorDisable;
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: (isSelected || isDisabled)
          ? Icon(
              Icons.check,
              size: 14,
              color: colorsTheme.textColorButton,
            )
          : null,
    );
  }

  Widget _buildSuspensionWidget(String tag) {
    if (tag == "#") {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 16.0, bottom: 5),
      alignment: Alignment.bottomLeft,
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorsTheme.textColorPrimary,
        ),
      ),
    );
  }
}
