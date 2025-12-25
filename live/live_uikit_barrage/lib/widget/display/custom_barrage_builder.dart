import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';


abstract class CustomBarrageBuilder {
  bool shouldCustomizeBarrageItem(Barrage barrage);

  Widget buildWidget(BuildContext context, Barrage barrage);
}
