import 'package:flutter/material.dart';
import 'package:tencent_calls_uikit/src/bridge/bootloader/bootloader.dart';

class Global {
  static BuildContext appContext() {
    return Bootloader.instance.navigator!.context;
  }
}
