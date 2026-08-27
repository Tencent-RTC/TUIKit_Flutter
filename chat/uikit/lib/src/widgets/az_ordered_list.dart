import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/theme/color_scheme.dart';
import 'package:tuikit_atomic_x/base_component/theme/font.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';
import 'package:tencent_chat_uikit/src/third_party/azlistview/azlistview.dart';
import 'package:tencent_chat_uikit/src/third_party/lpinyin/lpinyin.dart';

import 'package:tuikit_atomic_x/base_component/basic_controls/avatar.dart';

/// Row metrics shared by the list item and its divider, so the divider always
/// starts where the label starts.
const double azItemHorizontalPadding = 16;
const double azItemAvatarSpacing = 12;
const AvatarSize azItemAvatarSize = AvatarSize.m;

class AZOrderedListItem {
  final String key;
  final String label;
  final String? avatarURL;
  final dynamic extraData;
  final Widget Function(BuildContext context)? nameAccessoryBuilder;

  const AZOrderedListItem({
    required this.key,
    required this.label,
    this.avatarURL,
    this.extraData,
    this.nameAccessoryBuilder,
  });
}

class AZOrderedListConfig {
  final bool showIndexBar;
  final String emptyText;
  final Widget? emptyIcon;
  final Function(AZOrderedListItem)? onItemClick;

  const AZOrderedListConfig({
    this.showIndexBar = true,
    this.emptyText = '',
    this.emptyIcon,
    this.onItemClick,
  });
}

class ItemModel extends ISuspensionBean {
  final AZOrderedListItem item;
  String tagIndex = '';
  String namePinyin = '';
  bool isSelected = false;

  ItemModel({required this.item});

  @override
  String getSuspensionTag() => tagIndex;

  @override
  bool isShowSuspension = true;
}

class AZOrderedList extends StatefulWidget {
  final List<AZOrderedListItem> dataSource;
  final AZOrderedListConfig config;
  final Widget? header;
  final Widget? footer;

  const AZOrderedList({
    super.key,
    required this.dataSource,
    required this.config,
    this.header,
    this.footer,
  });

  @override
  State<AZOrderedList> createState() => _AZOrderedListState();
}

class _AZOrderedListState extends State<AZOrderedList> {
  List<ItemModel> _itemList = [];
  late SemanticColorScheme colorsTheme;

  @override
  void initState() {
    super.initState();
    _initItemList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void didUpdateWidget(AZOrderedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      _initItemList();
    }
  }

  void _initItemList() {
    final List<ItemModel> showList = [];
    for (var item in widget.dataSource) {
      final model = ItemModel(item: item);
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

  void _onItemTap(ItemModel itemModel) {
    final item = itemModel.item;
    widget.config.onItemClick?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    return _buildListView();
  }

  Widget _buildListView() {
    Widget listView;

    if (_itemList.isEmpty) {
      listView = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.config.emptyIcon ??
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: colorsTheme.textColorSecondary,
                ),
            const SizedBox(height: 16),
            Text(
              widget.config.emptyText,
              style: TextStyle(
                fontSize: 16,
                color: colorsTheme.textColorSecondary,
              ),
            ),
          ],
        ),
      );
    } else {
      if (widget.config.showIndexBar) {
        listView = AzListView(
          data: _itemList,
          itemCount: _itemList.length,
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
        );
      } else {
        listView = AzListView(
          data: _itemList,
          itemCount: _itemList.length,
          itemBuilder: (context, index) {
            final itemModel = _itemList[index];
            return _buildItemWidget(itemModel);
          },
          physics: const BouncingScrollPhysics(),
          susItemBuilder: (context, index) {
            final itemModel = _itemList[index];
            return _buildSuspensionWidget(itemModel.getSuspensionTag());
          },
          indexBarData: const [],
        );
      }
    }

    if (widget.header != null || widget.footer != null) {
      return Column(
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            child: Container(
              color: colorsTheme.bgColorInput,
              child: listView,
            ),
          ),
          if (widget.footer != null) widget.footer!,
        ],
      );
    }

    return listView;
  }

  Widget _buildItemWidget(ItemModel itemModel) {
    final item = itemModel.item;

    return InkWell(
      onTap: () => _onItemTap(itemModel),
      splashColor: colorsTheme.clearColor,
      highlightColor: colorsTheme.clearColor,
      child: Container(
        color: colorsTheme.listColorDefault,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: azItemHorizontalPadding,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Avatar.image(
                    name: item.label,
                    url: item.avatarURL,
                    size: azItemAvatarSize,
                  ),
                  const SizedBox(width: azItemAvatarSpacing),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            item.label,
                            style: FontScheme.body4Regular.copyWith(
                              color: colorsTheme.textColorPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.nameAccessoryBuilder != null) ...[
                          const SizedBox(width: 8),
                          item.nameAccessoryBuilder!(context),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            buildAZItemDivider(colorsTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSuspensionWidget(String tag) {
    if (tag == "#") {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: azItemHorizontalPadding),
      alignment: Alignment.centerLeft,
      color: colorsTheme.bgColorInput,
      child: Text(
        tag,
        style: FontScheme.caption2Regular.copyWith(
          color: colorsTheme.textColorTertiary,
        ),
      ),
    );
  }
}

/// Divider aligned with the label column: starts where the text starts and
/// stops [azItemHorizontalPadding] short of the right edge.
Widget buildAZItemDivider(SemanticColorScheme colorsTheme) {
  return Padding(
    padding: EdgeInsets.only(
      left: azItemHorizontalPadding + azItemAvatarSize.value + azItemAvatarSpacing,
      right: azItemHorizontalPadding,
    ),
    child: Divider(
      height: 0.5,
      thickness: 0.5,
      color: colorsTheme.strokeColorPrimary,
    ),
  );
}
