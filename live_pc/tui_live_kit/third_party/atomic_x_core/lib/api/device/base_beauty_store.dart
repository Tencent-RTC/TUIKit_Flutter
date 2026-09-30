// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   BaseBeautyStore @ AtomicXCore
// Function: Basic beauty related interfaces, managing the adjustment and state synchronization of smooth, whiteness, ruddy and other basic beauty effects.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
// <docgen-keep-end>

/// Basic beauty state, managing the level data of smooth, whiteness, ruddy and other beauty effects. Supports subscription to synchronize UI display with actual effects.
///
/// A comprehensive snapshot of the current beauty session state. This structure contains all relevant information about smooth, whiteness, ruddy and other beauty effect levels.
///
/// > **Note**: The state is updated automatically when beauty setting methods are called. Subscribe to [baseBeautyState] to receive real-time updates.
/// ### Usage Example
///
/// ```dart
/// // Define listeners
/// late final VoidCallback smoothLevelListener = _onSmoothLevelChanged;
/// late final VoidCallback whitenessLevelListener = _onWhitenessLevelChanged;
/// late final VoidCallback ruddyLevelListener = _onRuddyLevelChanged;
///
/// void _onSmoothLevelChanged() {
///     smoothSlider.value = store.baseBeautyState.smoothLevel.value;
/// }
///
/// void _onWhitenessLevelChanged() {
///     whitenessSlider.value = store.baseBeautyState.whitenessLevel.value;
/// }
///
/// void _onRuddyLevelChanged() {
///     ruddySlider.value = store.baseBeautyState.ruddyLevel.value;
/// }
///
/// // Subscribe to state changes
/// store.baseBeautyState.smoothLevel.addListener(smoothLevelListener);
/// store.baseBeautyState.whitenessLevel.addListener(whitenessLevelListener);
/// store.baseBeautyState.ruddyLevel.addListener(ruddyLevelListener);
///
/// // Unsubscribe when done
/// store.baseBeautyState.smoothLevel.removeListener(smoothLevelListener);
/// store.baseBeautyState.whitenessLevel.removeListener(whitenessLevelListener);
/// store.baseBeautyState.ruddyLevel.removeListener(ruddyLevelListener);
/// ```
///
/// ### State Property Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [smoothLevel] | `ValueListenable<double>` | Smooth level, with a value range from 0 to 9 |
/// | [whitenessLevel] | `ValueListenable<double>` | Whiteness level, with a value range from 0 to 9 |
/// | [ruddyLevel] | `ValueListenable<double>` | Ruddy level, with a value range from 0 to 9 |
abstract class BaseBeautyState {
  /// Smooth level, with a value range from 0 to 9; 0 means off, 9 means most obvious effect.
  ValueListenable<double> get smoothLevel;

  /// Whiteness level, with a value range from 0 to 9; 0 means off, 9 means most obvious effect.
  ValueListenable<double> get whitenessLevel;

  /// Ruddy level, with a value range from 0 to 9; 0 means off, 9 means most obvious effect.
  ValueListenable<double> get ruddyLevel;
}

/// Basic beauty related interfaces, managing the adjustment and state synchronization of smooth, whiteness, ruddy and other basic beauty effects.
///
/// `BaseBeautyStore` `BaseBeautyStore` manages the adjustment and state synchronization of smooth, whiteness, ruddy and other basic beauty effects.
/// Basic beauty functionality achieves real-time beauty effect adjustment through easy-to-use APIs. `BaseBeautyStore` provides a complete set of interfaces to manage beauty effect settings and state subscriptions.
///
/// ### Key Features
///
/// - **Smooth Effect**：Supports 0-9 level smooth effect adjustment.
/// - **Whiteness Effect**：Supports 0-9 level whiteness effect adjustment.
/// - **Ruddy Effect**：Supports 0-9 level ruddy effect adjustment.
/// - **State Subscription**：Real-time subscription to beauty state changes, synchronizing UI display with actual effects.
///
/// > **Note**: Beauty state updates are delivered through the [baseBeautyState] publisher. Subscribe to it to receive real-time updates about beauty effect levels.
///
/// ### Usage Example
///
/// ```dart
/// // Get singleton instance
/// final store = BaseBeautyStore.shared;
///
/// // Define listeners
/// late final VoidCallback smoothLevelListener = _onSmoothLevelChanged;
/// late final VoidCallback whitenessLevelListener = _onWhitenessLevelChanged;
/// late final VoidCallback ruddyLevelListener = _onRuddyLevelChanged;
///
/// void _onSmoothLevelChanged() {
///     print('Smooth level: ${store.baseBeautyState.smoothLevel.value}');
/// }
///
/// void _onWhitenessLevelChanged() {
///     print('Whiteness level: ${store.baseBeautyState.whitenessLevel.value}');
/// }
///
/// void _onRuddyLevelChanged() {
///     print('Ruddy level: ${store.baseBeautyState.ruddyLevel.value}');
/// }
///
/// // Subscribe to state changes
/// store.baseBeautyState.smoothLevel.addListener(smoothLevelListener);
/// store.baseBeautyState.whitenessLevel.addListener(whitenessLevelListener);
/// store.baseBeautyState.ruddyLevel.addListener(ruddyLevelListener);
///
/// // Set beauty effects
/// store.setSmoothLevel(5.0);
/// store.setWhitenessLevel(3.0);
/// store.setRuddyLevel(2.0);
///
/// // Reset all beauty effects
/// store.reset();
///
/// // Unsubscribe when done
/// store.baseBeautyState.smoothLevel.removeListener(smoothLevelListener);
/// store.baseBeautyState.whitenessLevel.removeListener(whitenessLevelListener);
/// store.baseBeautyState.ruddyLevel.removeListener(ruddyLevelListener);
/// ```
///
/// ## Topics
///
/// ### Getting Instance
/// - [shared] : Get singleton instance.
///
/// ### Observing State
/// - [baseBeautyState] : Beauty state data.
///
/// ### Beauty Adjustment
/// - [setSmoothLevel] : Set smooth level.
/// - [setWhitenessLevel] : Set whiteness level.
/// - [setRuddyLevel] : Set ruddy level.
/// - [reset] : Reset to default state.
///
/// ## See Also
///
/// - [BaseBeautyState]
abstract class BaseBeautyStore {
  /// Singleton object.
  static BaseBeautyStore get shared => StoreFactory.shared.getStore<BaseBeautyStore>();

  /// Beauty state subscription, including smooth, whiteness, ruddy and other beauty effect levels. By subscribing to this state, you can get real-time updates of beauty data.
  BaseBeautyState get baseBeautyState;

  /// Set smooth level
  ///
  /// - [smoothLevel] : Smooth level, with a value range from 0 to 9; 0 means off, 9 means most obvious effect.
  void setSmoothLevel(double smoothLevel);

  /// Set whiteness level
  ///
  /// - [whitenessLevel] : Whiteness level, with a value range from 0 to 9; 0 means off, 9 means most obvious effect.
  void setWhitenessLevel(double whitenessLevel);

  /// Set ruddy level
  ///
  /// - [ruddyLevel] : Ruddy level, with a value range from 0 to 9; 0 means off, 9 means most obvious effect.
  void setRuddyLevel(double ruddyLevel);

  /// Reset all beauty parameters (smooth, whiteness, ruddy) to default off state (value 0).
  void reset();
}
