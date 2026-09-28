// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   BaseBeautyStoreImpl @ AtomicXCore
// Function: BaseBeautyStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/device/base_beauty_store.dart';
import '../../engine/engine_bridge.dart';

class _BaseBeautyStateImpl implements BaseBeautyState {
  @override
  final ValueNotifier<double> smoothLevel = ValueNotifier<double>(0);

  @override
  final ValueNotifier<double> whitenessLevel = ValueNotifier<double>(0);

  @override
  final ValueNotifier<double> ruddyLevel = ValueNotifier<double>(0);
}

// API keys
const String _kSetSmoothLevel = 'BaseBeautyModule.setSmoothLevel';
const String _kSetWhitenessLevel = 'BaseBeautyModule.setWhitenessLevel';
const String _kSetRuddyLevel = 'BaseBeautyModule.setRuddyLevel';
const String _kReset = 'BaseBeautyModule.reset';

// Passive State channel (engine → Dart)
const String _stateChannel = 'BaseBeautyModule.stateChanged';

class BaseBeautyStoreImpl extends BaseBeautyStore {
  BaseBeautyStoreImpl._() {
    _subscribePassiveChannels();
  }

  static final BaseBeautyStoreImpl shared = BaseBeautyStoreImpl._();

  final _BaseBeautyStateImpl _state = _BaseBeautyStateImpl();

  @override
  BaseBeautyState get baseBeautyState => _state;

  @override
  void setSmoothLevel(double smoothLevel) {
    final param = jsonEncode(<String, Object>{'smoothLevel': smoothLevel});
    unawaited(EngineBridge.invoke(_kSetSmoothLevel, param));
  }

  @override
  void setWhitenessLevel(double whitenessLevel) {
    final param = jsonEncode(<String, Object>{'whitenessLevel': whitenessLevel});
    unawaited(EngineBridge.invoke(_kSetWhitenessLevel, param));
  }

  @override
  void setRuddyLevel(double ruddyLevel) {
    final param = jsonEncode(<String, Object>{'ruddyLevel': ruddyLevel});
    unawaited(EngineBridge.invoke(_kSetRuddyLevel, param));
  }

  @override
  void reset() {
    unawaited(EngineBridge.invoke(_kReset, '{}'));
  }

  void _subscribePassiveChannels() {
    EngineBridge.subscribe(_stateChannel, _onModuleStateChanged);
  }

  void _onModuleStateChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final property = dict['property'] as String?;
    if (property == null) return;

    switch (property) {
      case 'smoothLevel':
        final value = dict['smoothLevel'];
        if (value is! num) return;
        _state.smoothLevel.value = value.toDouble();
        break;
      case 'whitenessLevel':
        final value = dict['whitenessLevel'];
        if (value is! num) return;
        _state.whitenessLevel.value = value.toDouble();
        break;
      case 'ruddyLevel':
        final value = dict['ruddyLevel'];
        if (value is! num) return;
        _state.ruddyLevel.value = value.toDouble();
        break;
    }
  }

  static Map<String, dynamic>? _parseJSON(String json) {
    if (json.isEmpty) return null;
    try {
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      return null;
    }
    return null;
  }
}
