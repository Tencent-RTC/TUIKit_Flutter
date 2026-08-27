import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/color_scheme.dart';
import '../theme/font.dart';
import '../theme/theme_state.dart';
import '../utils/app_builder.dart';

enum AvatarType {
  image,
  text,
  symbol,
  local,
}

enum AvatarSize {
  xs(24),
  s(32),
  m(40),
  l(48),
  xl(64),
  xxl(96);

  const AvatarSize(this.value);
  final double value;

  double get borderRadius {
    switch (this) {
      case AvatarSize.xs:
      case AvatarSize.s:
      case AvatarSize.m:
        return 4;
      case AvatarSize.l:
        return 8;
      case AvatarSize.xl:
      case AvatarSize.xxl:
        return 12;
    }
  }
}

enum AvatarShape {
  round,
  roundedRectangle,
  rectangle,
}

enum AvatarStatus {
  none,
  online,
  offline,
}

sealed class AvatarContent {
  const AvatarContent();
}

class AvatarImageContent extends AvatarContent {
  final String? url;
  final String? name;

  const AvatarImageContent({this.url, this.name});
}

class AvatarTextContent extends AvatarContent {
  final String name;

  const AvatarTextContent(this.name);
}

class AvatarSymbolContent extends AvatarContent {
  const AvatarSymbolContent();
}

class AvatarLocalContent extends AvatarContent {
  final bool isGroup;

  const AvatarLocalContent({this.isGroup = false});
}

sealed class AvatarBadge {
  const AvatarBadge();
}

class NoBadge extends AvatarBadge {
  const NoBadge();
}

class DotBadge extends AvatarBadge {
  const DotBadge();
}

class TextBadge extends AvatarBadge {
  final String text;

  const TextBadge(this.text);
}

class CountBadge extends AvatarBadge {
  final int count;

  const CountBadge(this.count);
}

class Avatar extends StatelessWidget {
  final AvatarContent content;
  final AvatarSize size;
  final AvatarShape? shape;
  final AvatarStatus status;
  final AvatarBadge badge;
  final VoidCallback? onClick;

  const Avatar({
    super.key,
    required this.content,
    this.size = AvatarSize.m,
    this.shape,
    this.status = AvatarStatus.none,
    this.badge = const NoBadge(),
    this.onClick,
  });

  Avatar.image({
    Key? key,
    String? url,
    String? name,
    AvatarSize size = AvatarSize.m,
    AvatarShape? shape,
    badge = const NoBadge(),
    VoidCallback? onClick,
  }) : this(
          key: key,
          content: AvatarImageContent(url: url, name: name),
          size: size,
          shape: shape,
          status: AvatarStatus.none,
          badge: badge,
          onClick: onClick,
        );

  TextStyle _fontForAvatarSize(AvatarSize size) {
    switch (size) {
      case AvatarSize.xs:
        return FontScheme.caption3Bold;
      case AvatarSize.s:
        return FontScheme.caption2Bold;
      case AvatarSize.m:
        return FontScheme.caption1Bold;
      case AvatarSize.l:
        return FontScheme.body4Bold;
      case AvatarSize.xl:
        return FontScheme.body1Bold;
      case AvatarSize.xxl:
        return FontScheme.title2Bold;
    }
  }

  AvatarShape _getAvatarShape(AvatarShape? shape, AvatarSize size) {
    if (shape != null) {
      return shape;
    }
    
    final appBuilder = AppBuilder.getInstance();
    final avatarConfig = appBuilder.avatarConfig;
    
    switch (avatarConfig.shape) {
      case AppBuilder.AVATAR_SHAPE_CIRCULAR:
        return AvatarShape.round;
      case AppBuilder.AVATAR_SHAPE_ROUNDED:
        return AvatarShape.roundedRectangle;
      case AppBuilder.AVATAR_SHAPE_SQUARE:
        return AvatarShape.rectangle;
      default:
        return AvatarShape.round;
    }
  }

  Widget _buildAvatarContent(SemanticColorScheme colors) {
    switch (content) {
      case AvatarImageContent imageContent:
        return _buildImageAvatar(imageContent, colors);
      case AvatarTextContent textContent:
        return _buildTextAvatar(textContent.name, colors);
      case AvatarSymbolContent():
        return _buildSymbolAvatar(colors);
      case AvatarLocalContent localContent:
        return _buildLocalAvatar(localContent.isGroup, colors);
    }
  }

  Widget _buildImageAvatar(AvatarImageContent imageContent, SemanticColorScheme colors) {
    if (imageContent.url != null && imageContent.url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageContent.url!,
        width: size.value,
        height: size.value,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildTextOrSymbolAvatar(imageContent.name, colors),
        errorWidget: (context, url, error) => _buildTextOrSymbolAvatar(imageContent.name, colors),
      );
    } else {
      return _buildTextOrSymbolAvatar(imageContent.name, colors);
    }
  }

  Widget _buildTextAvatar(String name, SemanticColorScheme colors) {
    return _buildTextOrSymbolAvatar(name, colors);
  }

  Widget _buildSymbolAvatar(SemanticColorScheme colors) {
    final actualShape = _getAvatarShape(shape, size);
    return Container(
      width: size.value,
      height: size.value,
      decoration: BoxDecoration(
        color: colors.bgColorAvatar,
        shape: actualShape == AvatarShape.round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: actualShape == AvatarShape.roundedRectangle
            ? BorderRadius.circular(size.borderRadius)
            : null,
      ),
      child: Icon(
        Icons.person,
        size: size.value * 0.6,
        color: colors.textColorPrimary,
      ),
    );
  }

  Widget _buildLocalAvatar(bool isGroup, SemanticColorScheme colors) {
    final actualShape = _getAvatarShape(shape, size);
    return Container(
      width: size.value,
      height: size.value,
      decoration: BoxDecoration(
        color: colors.bgColorAvatar,
        shape: actualShape == AvatarShape.round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: actualShape == AvatarShape.roundedRectangle
            ? BorderRadius.circular(size.borderRadius)
            : null,
      ),
      child: Icon(
        isGroup ? Icons.group : Icons.person,
        size: size.value * 0.6,
        color: colors.textColorPrimary,
      ),
    );
  }

  Widget _buildTextOrSymbolAvatar(String? name, SemanticColorScheme colors) {
    final actualShape = _getAvatarShape(shape, size);
    return Container(
      width: size.value,
      height: size.value,
      decoration: BoxDecoration(
        color: colors.bgColorAvatar,
        shape: actualShape == AvatarShape.round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: actualShape == AvatarShape.roundedRectangle
            ? BorderRadius.circular(size.borderRadius)
            : null,
      ),
      child: Center(
        child: name != null && name.isNotEmpty
            ? Text(
                name.substring(0, 1).toUpperCase(),
                style: _fontForAvatarSize(size).copyWith(
                  color: colors.textColorPrimary,
                ),
              )
            : Icon(
                Icons.person,
                size: size.value * 0.6,
                color: colors.textColorPrimary,
              ),
      ),
    );
  }

  Widget _buildStatusDot(SemanticColorScheme colors) {
    if (status == AvatarStatus.none) return const SizedBox.shrink();

    Color dotColor;
    switch (status) {
      case AvatarStatus.online:
        dotColor = colors.textColorSuccess;
        break;
      case AvatarStatus.offline:
        dotColor = Colors.grey.withOpacity(0.5);
        break;
      case AvatarStatus.none:
        dotColor = Colors.transparent;
        break;
    }

    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
          border: Border.all(color: colors.bgColorDefault, width: 1),
        ),
      ),
    );
  }

  Widget _buildBadgeView(SemanticColorScheme colors) {
    switch (badge) {
      case NoBadge():
        return const SizedBox.shrink();
      case DotBadge():
        return Positioned(
          right: -3,
          top: -3,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colors.textColorError,
              shape: BoxShape.circle,
            ),
          ),
        );
      case TextBadge textBadge:
        return Positioned(
          right: -5,
          top: -5,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            decoration: BoxDecoration(
              color: colors.textColorError,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              textBadge.text,
              style: FontScheme.caption3Medium.copyWith(
                color: colors.textColorButton,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      case CountBadge countBadge:
        final text = countBadge.count > 99 ? "99+" : "${countBadge.count}";
        final bool isSingleDigit = text.length == 1;
        return Positioned(
          right: -5,
          top: -5,
          child: Container(
            alignment: Alignment.center,
            padding: isSingleDigit
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: isSingleDigit
                ? const BoxConstraints.tightFor(width: 20, height: 20)
                : const BoxConstraints(minWidth: 20, minHeight: 20),
            decoration: BoxDecoration(
              color: colors.textColorError,
              shape: isSingleDigit ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isSingleDigit ? null : BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: FontScheme.caption3Medium.copyWith(
                color: colors.textColorButton,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    
    Widget avatar = _buildAvatarContent(colorsTheme);

    final actualShape = _getAvatarShape(shape, size);

    switch (actualShape) {
      case AvatarShape.round:
        avatar = ClipOval(child: avatar);
        break;
      case AvatarShape.roundedRectangle:
        avatar = ClipRRect(
          borderRadius: BorderRadius.circular(size.borderRadius),
          child: avatar,
        );
        break;
      case AvatarShape.rectangle:
        avatar = ClipRect(child: avatar);
        break;
    }

    // Keep the layout size equal to the avatar's own size regardless of
    // whether a badge is present, so callers can align siblings consistently.
    // The badge overflows the Stack via `clipBehavior: Clip.none` and is
    // expected to render into the parent's own padding area.
    Widget result = Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        _buildStatusDot(colorsTheme),
        _buildBadgeView(colorsTheme),
      ],
    );

    if (onClick != null) {
      result = GestureDetector(
        onTap: onClick,
        child: result,
      );
    }

    return result;
  }
} 