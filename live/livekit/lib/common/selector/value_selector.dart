import 'package:flutter/foundation.dart';

class ValueSelector<T, R> extends ValueNotifier<R> {
  final ValueListenable<T> _source;
  final R Function(T) _selector;
  late final VoidCallback _listener;

  ValueSelector(this._source, this._selector) : super(_selector(_source.value)) {
    _listener = () {
      final newValue = _selector(_source.value);
      if (value != newValue) {
        value = newValue;
      }
    };
    _source.addListener(_listener);
  }

  @override
  void dispose() {
    _source.removeListener(_listener);
    super.dispose();
  }
}
