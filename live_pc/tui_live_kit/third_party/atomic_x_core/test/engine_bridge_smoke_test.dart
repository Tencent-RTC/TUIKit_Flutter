// Copyright (c) 2026 Tencent. All rights reserved.
// Module:   atomic_engine smoke test
// Function: 桥接层纯 Dart 层冒烟测试，仅覆盖不依赖 native 动态库的逻辑。

import 'package:atomic_x_core/engine/engine_call_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EngineCallResult 成败判定', () {
    test('code == 0 视为成功', () {
      const result = EngineCallResult(code: 0, message: '', data: '{}');
      expect(result.isSuccess, isTrue);
    });

    test('code != 0 视为失败', () {
      const result = EngineCallResult(
        code: -3,
        message: 'engine handle is null',
        data: '',
      );
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('handle'));
    });

    test('toString 不会泄露 data 内容（只暴露长度）', () {
      const result = EngineCallResult(
        code: 0,
        message: '',
        data: '{"secret":"should_not_leak"}',
      );
      final str = result.toString();
      expect(str, isNot(contains('secret')));
      expect(str, contains('dataLen: ${result.data.length}'));
    });
  });
}
