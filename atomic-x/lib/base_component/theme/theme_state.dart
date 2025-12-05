import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_builder.dart';
import '../utils/storage_util.dart';
import 'color_scheme.dart';
import 'font.dart';
import 'radius.dart';
import 'spacing.dart';

enum ThemeType {
  system,
  light,
  dark,
}

class ThemeConfig {
  late ThemeType type;
  String? primaryColor;

  ThemeConfig({
    required this.type,
    this.primaryColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeConfig && other.primaryColor == primaryColor;
  }

  @override
  int get hashCode => primaryColor.hashCode;
}

class ThemeState extends ChangeNotifier {
  final String themeKey = 'BaseComponentThemeKey';
  ThemeConfig _currentTheme = ThemeConfig(type: ThemeType.system);

  ThemeType get currentType => _currentTheme.type;

  String? get currentPrimaryColor => _currentTheme.primaryColor;

  SemanticColorScheme? _cachedColorScheme;
  ThemeConfig? _cachedThemeConfig;

  ThemeState() {
    _loadThemeFromLocal();
  }

  void setThemeMode(ThemeType type) {
    _clearCache();
    _currentTheme = ThemeConfig(type: type, primaryColor: _currentTheme.primaryColor);
    saveTheme();
    notifyListeners();
  }

  void setPrimaryColor(String hexColor) {
    _clearCache();

    final RegExp hexRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (hexRegex.hasMatch(hexColor)) {
      _currentTheme = ThemeConfig(
        type: _currentTheme.type,
        primaryColor: hexColor,
      );
    } else {
      debugPrint('Warning: Invalid hex color format: $hexColor, using default color');
    }

    saveTheme();
    notifyListeners();
  }

  void clearPrimaryColor() {
    _clearCache();
    _currentTheme = ThemeConfig(type: _currentTheme.type, primaryColor: null);
    saveTheme();
  }

  Future<void> saveTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final themeJson = {
        'mode': _currentTheme.type.index,
        'primaryColor': _currentTheme.primaryColor,
      };
      await prefs.setString(themeKey, jsonEncode(themeJson));
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }

  void _loadThemeFromLocal() {
    try {
      final themeString = StorageUtil.get(themeKey) as String?;
      if (themeString != null) {
        final themeJson = jsonDecode(themeString) as Map<String, dynamic>;
        final modeIndex = themeJson['mode'] as int;
        final primaryColor = themeJson['primaryColor'] as String?;

        _currentTheme = ThemeConfig(
          type: ThemeType.values[modeIndex],
          primaryColor: primaryColor,
        );
        return;
      }
    } catch (e) {
      debugPrint('Failed to load theme from local storage: $e');
    }

    _loadThemeFromAppBuilder();
  }

  void _loadThemeFromAppBuilder() {
    try {
      final appBuilder = AppBuilder.getInstance();
      final atomicThemeConfig = appBuilder.themeConfig;

      switch (atomicThemeConfig.mode) {
        case AppBuilder.THEME_MODE_LIGHT:
          _currentTheme.type = ThemeType.light;
          break;
        case AppBuilder.THEME_MODE_DARK:
          _currentTheme.type = ThemeType.dark;
          break;
        default:
          _currentTheme.type = ThemeType.system;
      }

      if (atomicThemeConfig.primaryColor != null && atomicThemeConfig.primaryColor!.isNotEmpty) {
        setPrimaryColor(atomicThemeConfig.primaryColor!);
      }
    } catch (e) {
      debugPrint('Failed to load theme from AppBuilder: $e');
    }
  }

  ThemeConfig get currentTheme {
    return _currentTheme;
  }

  bool get isDarkMode {
    return _currentTheme.type == ThemeType.dark || (_currentTheme.type == ThemeType.system && _isSystemDarkMode);
  }

  bool get _isSystemDarkMode {
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  bool get hasCustomPrimaryColor {
    return _currentTheme.primaryColor != null;
  }

  SemanticColorScheme get colors {
    if (_cachedColorScheme != null && _cachedThemeConfig != null && _cachedThemeConfig == _currentTheme) {
      return _cachedColorScheme!;
    }

    final newColorScheme = _calculateColorScheme();
    _cachedColorScheme = newColorScheme;
    _cachedThemeConfig = _currentTheme;

    return newColorScheme;
  }

  SemanticFontScheme get fonts => FontScheme;

  SemanticRadiusScheme get radius => RadiusScheme;

  SemanticSpacingScheme get spacing => SpacingScheme;

  SemanticColorScheme _calculateColorScheme() {
    ThemeType effectiveMode;

    switch (_currentTheme.type) {
      case ThemeType.system:
        effectiveMode = _isSystemDarkMode ? ThemeType.dark : ThemeType.light;
      case ThemeType.light:
      case ThemeType.dark:
        effectiveMode = _currentTheme.type;
    }

    if (_currentTheme.primaryColor != null) {
      return _getCustomScheme(
        isLight: effectiveMode == ThemeType.light,
        baseScheme: effectiveMode == ThemeType.light ? LightSemanticScheme : DarkSemanticScheme,
        primaryColor: _currentTheme.primaryColor!,
      );
    }

    switch (effectiveMode) {
      case ThemeType.light:
        return LightSemanticScheme;
      case ThemeType.dark:
        return DarkSemanticScheme;
      case ThemeType.system:
        return _getSystemScheme();
    }
  }

  void _clearCache() {
    _cachedColorScheme = null;
    _cachedThemeConfig = null;
  }

  SemanticColorScheme _getSystemScheme() {
    return _isSystemDarkMode ? DarkSemanticScheme : LightSemanticScheme;
  }

  SemanticColorScheme _getCustomScheme({
    required bool isLight,
    required SemanticColorScheme baseScheme,
    required String primaryColor,
  }) {
    final hexColor = primaryColor;
    final lightPalette = ThemeColorGenerator.generateColorPalette(hexColor, theme: "light");
    final darkPalette = ThemeColorGenerator.generateColorPalette(hexColor, theme: "dark");

    final themeLight1 = ThemeColorGenerator.hexToColor(lightPalette[0]);
    final themeLight2 = ThemeColorGenerator.hexToColor(lightPalette[1]);
    final themeLight5 = ThemeColorGenerator.hexToColor(lightPalette[4]);
    final themeLight6 = ThemeColorGenerator.hexToColor(lightPalette[5]);
    final themeLight7 = ThemeColorGenerator.hexToColor(lightPalette[6]);
    final themeDark2 = ThemeColorGenerator.hexToColor(darkPalette[1]);
    final themeDark5 = ThemeColorGenerator.hexToColor(darkPalette[4]);
    final themeDark6 = ThemeColorGenerator.hexToColor(darkPalette[5]);
    final themeDark7 = ThemeColorGenerator.hexToColor(darkPalette[6]);

    return SemanticColorScheme(
      // text & icon
      textColorPrimary: baseScheme.textColorPrimary,
      textColorSecondary: baseScheme.textColorSecondary,
      textColorTertiary: baseScheme.textColorTertiary,
      textColorDisable: baseScheme.textColorDisable,
      textColorButton: baseScheme.textColorButton,
      textColorButtonDisabled: baseScheme.textColorButtonDisabled,
      textColorLink: isLight ? themeLight6 : themeDark6,
      textColorLinkHover: isLight ? themeLight5 : themeDark5,
      textColorLinkActive: isLight ? themeLight7 : themeDark7,
      textColorLinkDisabled: isLight ? themeLight2 : themeDark2,
      textColorAntiPrimary: baseScheme.textColorAntiPrimary,
      textColorAntiSecondary: baseScheme.textColorAntiSecondary,
      textColorWarning: baseScheme.textColorWarning,
      textColorSuccess: baseScheme.textColorSuccess,
      textColorError: baseScheme.textColorError,

      // background
      bgColorTopBar: baseScheme.bgColorTopBar,
      bgColorOperate: baseScheme.bgColorOperate,
      bgColorDialog: baseScheme.bgColorDialog,
      bgColorDialogModule: baseScheme.bgColorDialogModule,
      bgColorEntryCard: baseScheme.bgColorEntryCard,
      bgColorFunction: baseScheme.bgColorFunction,
      bgColorBottomBar: baseScheme.bgColorBottomBar,
      bgColorInput: baseScheme.bgColorInput,
      bgColorBubbleReciprocal: baseScheme.bgColorBubbleReciprocal,
      bgColorBubbleOwn: isLight ? themeLight2 : themeDark7,
      bgColorDefault: baseScheme.bgColorDefault,
      bgColorTagMask: baseScheme.bgColorTagMask,
      bgColorElementMask: baseScheme.bgColorElementMask,
      bgColorMask: baseScheme.bgColorMask,
      bgColorMaskDisappeared: baseScheme.bgColorMaskDisappeared,
      bgColorMaskBegin: baseScheme.bgColorMaskBegin,
      bgColorAvatar: isLight ? themeLight2 : themeDark2,

      // border
      strokeColorPrimary: baseScheme.strokeColorPrimary,
      strokeColorSecondary: baseScheme.strokeColorSecondary,
      strokeColorModule: baseScheme.strokeColorModule,

      // shadow
      shadowColor: baseScheme.shadowColor,

      // status
      listColorDefault: baseScheme.listColorDefault,
      listColorHover: baseScheme.listColorHover,
      listColorFocused: isLight ? themeLight1 : themeDark2,

      // button
      buttonColorPrimaryDefault: isLight ? themeLight6 : themeDark6,
      buttonColorPrimaryHover: isLight ? themeLight5 : themeDark5,
      buttonColorPrimaryActive: isLight ? themeLight7 : themeDark7,
      buttonColorPrimaryDisabled: isLight ? themeLight2 : themeDark2,
      buttonColorSecondaryDefault: baseScheme.buttonColorSecondaryDefault,
      buttonColorSecondaryHover: baseScheme.buttonColorSecondaryHover,
      buttonColorSecondaryActive: baseScheme.buttonColorSecondaryActive,
      buttonColorSecondaryDisabled: baseScheme.buttonColorSecondaryDisabled,
      buttonColorAccept: baseScheme.buttonColorAccept,
      buttonColorHangupDefault: baseScheme.buttonColorHangupDefault,
      buttonColorHangupDisabled: baseScheme.buttonColorHangupDisabled,
      buttonColorHangupHover: baseScheme.buttonColorHangupHover,
      buttonColorHangupActive: baseScheme.buttonColorHangupActive,
      buttonColorOn: baseScheme.buttonColorOn,
      buttonColorOff: baseScheme.buttonColorOff,

      // dropdown
      dropdownColorDefault: baseScheme.dropdownColorDefault,
      dropdownColorHover: baseScheme.dropdownColorHover,
      dropdownColorActive: isLight ? themeLight1 : themeDark2,

      // scrollbar
      scrollbarColorDefault: baseScheme.scrollbarColorDefault,
      scrollbarColorHover: baseScheme.scrollbarColorHover,

      // floating
      floatingColorDefault: baseScheme.floatingColorDefault,
      floatingColorOperate: baseScheme.floatingColorOperate,

      // checkbox
      checkboxColorSelected: isLight ? themeLight6 : themeDark5,

      // toast
      toastColorWarning: baseScheme.toastColorWarning,
      toastColorSuccess: baseScheme.toastColorSuccess,
      toastColorError: baseScheme.toastColorError,
      toastColorDefault: isLight ? themeLight1 : themeDark2,

      // tag
      tagColorLevel1: baseScheme.tagColorLevel1,
      tagColorLevel2: baseScheme.tagColorLevel2,
      tagColorLevel3: baseScheme.tagColorLevel3,
      tagColorLevel4: baseScheme.tagColorLevel4,

      // switch
      switchColorOff: baseScheme.switchColorOff,
      switchColorOn: isLight ? themeLight6 : themeDark5,
      switchColorButton: baseScheme.switchColorButton,

      // slider
      sliderColorFilled: isLight ? themeLight6 : themeDark5,
      sliderColorEmpty: baseScheme.sliderColorEmpty,
      sliderColorButton: baseScheme.sliderColorButton,

      // tab
      tabColorSelected: isLight ? themeLight2 : themeDark5,
      tabColorUnselected: baseScheme.tabColorUnselected,
      tabColorOption: baseScheme.tabColorOption,

      // clear
      clearColor: baseScheme.clearColor,
    );
  }
}

class ThemeColorGenerator {
  static List<String> generateColorPalette(String baseColor, {String theme = "light"}) {
    if (_isStandardColor(baseColor)) {
      final palette = _getClosestPalette(baseColor);
      final targetColors = palette[theme] ?? palette["light"]!;
      return targetColors;
    }
    return _generateDynamicColorVariations(baseColor: baseColor, theme: theme);
  }

  static Color hexToColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    final rgb = int.parse(hexColor, radix: 16);

    final r = ((rgb >> 16) & 0xFF) / 255.0;
    final g = ((rgb >> 8) & 0xFF) / 255.0;
    final b = (rgb & 0xFF) / 255.0;

    return Color.fromRGBO((r * 255).round(), (g * 255).round(), (b * 255).round(), 1.0);
  }

  static String colorToHex(Color color) {
    final red = (color.red * 255).round();
    final green = (color.green * 255).round();
    final blue = (color.blue * 255).round();

    return '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  static const Map<String, List<String>> _bluePalette = {
    "light": [
      "#ebf3ff",
      "#cce2ff",
      "#adcfff",
      "#7aafff",
      "#4588f5",
      "#1c66e5",
      "#0d49bf",
      "#033099",
      "#001f73",
      "#00124d"
    ],
    "dark": [
      "#1c2333",
      "#243047",
      "#2f4875",
      "#305ba6",
      "#2b6ad6",
      "#4086ff",
      "#5c9dff",
      "#78b0ff",
      "#9cc7ff",
      "#c2deff"
    ]
  };

  static const Map<String, List<String>> _greenPalette = {
    "light": [
      "#dcfae9",
      "#b6f0d1",
      "#84e3b5",
      "#5ad69e",
      "#3cc98c",
      "#0abf77",
      "#09a768",
      "#078f59",
      "#067049",
      "#044d37"
    ],
    "dark": [
      "#1a2620",
      "#22352c",
      "#2f4f3f",
      "#377355",
      "#368f65",
      "#38a673",
      "#62b58b",
      "#8bc7a9",
      "#a9d4bd",
      "#c8e5d5"
    ]
  };

  static const Map<String, List<String>> _redPalette = {
    "light": [
      "#ffe7e6",
      "#fcc9c7",
      "#faaeac",
      "#f58989",
      "#e86666",
      "#e54545",
      "#c93439",
      "#ad2934",
      "#8f222d",
      "#6b1a27"
    ],
    "dark": [
      "#2b1c1f",
      "#422324",
      "#613234",
      "#8a4242",
      "#c2544e",
      "#e6594c",
      "#e57a6e",
      "#f3a599",
      "#facbc3",
      "#fae4de"
    ]
  };

  static const Map<String, List<String>> _orangePalette = {
    "light": [
      "#ffeedb",
      "#ffd6b2",
      "#ffbe85",
      "#ffa455",
      "#ff8b2b",
      "#ff7200",
      "#e05d00",
      "#bf4900",
      "#8f370b",
      "#662200"
    ],
    "dark": [
      "#211a19",
      "#35231a",
      "#462e1f",
      "#653c21",
      "#96562a",
      "#e37f32",
      "#e39552",
      "#eead72",
      "#f7cfa4",
      "#f9e9d1"
    ]
  };

  static const Map<String, Map<int, Map<String, double>>> _hslAdjustments = {
    "light": {
      1: {"s": -40.0, "l": 45.0},
      2: {"s": -30.0, "l": 35.0},
      3: {"s": -20.0, "l": 25.0},
      4: {"s": -10.0, "l": 15.0},
      5: {"s": -5.0, "l": 5.0},
      6: {"s": 0.0, "l": 0.0},
      7: {"s": 5.0, "l": -10.0},
      8: {"s": 10.0, "l": -20.0},
      9: {"s": 15.0, "l": -30.0},
      10: {"s": 20.0, "l": -40.0}
    },
    "dark": {
      1: {"s": -60.0, "l": -35.0},
      2: {"s": -50.0, "l": -25.0},
      3: {"s": -40.0, "l": -15.0},
      4: {"s": -30.0, "l": -5.0},
      5: {"s": -20.0, "l": 5.0},
      6: {"s": 0.0, "l": 0.0},
      7: {"s": -10.0, "l": 15.0},
      8: {"s": -20.0, "l": 30.0},
      9: {"s": -30.0, "l": 45.0},
      10: {"s": -40.0, "l": 60.0}
    }
  };

  static Map<String, List<String>> _getClosestPalette(String color) {
    final hsl = _hexToHSL(color);

    double colorDistance(Map<String, double> c1, Map<String, double> c2) {
      final dh = math.min((c1["h"]! - c2["h"]!).abs(), 360 - (c1["h"]! - c2["h"]!).abs());
      final ds = c1["s"]! - c2["s"]!;
      final dl = c1["l"]! - c2["l"]!;
      return math.sqrt(dh * dh + ds * ds + dl * dl);
    }

    final palettes = [
      {"palette": _bluePalette, "baseColor": _bluePalette["light"]![5]},
      {"palette": _greenPalette, "baseColor": _greenPalette["light"]![5]},
      {"palette": _redPalette, "baseColor": _redPalette["light"]![5]},
      {"palette": _orangePalette, "baseColor": _orangePalette["light"]![5]}
    ];

    final distances = palettes.map((paletteInfo) {
      final baseColorHsl = _hexToHSL(paletteInfo["baseColor"] as String);
      return {
        "palette": paletteInfo["palette"] as Map<String, List<String>>,
        "distance": colorDistance(hsl, baseColorHsl)
      };
    }).toList();

    distances.sort((a, b) => (a["distance"] as double).compareTo(b["distance"] as double));
    return distances[0]["palette"] as Map<String, List<String>>;
  }

  static bool _isStandardColor(String color) {
    final standardColors = [
      _bluePalette["light"]![5],
      _greenPalette["light"]![5],
      _redPalette["light"]![5],
      _orangePalette["light"]![5]
    ];

    final inputHsl = _hexToHSL(color);
    return standardColors.any((standardColor) {
      final standardHsl = _hexToHSL(standardColor);
      final dh = math.min((inputHsl["h"]! - standardHsl["h"]!).abs(), 360 - (inputHsl["h"]! - standardHsl["h"]!).abs());
      return dh < 15 &&
          (inputHsl["s"]! - standardHsl["s"]!).abs() < 15 &&
          (inputHsl["l"]! - standardHsl["l"]!).abs() < 15;
    });
  }

  static String _adjustColor(String color, Map<String, double> adjustment) {
    final hsl = _hexToHSL(color);
    final newS = math.max(0.0, math.min(100.0, hsl["s"]! + adjustment["s"]!));
    final newL = math.max(0.0, math.min(100.0, hsl["l"]! + adjustment["l"]!));
    return _hslToHex({"h": hsl["h"]!, "s": newS, "l": newL});
  }

  static List<String> _generateDynamicColorVariations({required String baseColor, required String theme}) {
    final variations = <String>[];
    final adjustments = _hslAdjustments[theme] ?? _hslAdjustments["light"]!;
    final baseHsl = _hexToHSL(baseColor);
    final saturationFactor = baseHsl["s"]! > 70
        ? 0.8
        : baseHsl["s"]! < 30
            ? 1.2
            : 1.0;
    final lightnessFactor = baseHsl["l"]! > 70
        ? 0.8
        : baseHsl["l"]! < 30
            ? 1.2
            : 1.0;

    for (int i = 1; i <= 10; i++) {
      final adjustment = adjustments[i] ?? {"s": 0.0, "l": 0.0};
      final adjustedS = adjustment["s"]! * saturationFactor;
      final adjustedL = adjustment["l"]! * lightnessFactor;
      variations.add(_adjustColor(baseColor, {"s": adjustedS, "l": adjustedL}));
    }

    return variations;
  }

  static Map<String, double> _hexToHSL(String hex) {
    final hexColor = hex.replaceAll('#', '');
    final rgb = int.parse(hexColor, radix: 16);

    final r = ((rgb >> 16) & 0xFF) / 255.0;
    final g = ((rgb >> 8) & 0xFF) / 255.0;
    final b = (rgb & 0xFF) / 255.0;

    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    double h = 0;
    double s = 0;
    final l = (max + min) / 2.0;

    if (max != min) {
      final d = max - min;
      s = l > 0.5 ? d / (2.0 - max - min) : d / (max + min);

      if (max == r) {
        h = (g - b) / d + (g < b ? 6.0 : 0.0);
      } else if (max == g) {
        h = (b - r) / d + 2.0;
      } else if (max == b) {
        h = (r - g) / d + 4.0;
      }
      h /= 6.0;
    }

    return {"h": h * 360.0, "s": s * 100.0, "l": l * 100.0};
  }

  static String _hslToHex(Map<String, double> hsl) {
    final h = hsl["h"]! / 360.0;
    final s = hsl["s"]! / 100.0;
    final l = hsl["l"]! / 100.0;

    final c = (1.0 - (2.0 * l - 1.0).abs()) * s;
    final x = c * (1.0 - ((h * 6.0) % 2.0 - 1.0).abs());
    final m = l - c / 2.0;

    double r = 0, g = 0, b = 0;

    switch ((h * 6.0).floor()) {
      case 0:
        r = c;
        g = x;
        b = 0;
        break;
      case 1:
        r = x;
        g = c;
        b = 0;
        break;
      case 2:
        r = 0;
        g = c;
        b = x;
        break;
      case 3:
        r = 0;
        g = x;
        b = c;
        break;
      case 4:
        r = x;
        g = 0;
        b = c;
        break;
      case 5:
        r = c;
        g = 0;
        b = x;
        break;
    }

    final red = ((r + m) * 255.0).round();
    final green = ((g + m) * 255.0).round();
    final blue = ((b + m) * 255.0).round();

    return '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}

class BaseThemeProvider extends InheritedNotifier<ThemeState> {
  const BaseThemeProvider({
    super.key,
    required ThemeState themeState,
    required super.child,
  }) : super(notifier: themeState);

  static ThemeState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<BaseThemeProvider>();
    assert(provider != null, '在 BaseThemeProvider 的上下文中找不到 BaseThemeProvider');
    return provider!.notifier!;
  }

  static SemanticColorScheme colorsOf(BuildContext context) {
    return of(context).colors;
  }
}

class ComponentTheme extends StatelessWidget {
  final ThemeState themeState;

  final Widget child;

  ComponentTheme({
    super.key,
    ThemeState? themeState,
    required this.child,
  }) : themeState = themeState ?? ThemeState();

  @override
  Widget build(BuildContext context) {
    return BaseThemeProvider(
      themeState: themeState,
      child: child,
    );
  }
}
