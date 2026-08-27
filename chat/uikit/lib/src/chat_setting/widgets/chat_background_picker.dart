import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

import '../../common/language/gen/chat_localizations.dart';
import '../../common/utils/chat_background_store.dart';

/// A selectable chat background: [imageUri] is `null` for the "default"
/// (no image) entry, in which case [thumbnailUri] is `null` too.
class ChatBackgroundPreset {
  const ChatBackgroundPreset({this.imageUri, this.thumbnailUri});

  final String? imageUri;
  final String? thumbnailUri;

  bool get isDefault => imageUri == null;
}

/// The same seven CDN backgrounds the native implementations ship, plus the
/// default (image-less) entry at the head of the list.
class ChatBackgroundPresetProvider {
  ChatBackgroundPresetProvider._();

  static const String _baseUrl =
      'https://im.sdk.qcloud.com/download/tuikit-resource/conversation-backgroundImage';

  static const int _presetCount = 7;

  static String _backgroundUrl(int index) => '$_baseUrl/backgroundImage_${index}_full.png';

  static String _thumbnailUrl(int index) => '$_baseUrl/backgroundImage_$index.png';

  static List<ChatBackgroundPreset> get presets => [
        const ChatBackgroundPreset(),
        for (var i = 1; i <= _presetCount; i++)
          ChatBackgroundPreset(
            imageUri: _backgroundUrl(i),
            thumbnailUri: _thumbnailUrl(i),
          ),
      ];
}

/// Bottom sheet with a two-column grid of the available backgrounds. Picking one
/// dismisses the sheet and reports the selection.
class ChatBackgroundPicker extends StatelessWidget {
  const ChatBackgroundPicker._({required this.selectedImageUri});

  final String? selectedImageUri;

  static const double _previewHeight = 120;

  /// Shows the picker. Completes with `true` when a selection was made so the
  /// caller can refresh its row.
  static Future<bool> show(
    BuildContext context, {
    required String conversationID,
  }) async {
    final selected = await showModalBottomSheet<ChatBackgroundPreset>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChatBackgroundPicker._(
        selectedImageUri: ChatBackgroundStore.shared.peek(conversationID),
      ),
    );
    if (selected == null) return false;
    await ChatBackgroundStore.shared.setImageUri(conversationID, selected.imageUri);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);
    final presets = ChatBackgroundPresetProvider.presets;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.65,
      decoration: BoxDecoration(
        color: colors.bgColorOperate,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  locale.selectChatBackground,
                  style: FontScheme.body4Bold.copyWith(color: colors.textColorPrimary),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(Icons.close, size: 22, color: colors.textColorSecondary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // Fixed preview height, like the native picker. The thumbnails
                // are landscape (662x464), so a tall cell would letterbox them.
                mainAxisExtent: _previewHeight,
              ),
              itemCount: presets.length,
              itemBuilder: (context, index) => _buildCell(context, presets[index], colors, locale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    ChatBackgroundPreset preset,
    SemanticColorScheme colors,
    ChatLocalizations locale,
  ) {
    final isSelected = preset.imageUri == selectedImageUri;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(preset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgColorInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.textColorLink : colors.strokeColorPrimary,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: preset.isDefault
            ? Center(
                child: Text(
                  locale.chatBackgroundDefault,
                  style: FontScheme.caption1Regular.copyWith(color: colors.textColorSecondary),
                ),
              )
            : Image.network(
                preset.thumbnailUri!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textColorTertiary,
                          ),
                        ),
                      ),
                // Surface a failed thumbnail instead of rendering an empty
                // cell, which is indistinguishable from a loaded blank image.
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 24,
                    color: colors.textColorTertiary,
                  ),
                ),
              ),
      ),
    );
  }
}
