import 'package:flutter/foundation.dart';

class ValueProbe<T> extends ValueNotifier<T> {
  ValueProbe(super.value);
  bool get isObserved => hasListeners;
}
