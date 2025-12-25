import 'dart:async';

typedef ToastCallback = void Function(String message);

abstract class ToastService {
  void showToast(String message);

  void subscribeToast(ToastCallback callback);

  void unsubscribeToast();
}

class ToastServiceImpl implements ToastService {
  final StreamController<String> _toastSubject = StreamController.broadcast();
  StreamSubscription<String>? _toastSubscription;
  @override
  void showToast(String message) {
    _toastSubject.add(message);
  }

  @override
  void subscribeToast(ToastCallback callback) {
    _toastSubscription = _toastSubject.stream.listen((toast)=>callback.call(toast));
  }

  @override
  void unsubscribeToast() {
    _toastSubscription?.cancel();
  }
}