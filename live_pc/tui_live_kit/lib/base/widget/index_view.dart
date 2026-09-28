import 'package:flutter/widgets.dart';

/// 占位组件：基础通用控件模块入口，后续承载跨组件复用控件。
class BaseWidgetView extends StatelessWidget {
  const BaseWidgetView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('BaseWidgetView');
  }
}
