import 'package:flutter/widgets.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';

/// LiveKit theme manager.
/// Switches theme when entering LiveKit scene and restores when exiting.
/// Also supports pausing theme in float window mode.
class LiveThemeManager {
  LiveThemeManager._();

  static final LiveThemeManager _instance = LiveThemeManager._();

  static LiveThemeManager get instance => _instance;

  ThemeState? _themeState;
  ThemeType? _previousThemeType;
  ThemeType _targetThemeType = ThemeType.dark;
  int _referenceCount = 0;
  bool _isPaused = false;

  /// Safely set theme mode, avoiding calls during build phase.
  void _safeSetThemeMode(ThemeState themeState, ThemeType themeType) {
    if (themeState.currentType == themeType) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (themeState.currentType != themeType) {
        themeState.setThemeMode(themeType);
      }
    });
  }

  /// Called when entering LiveKit scene.
  /// [context] is used to get ThemeState.
  /// [targetTheme] is the target theme, defaults to dark.
  void enterLiveKitScene(BuildContext context, {ThemeType targetTheme = ThemeType.dark}) {
    _referenceCount++;
    _targetThemeType = targetTheme;

    if (_referenceCount == 1) {
      _themeState = BaseThemeProvider.of(context);
      _previousThemeType = _themeState?.currentType;
      _isPaused = false;

      if (_themeState != null) {
        _safeSetThemeMode(_themeState!, targetTheme);
      }
    }
  }

  /// Called when exiting LiveKit scene.
  void exitLiveKitScene() {
    if (_referenceCount > 0) {
      _referenceCount--;
    }

    if (_referenceCount == 0 && _previousThemeType != null && _themeState != null) {
      final themeState = _themeState!;
      final previousType = _previousThemeType!;
      _reset();
      _safeSetThemeMode(themeState, previousType);
    }
  }

  /// Called when entering float window mode, temporarily restores the previous theme.
  void pauseTheme() {
    if (_isPaused || _themeState == null || _previousThemeType == null) {
      return;
    }
    _isPaused = true;
    _safeSetThemeMode(_themeState!, _previousThemeType!);
  }

  /// Called when returning from float window to fullscreen, restores LiveKit theme.
  void resumeTheme() {
    if (!_isPaused || _themeState == null) {
      return;
    }
    _isPaused = false;
    _safeSetThemeMode(_themeState!, _targetThemeType);
  }

  /// Force reset state (for exceptional cases).
  void forceReset() {
    if (_previousThemeType != null && _themeState != null) {
      _safeSetThemeMode(_themeState!, _previousThemeType!);
    }
    _reset();
  }

  void _reset() {
    _themeState = null;
    _previousThemeType = null;
    _referenceCount = 0;
    _isPaused = false;
  }

  /// Whether currently in LiveKit theme mode.
  bool get isInLiveKitScene => _referenceCount > 0;

  /// Whether the theme is paused (float window mode).
  bool get isPaused => _isPaused;

  /// Current reference count (for debugging).
  int get referenceCount => _referenceCount;
}
