import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A host-app supplied entry in the message input "more" panel (the grid behind
/// the plus button), appended after the built-in actions.
///
/// Provide either [iconAssetName] (an SVG, tinted to match the built-in icons)
/// or [iconData]; when both are null a generic placeholder is drawn.
class MessageInputMoreAction {
  /// Stable identifier, so hosts can tell their own actions apart.
  final String id;

  /// Label rendered under the icon tile.
  final String title;

  /// SVG asset path. Resolved against [iconPackage].
  final String? iconAssetName;

  /// Package owning [iconAssetName]. Leave null for assets declared by the
  /// host application itself.
  final String? iconPackage;

  /// Material icon used when [iconAssetName] is not provided.
  final IconData? iconData;

  /// Invoked when the user taps the item. [conversationID] is the conversation
  /// the input is currently attached to.
  final void Function(BuildContext context, String conversationID) onTap;

  const MessageInputMoreAction({
    required this.id,
    required this.title,
    required this.onTap,
    this.iconAssetName,
    this.iconPackage,
    this.iconData,
  });

  /// Renders the glyph inside the panel's icon tile, matching the sizing and
  /// tinting of the built-in actions.
  Widget buildIcon(Color color) {
    final assetName = iconAssetName;
    if (assetName != null) {
      return SvgPicture.asset(
        assetName,
        package: iconPackage,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        width: 26,
        height: 22,
      );
    }
    return Icon(iconData ?? Icons.add_circle_outline, color: color, size: 24);
  }
}
