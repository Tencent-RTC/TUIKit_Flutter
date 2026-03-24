import 'package:flutter/material.dart';

/// General-purpose settings panel container - presented as a half-screen bottom sheet
///
/// Responsibilities: manage the presentation style, animation, and lifecycle of the panel
/// Design: accept any `Widget` as content and present it as a half-screen bottom sheet through `showModalBottomSheet`
///
/// Reuse notes:
/// - `BasicStreaming` stage: `showSettingPanel` + `DeviceSettingWidget`
/// - `Interactive` stage: `showSettingPanel` + `TabbedSettingView([DeviceSettingWidget, BeautySettingWidget, ...])`
/// - Keep the container unchanged and only add new content widgets

// MARK: - Public API

/// Show the panel as a half-screen bottom sheet on the given `context`
/// - Parameters:
///   - context: `BuildContext`
///   - title: Panel title
///   - contentWidget: Content widget
///   - height: Custom panel height (uses the default height when null)
///   - backgroundColor: Custom panel background color (uses the theme background when null)
void showSettingPanel({
  required BuildContext context,
  required String title,
  required Widget contentWidget,
  double? height,
  Color? backgroundColor,
}) {
  final bgColor = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

  // Automatically adapt the title and close button colors based on the background brightness
  final isDarkBackground = !_isLightColor(bgColor);
  final titleColor = isDarkBackground ? Colors.white : Colors.black87;
  final closeColor = isDarkBackground ? Colors.white.withValues(alpha: 0.6) : Colors.black38;
  final separatorColor = isDarkBackground ? Colors.white.withValues(alpha: 0.15) : Colors.black12;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (BuildContext context) {
      return SizedBox(
        height: height ?? MediaQuery.of(context).size.height * 0.45,
        child: Column(
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Title
                    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: titleColor)),
                    // Close button
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.cancel, size: 24, color: closeColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Divider
            Container(height: 0.5, color: separatorColor),

            // Content area
            Expanded(child: contentWidget),
          ],
        ),
      );
    },
  );
}

// MARK: - Color Helper

/// Determine whether a color is light based on perceived brightness
bool _isLightColor(Color color) {
  // Use the W3C relative luminance formula
  final luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
  return luminance > 0.5;
}
