import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../l10n/language_store.dart';
import '../../../l10n/live_kit_localizations.dart';
import '../../pusher_style.dart';

/// 画面源配置弹窗统一宽度（摄像头 / 图片 / 本地视频 / 在线视频）。
const double kSourceDialogWidth = 420;

/// 弹出画面源配置弹窗的通用包装（透明遮罩 + 淡入动画）。
Future<T?> showSourceConfigDialog<T>(
  BuildContext context, {
  required String barrierLabel,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// 本地文件校验：非空、扩展名白名单、文件存在。返回错误文案或 null。
/// [label] 为已本地化的文件类型名（如"图片"/"Image"）。
String? validateSourceFile(String? path, Set<String> extensions, String label) {
  final strings = currentLiveKitStrings();
  if (path == null || path.isEmpty) {
    return strings.filePickRequired(label);
  }
  final dot = path.lastIndexOf('.');
  final ext = dot >= 0 ? path.substring(dot + 1).toLowerCase() : '';
  if (!extensions.contains(ext)) {
    return strings.fileFormatUnsupported(label, ext);
  }
  if (!File(path).existsSync()) {
    return strings.fileNotReadable;
  }
  return null;
}

/// 弹窗骨架：遮罩（背景模糊 + 压暗）+ 不透明面板 + 标题栏 + 内容 + 底部按钮。
///
/// [height] 为空时高度随内容自适应；非空时固定高度、内容区撑满
/// （屏幕共享弹窗使用 1000x650 固定尺寸）。
class SourceDialogShell extends StatelessWidget {
  const SourceDialogShell({
    super.key,
    required this.icon,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    required this.children,
    this.errorText,
    this.confirmEnabled = true,
    this.width = kSourceDialogWidth,
    this.height,
  });

  final IconData icon;
  final String title;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final List<Widget> children;
  final String? errorText;

  /// 确认按钮是否可点击（必填项未满足时禁用）。
  final bool confirmEnabled;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final fixedHeight = height != null;
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          ...children,
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
              style: const TextStyle(fontSize: 12, color: PusherStyle.danger),
            ),
          ],
        ],
      ),
    );
    return Stack(
      children: [
        // 遮罩：背景模糊 + 半透明黑，点击关闭（对齐添加画面源弹窗）。
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
        ),
        Center(
          child: Container(
            width: width,
            height: height,
            decoration: PusherStyle.dialogPanel(),
            clipBehavior: Clip.antiAlias,
            // 弹窗路由在 PusherView 的 Material 之外：透明 Material 提供
            // 正常 DefaultTextStyle 与 Material 祖先。
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize:
                    fixedHeight ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  _DialogHeader(icon: icon, title: title),
                  Container(height: 1, color: PusherStyle.white6),
                  if (fixedHeight) Expanded(child: content) else content,
                  Container(height: 1, color: PusherStyle.white6),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SourceDialogButton(
                          label: LiveKitLocalizations.of(context).commonCancel,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        SourceDialogButton(
                          label: confirmLabel,
                          primary: true,
                          enabled: confirmEnabled,
                          onTap: onConfirm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: PusherStyle.textTertiary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PusherStyle.textEmphasis,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.close,
              size: 14,
              color: PusherStyle.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹窗按钮（主 = 品牌渐变 / 次 = 软面板底），紧凑尺寸、文字居中。
class SourceDialogButton extends StatefulWidget {
  const SourceDialogButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  State<SourceDialogButton> createState() => _SourceDialogButtonState();
}

class _SourceDialogButtonState extends State<SourceDialogButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: widget.primary && enabled
                ? LinearGradient(
                    colors: _hovering
                        ? const [PusherStyle.brand2, PusherStyle.brand]
                        : const [PusherStyle.brand, PusherStyle.brand2],
                  )
                : null,
            color: widget.primary
                ? (enabled ? null : PusherStyle.white8)
                : (_hovering ? PusherStyle.white10 : PusherStyle.white6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.primary ? FontWeight.w500 : FontWeight.normal,
              color: widget.primary
                  ? (enabled ? Colors.white : PusherStyle.textHint)
                  : PusherStyle.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 字段标签（12px 灰字，label 在上的上下结构）。
class SourceFieldLabel extends StatelessWidget {
  const SourceFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: PusherStyle.textTertiary),
    );
  }
}

/// 辅助说明文字（12px，与标签同色系）。
class SourceHintText extends StatelessWidget {
  const SourceHintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: PusherStyle.textTertiary),
    );
  }
}

/// 下拉选项数据。
class SourceDropdownItem<T> {
  const SourceDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// 项目配色下拉：字段样式与软面板一致，选项菜单固定在字段【正下方】
/// 弹出（只覆盖入口下方内容，绝不遮挡入口与标签），贴近屏幕底部时
/// 收进屏幕内、菜单内部滚动。
///
/// Flutter 自带 DropdownButton 会把「当前选中项」对齐到按钮上（选中项
/// 靠后时菜单向上弹出遮挡入口），无法控制方向，故自绘。
class SourceDropdown<T> extends StatefulWidget {
  const SourceDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
  });

  final List<SourceDropdownItem<T>> items;
  final ValueChanged<T> onChanged;

  /// 当前选中值；null 时显示 [hint] 占位。
  final T? value;
  final String? hint;

  @override
  State<SourceDropdown<T>> createState() => _SourceDropdownState<T>();
}

/// 下拉选项行高。
const double _kDropdownItemHeight = 36;

class _SourceDropdownState<T> extends State<SourceDropdown<T>> {
  static const double _kFieldHeight = 36;
  static const double _kMenuGap = 4;
  static const double _kMenuMargin = 8;

  OverlayEntry? _menuEntry;

  bool get _open => _menuEntry != null;

  String? get _currentLabel {
    for (final item in widget.items) {
      if (item.value == widget.value) {
        return item.label;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _toggle() {
    if (_open || widget.items.isEmpty) {
      _removeMenu();
      return;
    }
    _openMenu();
  }

  void _openMenu() {
    final box = context.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero, ancestor: overlay);
    final overlaySize = overlay.size;
    final menuTop = anchor.dy + box.size.height + _kMenuGap;
    final maxMenuHeight = (overlaySize.height - menuTop - _kMenuMargin)
        .clamp(0.0, double.infinity);
    final left = anchor.dx.clamp(
      0.0,
      (overlaySize.width - box.size.width).clamp(0.0, double.infinity),
    );

    _menuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 全屏透明点击层：点菜单外任意位置关闭。
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeMenu,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: menuTop.clamp(0.0, double.infinity),
            width: box.size.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  // 与原 DropdownButton 的 canvasColor 一致。
                  color: const Color(0xFF2A2536),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PusherStyle.white8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxMenuHeight),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        for (final item in widget.items)
                          _SourceDropdownMenuItem<T>(
                            item: item,
                            selected: item.value == widget.value,
                            onTap: () {
                              _removeMenu();
                              widget.onChanged(item.value);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_menuEntry!);
  }

  void _removeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _currentLabel != null;
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: _kFieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: PusherStyle.softPanel(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? _currentLabel! : (widget.hint ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue
                      ? PusherStyle.textPrimary
                      : PusherStyle.textDisabled,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _open
                  ? RemixIcons.arrow_up_s_line
                  : RemixIcons.arrow_down_s_line,
              size: 14,
              color: PusherStyle.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 下拉菜单项（悬停高亮，选中项常亮）。
class _SourceDropdownMenuItem<T> extends StatefulWidget {
  const _SourceDropdownMenuItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SourceDropdownItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SourceDropdownMenuItem<T>> createState() =>
      _SourceDropdownMenuItemState<T>();
}

class _SourceDropdownMenuItemState<T>
    extends State<_SourceDropdownMenuItem<T>> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovering;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _kDropdownItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          color: highlighted ? PusherStyle.white10 : Colors.transparent,
          child: Text(
            widget.item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: highlighted
                  ? PusherStyle.textPrimary
                  : PusherStyle.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 开关（对齐设计稿 toggle-switch：开启时品牌色底 + 白色圆点）。
class SourceToggleSwitch extends StatelessWidget {
  const SourceToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? PusherStyle.brand : PusherStyle.white15,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 120),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// 文件选择行：选择按钮 + 已选文件路径。
class SourceFilePickerRow extends StatelessWidget {
  const SourceFilePickerRow({
    super.key,
    required this.path,
    required this.placeholder,
    required this.pickerLabel,
    required this.extensions,
    required this.onPicked,
  });

  final String? path;
  final String placeholder;
  final String pickerLabel;
  final Set<String> extensions;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 4, right: 10),
      decoration: PusherStyle.softPanel(),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pick,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: PusherStyle.softPanel(radius: 6),
              child: Text(
                pickerLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: PusherStyle.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path ?? placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: path == null
                    ? PusherStyle.textTertiary
                    : PusherStyle.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: pickerLabel, extensions: extensions.toList()),
      ],
    );
    if (file != null) {
      onPicked(file.path);
    }
  }
}

/// 深色输入框。
class SourceDarkTextField extends StatelessWidget {
  const SourceDarkTextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: PusherStyle.softPanel(),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12, color: PusherStyle.textPrimary),
        cursorColor: PusherStyle.brand2,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: PusherStyle.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// 通用滑杆组：label 与数值一行（上下结构，label 在上）、滑杆通栏在下。
class LabeledSliderGroup extends StatelessWidget {
  const LabeledSliderGroup({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.display,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SourceFieldLabel(label),
            Text(
              display,
              style: const TextStyle(
                fontSize: 12,
                color: PusherStyle.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GradientSlider(
          fraction: (value / max).clamp(0.0, 1.0),
          tickCount: divisions,
          onChanged: (fraction) {
            final raw = fraction * max;
            onChanged(divisions != null ? raw.roundToDouble() : raw);
          },
        ),
      ],
    );
  }
}

/// 播放音量滑杆组（0-100）。
class VolumeSliderGroup extends StatelessWidget {
  const VolumeSliderGroup({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  final int volume;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LabeledSliderGroup(
      label: LiveKitLocalizations.of(context).playbackVolume,
      value: volume.toDouble(),
      max: 100,
      display: '$volume',
      onChanged: (value) => onChanged(value.round()),
    );
  }
}

class GradientSlider extends StatelessWidget {
  const GradientSlider({
    super.key,
    required this.fraction,
    required this.onChanged,
    this.tickCount,
  });

  /// 已滑过比例（0 ~ 1）。
  final double fraction;
  final ValueChanged<double> onChanged;

  final int? tickCount;

  static const double _trackHeight = 6;
  static const double _thumbSize = 14;
  static const double _tickSize = 4;

  void _update(double dx, double width) {
    if (width <= 0) {
      return;
    }
    onChanged((dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // 把手中心限制在轨道两端内（不越出轨道）。
        final thumbCenter = (fraction * width).clamp(
          _thumbSize / 2,
          (width - _thumbSize / 2).clamp(_thumbSize / 2, double.infinity),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _update(details.localPosition.dx, width),
          onHorizontalDragUpdate: (details) =>
              _update(details.localPosition.dx, width),
          child: SizedBox(
            height: 20,
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: _thumbSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 未滑过轨道（铺满整行，Center 松约束下必须显式满宽）。
                    Positioned.fill(
                      top: (_thumbSize - _trackHeight) / 2,
                      bottom: (_thumbSize - _trackHeight) / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF414959),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    // 已滑过轨道（纯色品牌红，无渐变）。
                    Positioned(
                      left: 0,
                      top: (_thumbSize - _trackHeight) / 2,
                      bottom: (_thumbSize - _trackHeight) / 2,
                      width: thumbCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: PusherStyle.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (tickCount != null && tickCount! > 0)
                      for (var i = 0; i <= tickCount!; i++)
                        Positioned(
                          left: ((i / tickCount!) * width - _tickSize / 2)
                              .clamp(0.0, (width - _tickSize).clamp(0.0, double.infinity)),
                          top: (_thumbSize - _tickSize) / 2,
                          width: _tickSize,
                          height: _tickSize,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFFFFFFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    // 圆形把手。
                    Positioned(
                      left: thumbCenter - _thumbSize / 2,
                      child: Container(
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PusherStyle.danger,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
