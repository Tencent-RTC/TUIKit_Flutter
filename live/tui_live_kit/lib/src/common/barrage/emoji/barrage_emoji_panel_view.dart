import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../live_kit_resources.dart';
import '../../theme/live_theme.dart';
import 'barrage_emoji_converter.dart';

class BarrageEmojiPanelView extends StatefulWidget {
  const BarrageEmojiPanelView({
    super.key,
    required this.onSelect,
    required this.onDelete,
    required this.onSend,
    this.isPresented = true,
    this.isDeleteEnabled = true,
    this.isSendEnabled = false,
  });

  final ValueChanged<BarrageEmoji> onSelect;
  final VoidCallback onDelete;
  final VoidCallback onSend;
  final bool isPresented;
  final bool isDeleteEnabled;
  final bool isSendEnabled;

  @override
  State<BarrageEmojiPanelView> createState() => _BarrageEmojiPanelViewState();
}

class _BarrageEmojiPanelViewState extends State<BarrageEmojiPanelView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(BarrageEmojiPanelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPresented && widget.isPresented) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) _scrollController.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _pageDown() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final visibleHeight = position.viewportDimension - _PanelStyle.controlsReservedHeight;
    if (visibleHeight <= 0) return;
    final target = math.min(position.pixels + visibleHeight, position.maxScrollExtent);
    if (target <= position.pixels) return;
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.viewPaddingOf(context).bottom;
    return ColoredBox(
      color: _PanelStyle.background,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 8,
            left: 16,
            height: 22,
            child: Text(
              LiveKitResources.localizedString('tuilivekit.comment.emoji_frequently_used'),
              style: const TextStyle(
                  color: _PanelStyle.secondaryForeground,
                  fontSize: 12,
                  height: 20 / 12,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none),
            ),
          ),
          Positioned(
            top: 40.5,
            left: 0,
            right: 0,
            bottom: bottomSafeArea,
            child: LayoutBuilder(builder: (context, constraints) {
              final itemWidth = math.max(1.0, (constraints.maxWidth - 18) / 8);
              return GridView.builder(
                key: const ValueKey('barrageEmojiGrid'),
                controller: _scrollController,
                padding: const EdgeInsets.only(left: 9, right: 9, bottom: _PanelStyle.controlsReservedHeight + 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8, crossAxisSpacing: 0, mainAxisSpacing: 11, childAspectRatio: itemWidth / 29),
                itemCount: BarrageEmoji.all.length,
                itemBuilder: (context, index) {
                  final emoji = BarrageEmoji.all[index];
                  return _BarrageEmojiCell(emoji: emoji, onTap: () => widget.onSelect(emoji));
                },
              );
            }),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _PanelStyle.controlsReservedHeight + bottomSafeArea,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x00F6F6F8), _PanelStyle.background, _PanelStyle.background],
                    stops: <double>[0, 0.2, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: bottomSafeArea,
            height: 34,
            child: _ControlButton(
              label: LiveKitResources.localizedString('tuilivekit.comment.emoji_page_down'),
              onTap: _pageDown,
              height: 34,
              child: _controlImage('livekit_comment_page_down'),
            ),
          ),
          Positioned(
            right: 10,
            bottom: bottomSafeArea + 1,
            height: 32,
            child: Row(
              children: <Widget>[
                _ControlButton(
                  label: LiveKitResources.localizedString('tuilivekit.comment.emoji_delete'),
                  onTap: widget.isDeleteEnabled ? widget.onDelete : null,
                  width: 44,
                  backgroundColor: _PanelStyle.deleteBackground,
                  child: Opacity(
                    opacity: widget.isDeleteEnabled ? 1 : 0.45,
                    child: _controlImage('livekit_comment_delete'),
                  ),
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  label: LiveKitResources.localizedString('tuilivekit.common.send'),
                  onTap: widget.isSendEnabled ? widget.onSend : null,
                  width: 64,
                  backgroundColor: LiveTheme.brandBlue,
                  backgroundImage: DecorationImage(
                    image: LiveKitResources.image('livekit_comment_send_background'),
                    fit: BoxFit.fill,
                  ),
                  child: Text(
                    LiveKitResources.localizedString('tuilivekit.common.send'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _controlImage(String name) {
    return Image(
      image: LiveKitResources.image(name),
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: ColoredBox(
          color: _PanelStyle.secondaryForeground,
          child: SizedBox(width: 20, height: 20),
        ),
      ),
    );
  }
}

class _BarrageEmojiCell extends StatelessWidget {
  const _BarrageEmojiCell({required this.emoji, required this.onTap});

  final BarrageEmoji emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        highlightColor: const Color(0x14000000),
        child: Center(child: BarrageEmojiConverter.buildImage(emoji, size: 29)),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.onTap,
    required this.child,
    this.width = 32,
    this.height = 32,
    this.backgroundColor,
    this.backgroundImage,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final double width;
  final double height;
  final Color? backgroundColor;
  final DecorationImage? backgroundImage;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration:
              BoxDecoration(color: backgroundColor, image: backgroundImage, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _PanelStyle {
  static const background = Color(0xFFF6F6F8);
  static const secondaryForeground = Color(0x73000000);
  static const deleteBackground = Color(0xFFE4E6EB);
  static const controlsReservedHeight = 64.0;
}
