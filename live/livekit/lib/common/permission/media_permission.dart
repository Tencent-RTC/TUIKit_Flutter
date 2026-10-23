import 'package:tuikit_atomic_x/permission/permission.dart';

extension PermissionStatusEx on PermissionStatus {
  bool get isUsable => this == PermissionStatus.granted || this == PermissionStatus.limited;
}