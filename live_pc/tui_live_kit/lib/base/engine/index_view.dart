import 'package:flutter/widgets.dart';

/// 占位组件：基础引擎模块入口，后续承载 AtomicXCore 引擎封装。
class BaseEngineView extends StatelessWidget {
  const BaseEngineView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('BaseEngineView');
  }
}
