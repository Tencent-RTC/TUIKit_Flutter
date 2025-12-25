import 'package:flutter/foundation.dart';

import '../../common/widget/float_window/float_window_mode.dart';

class LSFloatWindowState {
  final ValueNotifier<bool> pipMode = ValueNotifier(false);
  final ValueListenable<FloatWindowMode> floatWindowMode = ValueNotifier(FloatWindowMode.none);
  final ValueListenable<bool> isFloatWindowMode = ValueNotifier(false);
  final ValueListenable<bool> enablePipMode = ValueNotifier(false);
}