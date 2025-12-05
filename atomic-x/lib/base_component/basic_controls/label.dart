import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

enum LabelSize {
  small,
  medium,
  large,
}

class LabelStyleConfig {
  final TextStyle Function(LabelSize) fontStyle;
  final Color Function(SemanticColorScheme) color;
  final int lineLimit;

  const LabelStyleConfig({
    required this.fontStyle,
    required this.color,
    required this.lineLimit,
  });
}

class TitleLabel extends StatelessWidget {
  final LabelSize size;
  final String text;

  const TitleLabel({
    super.key,
    required this.size,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _Label(
      text: text,
      size: size,
      config: _titleLabelConfig,
    );
  }
}

class SubTitleLabel extends StatelessWidget {
  final LabelSize size;
  final String text;

  const SubTitleLabel({
    super.key,
    required this.size,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _Label(
      text: text,
      size: size,
      config: _subTitleLabelConfig,
    );
  }
}

class ItemLabel extends StatelessWidget {
  final LabelSize size;
  final String text;

  const ItemLabel({
    super.key,
    required this.size,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _Label(
      text: text,
      size: size,
      config: _itemLabelConfig,
    );
  }
}

class DangerLabel extends StatelessWidget {
  final LabelSize size;
  final String text;

  const DangerLabel({
    super.key,
    required this.size,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _Label(
      text: text,
      size: size,
      config: _dangerLabelConfig,
    );
  }
}

class CustomLabel extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final Color color;
  final int lineLimit;

  const CustomLabel({
    super.key,
    required this.text,
    required this.textStyle,
    required this.color,
    this.lineLimit = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: textStyle.copyWith(color: color),
      maxLines: lineLimit,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// MARK: - Label Config

const _titleLabelConfig = LabelStyleConfig(
  fontStyle: _getTitleFont,
  color: _getTitleColor,
  lineLimit: 1,
);

const _subTitleLabelConfig = LabelStyleConfig(
  fontStyle: _getSubTitleFont,
  color: _getSubTitleColor,
  lineLimit: 1,
);

const _itemLabelConfig = LabelStyleConfig(
  fontStyle: _getItemFont,
  color: _getItemColor,
  lineLimit: 1,
);

const _dangerLabelConfig = LabelStyleConfig(
  fontStyle: _getDangerFont,
  color: _getDangerColor,
  lineLimit: 1,
);

// MARK: - Font Functions

TextStyle _getTitleFont(LabelSize size) {
  switch (size) {
    case LabelSize.small:
      return FontScheme.body2Bold;
    case LabelSize.medium:
      return FontScheme.body1Bold;
    case LabelSize.large:
      return FontScheme.title2Bold;
  }
}

TextStyle _getSubTitleFont(LabelSize size) {
  switch (size) {
    case LabelSize.small:
      return FontScheme.caption1Regular;
    case LabelSize.medium:
      return FontScheme.body2Regular;
    case LabelSize.large:
      return FontScheme.body1Regular;
  }
}

TextStyle _getItemFont(LabelSize size) {
  switch (size) {
    case LabelSize.small:
      return FontScheme.caption1Regular;
    case LabelSize.medium:
      return FontScheme.body2Regular;
    case LabelSize.large:
      return FontScheme.body1Regular;
  }
}

TextStyle _getDangerFont(LabelSize size) {
  switch (size) {
    case LabelSize.small:
      return FontScheme.caption1Regular;
    case LabelSize.medium:
      return FontScheme.body2Regular;
    case LabelSize.large:
      return FontScheme.body1Regular;
  }
}

// MARK: - Color Functions

Color _getTitleColor(SemanticColorScheme scheme) {
  return scheme.textColorPrimary;
}

Color _getSubTitleColor(SemanticColorScheme scheme) {
  return scheme.textColorSecondary;
}

Color _getItemColor(SemanticColorScheme scheme) {
  return scheme.textColorPrimary;
}

Color _getDangerColor(SemanticColorScheme scheme) {
  return scheme.textColorError;
}

// MARK: - Base Label

class _Label extends StatelessWidget {
  final String text;
  final LabelSize size;
  final LabelStyleConfig config;

  const _Label({
    required this.text,
    required this.size,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = BaseThemeProvider.colorsOf(context);

    return Text(
      text,
      style: config.fontStyle(size).copyWith(
            color: config.color(colorScheme),
          ),
      maxLines: config.lineLimit,
      overflow: TextOverflow.ellipsis,
    );
  }
}
