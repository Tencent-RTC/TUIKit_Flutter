abstract class TUIObserver {
  void onNotify(String event, String? key, NotifyParams? params);
}

class PublishParams {
  bool isSticky;
  Map<String, dynamic>? data;
  void Function(Map<String, dynamic>)? callback;

  PublishParams({
    this.isSticky = false,
    this.data,
    this.callback,
  });
}

class NotifyParams {
  Map<String, dynamic>? data;
  void Function(Map<String, dynamic>)? callback;

  NotifyParams({
    this.data,
    this.callback,
  });
}

class TUIEventBus {
  TUIEventBus._internal();

  factory TUIEventBus() => _instance;
  static final TUIEventBus _instance = TUIEventBus._internal();

  static TUIEventBus get shared => _instance;

  Map<String, List<TUIObserver>> observerMap = {};
  Map<String, Map<String, dynamic>> stickyDataMap = {};

  void subscribe(String event, String? key, TUIObserver observer) {
    String eventKey = _buildEventKey(event, key);
    observerMap[eventKey] ??= [];
    observerMap[eventKey]!.add(observer);

    Map<String, dynamic>? data = stickyDataMap[eventKey];
    if (data != null) {
      observer.onNotify(event, key, NotifyParams(data: data));
    }
  }

  void unsubscribe(String event, String? key, TUIObserver observer) {
    String eventKey = _buildEventKey(event, key);
    List<TUIObserver>? observers = observerMap[eventKey];
    if (observers != null) {
      observers.remove(observer);
      if (observers.isEmpty) {
        observerMap.remove(eventKey);
      }
    }
  }

  void publish(String event, String? key, PublishParams? params) {
    String eventKey = _buildEventKey(event, key);

    if (params != null && params.isSticky == true && params.data != null) {
      stickyDataMap[eventKey] = params.data!;
    }

    List<TUIObserver>? observers = observerMap[eventKey];
    if (observers != null) {
      NotifyParams? notifyParams;
      if (params != null && (params.data != null || params.callback != null)) {
        notifyParams = NotifyParams(data: params.data, callback: params.callback);
      }

      for (final observer in observers) {
        observer.onNotify(event, key, notifyParams);
      }
    }
  }

  String _buildEventKey(String event, String? key) {
    return key == null ? event : '$event:$key';
  }
}
