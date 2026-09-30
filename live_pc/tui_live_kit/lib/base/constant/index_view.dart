import 'package:flutter/widgets.dart';

/// 占位组件：基础常量模块入口，后续承载跨组件共享常量。
class BaseConstantView extends StatelessWidget {
  const BaseConstantView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('BaseConstantView');
  }
}
