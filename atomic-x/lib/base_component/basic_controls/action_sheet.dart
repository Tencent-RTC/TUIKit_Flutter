import 'package:flutter/material.dart';
import '../localizations/atomic_localizations.dart';
import '../theme/color_scheme.dart';
import '../theme/theme_state.dart';

class ActionSheetItem {
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isDisabled;

  const ActionSheetItem({
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.isDisabled = false,
  });
}

class ActionSheet {
  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    required List<ActionSheetItem> actions,
    String? cancelText,
    bool showCancel = true,
  }) {
    final colors = BaseThemeProvider.colorsOf(context);
    final appLocale = AtomicLocalizations.of(context);

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // Calculate max height: 60% of screen height
        final maxHeight = MediaQuery.of(context).size.height * 0.6;
        
        return Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: colors.bgColorDialog,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null || message != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Column(
                          children: [
                            if (title != null)
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textColorSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            if (title != null && message != null)
                              const SizedBox(height: 4),
                            if (message != null)
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textColorSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    
                    if (title != null || message != null)
                      _buildDivider(colors),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: actions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final action = entry.value;
                            final isFirst = index == 0 && title == null && message == null;
                            final isLast = index == actions.length - 1;

                            return Column(
                              children: [
                                _buildActionButton(
                                  context: context,
                                  colors: colors,
                                  item: action,
                                  isFirst: isFirst,
                                  isLast: isLast,
                                ),
                                if (!isLast) _buildDivider(colors),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (showCancel) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.bgColorDialog,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _buildCancelButton(
                    context: context,
                    colors: colors,
                    text: cancelText ?? appLocale.cancel,
                  ),
                ),
              ],

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildActionButton({
    required BuildContext context,
    required SemanticColorScheme colors,
    required ActionSheetItem item,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color textColor;
    if (item.isDisabled) {
      textColor = colors.textColorDisable;
    } else if (item.isDestructive) {
      textColor = colors.textColorError;
    } else {
      textColor = colors.buttonColorPrimaryDefault;
    }

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: item.isDisabled ? null : () {
          Navigator.of(context).pop();
          item.onTap();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(14) : Radius.zero,
              bottom: isLast ? const Radius.circular(14) : Radius.zero,
            ),
          ),
        ),
        child: Text(
          item.title,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  static Widget _buildCancelButton({
    required BuildContext context,
    required SemanticColorScheme colors,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: colors.buttonColorPrimaryDefault,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Widget _buildDivider(SemanticColorScheme colors) {
    return Container(
      height: 0.5,
      color: colors.strokeColorPrimary,
    );
  }
}

class BottomInputSheet {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? hintText,
    String? initialText,
    String? confirmText,
    String? cancelText,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    final colors = BaseThemeProvider.colorsOf(context);
    final atomicLocale = AtomicLocalizations.of(context);
    final controller = TextEditingController(text: initialText ?? '');

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.bgColorDialog,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textColorPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: colors.bgColorInput,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLength: maxLength,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      counterText: '',
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colors.buttonColorSecondaryDefault,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          cancelText ?? atomicLocale.cancel,
                          style: TextStyle(
                            color: colors.textColorPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          Navigator.of(context).pop(text);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colors.buttonColorPrimaryDefault,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          confirmText ?? atomicLocale.confirm,
                          style: TextStyle(
                            color: colors.textColorButton,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 