import 'package:atomic_x_core/api/device/screen_share_store.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../l10n/language_store.dart';
import '../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import '../../pusher_style.dart';
import '../scene_store.dart';
import 'source_dialog.dart';

/// 添加 / 编辑屏幕共享画面源弹窗：分类（屏幕 / 窗口）+ 缩略图网格选择。
///
/// 布局与其他画面源弹窗不同（固定 1000x650、Tab + 网格 + 内容区撑满），
/// 但骨架 / 按钮 / 文本样式统一走共享层。
/// 返回用户确认后的 [ScreenSourceConfig]；取消返回 null。
/// [initial] 非空时为编辑模式（预选对应分类与源）。
Future<ScreenSourceConfig?> showScreenSourceDialog(
  BuildContext context, {
  ScreenSourceConfig? initial,
}) {
  return showSourceConfigDialog<ScreenSourceConfig>(
    context,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    child: _ScreenSourceDialog(initial: initial),
  );
}

class _ScreenSourceDialog extends StatefulWidget {
  const _ScreenSourceDialog({this.initial});

  final ScreenSourceConfig? initial;

  @override
  State<_ScreenSourceDialog> createState() => _ScreenSourceDialogState();
}

class _ScreenSourceDialogState extends State<_ScreenSourceDialog> {
  late bool _isScreenTab;

  /// 全量共享源缓存（屏幕 + 窗口）。
  ///
  /// 引擎一次枚举即返回全部类型，且该操作在引擎侧开销大（需截取每个
  /// 窗口的缩略图），因此弹窗打开时枚举一次、切换页签仅本地过滤，
  /// 不再重复触发枚举；重开弹窗会重新枚举拿到最新列表。
  List<ShareSource>? _allSources;
  String? _selectedSourceId;
  String? _errorText;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _isScreenTab = widget.initial?.isScreen ?? true;
    _selectedSourceId = widget.initial?.sourceId;
    _loadSources();
  }

  /// 当前页签下展示的源（对全量缓存本地过滤）。
  List<ShareSource>? get _sources {
    final all = _allSources;
    if (all == null) {
      return null;
    }
    return all
        .where(
          (source) => (source.type == ShareSourceType.screen) == _isScreenTab,
        )
        .toList();
  }

  Future<void> _loadSources() async {
    setState(() {
      _allSources = null;
      _errorText = null;
    });
    try {
      // 枚举本身会触发 macOS「屏幕录制」授权弹窗（首次）。
      final sources = await ScreenShareStore.shared
          .getShareSources(
            thumbnailSize: const Size(320, 180),
            iconSize: const Size(48, 48),
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) {
        return;
      }
      setState(() {
        _allSources = sources;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _allSources = const [];
        _errorText = currentLiveKitStrings().screenEnumFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    return SourceDialogShell(
      icon: RemixIcons.computer_line,
      title: _isEdit ? strings.screenEditTitle : strings.screenAddTitle,
      width: 1000,
      height: 650,
      errorText: _errorText,
      confirmLabel: _isEdit ? strings.commonSave : strings.commonAdd,
      confirmEnabled: _selectedSourceId != null,
      onConfirm: _confirm,
      children: [
        _buildCategoryTabs(),
        const SizedBox(height: 12),
        Expanded(child: _buildSourceGrid()),
      ],
    );
  }

  /// 分类 Tab：屏幕 / 窗口（紧凑胶囊，激活项实心品牌色；不撑满整行）。
  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: PusherStyle.softPanel(radius: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _categoryTab(
            label: LiveKitLocalizations.of(context).sourceTypeScreen,
            isScreenTab: true,
          ),
          const SizedBox(width: 2),
          _categoryTab(
            label: LiveKitLocalizations.of(context).screenTabWindow,
            isScreenTab: false,
          ),
        ],
      ),
    );
  }

  Widget _categoryTab({
    required String label,
    required bool isScreenTab,
  }) {
    final selected = _isScreenTab == isScreenTab;
    return GestureDetector(
      onTap: () {
        if (selected) {
          return;
        }
        // 切换页签只做本地过滤（_sources getter），不重新枚举：
        // 引擎侧枚举需截取全部窗口缩略图，重复触发会造成主线程阻塞、UI 卡顿。
        setState(() {
          _isScreenTab = isScreenTab;
          _selectedSourceId = null;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? PusherStyle.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
            color: selected ? Colors.white : PusherStyle.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSourceGrid() {
    final sources = _sources;
    if (sources == null) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: PusherStyle.textTertiary,
          ),
        ),
      );
    }
    if (sources.isEmpty) {
      return Center(
        child: Text(
          LiveKitLocalizations.of(context).screenEmpty(
            _isScreenTab
                ? LiveKitLocalizations.of(context).sourceTypeScreen
                : LiveKitLocalizations.of(context).screenTabWindow,
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.6,
            color: PusherStyle.textDisabled,
          ),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return _ShareSourceCard(
          source: source,
          selected: source.sourceId == _selectedSourceId,
          onTap: source.isMinimizeWindow
              ? null
              : () => setState(() => _selectedSourceId = source.sourceId),
        );
      },
    );
  }

  void _confirm() {
    final source = _sources?.firstWhere(
      (s) => s.sourceId == _selectedSourceId,
    );
    if (source == null) {
      return;
    }
    Navigator.pop(
      context,
      ScreenSourceConfig(
        sourceId: source.sourceId,
        sourceName: source.sourceName,
        isScreen: source.type == ShareSourceType.screen,
        width: source.width > 0 ? source.width : null,
        height: source.height > 0 ? source.height : null,
      ),
    );
  }
}

/// 共享源卡片：缩略图 + 名称，选中描边，最小化窗口灰显不可选。
class _ShareSourceCard extends StatefulWidget {
  const _ShareSourceCard({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final ShareSource source;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_ShareSourceCard> createState() => _ShareSourceCardState();
}

class _ShareSourceCardState extends State<_ShareSourceCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    final disabled = widget.onTap == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: disabled ? 0.4 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: _hovering && !disabled
                  ? PusherStyle.white10
                  : const Color(0x0EFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.selected ? PusherStyle.brand2 : PusherStyle.white8,
                width: widget.selected ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: source.thumbnail != null
                        ? Image(
                            image: source.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _thumbnailFallback(),
                          )
                        : _thumbnailFallback(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      if (source.icon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Image(
                            image: source.icon!,
                            width: 12,
                            height: 12,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          source.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: PusherStyle.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return const Center(
      child: Icon(
        RemixIcons.computer_line,
        size: 20,
        color: PusherStyle.textDisabled,
      ),
    );
  }
}
