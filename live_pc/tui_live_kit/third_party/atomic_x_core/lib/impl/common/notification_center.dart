import 'dart:async';

class NotificationCenter {
  static final NotificationCenter _instance = NotificationCenter._internal();

  factory NotificationCenter() => _instance;

  NotificationCenter._internal();

  final Map<String, StreamController<dynamic>> _controllers = {};

  StreamController<T> _getController<T>(String name) {
    if (!_controllers.containsKey(name)) {
      _controllers[name] = StreamController<T>.broadcast();
    }
    return _controllers[name] as StreamController<T>;
  }

  Stream<T> getStream<T>(String name) {
    return _getController<T>(name).stream;
  }

  void post<T>(String name, T data) {
    final controller = _getController<T>(name);
    controller.add(data);
  }

  StreamSubscription<T> addListener<T>(String name, void Function(T data) listener) {
    final stream = getStream<T>(name);
    return stream.listen(listener);
  }

  void clearStream(String name) {
    _controllers[name]?.close();
    _controllers.remove(name);
  }

  void clear() {
    for (var controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  void dispose() {
    clear();
  }
}

final notificationCenter = NotificationCenter();
