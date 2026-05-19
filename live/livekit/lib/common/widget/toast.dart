import 'package:flutter/cupertino.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/toast.dart';

void makeToast(BuildContext context, String message, {ToastType? type, bool useRootOverlay = false}) {
  if (type == null) {
    Toast.simple(context, message, useRootOverlay: useRootOverlay);
  } else {
    Toast.show(context, message, type: type, useRootOverlay: useRootOverlay);
  }
}
