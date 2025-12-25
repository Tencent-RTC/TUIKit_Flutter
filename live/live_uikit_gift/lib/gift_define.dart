import 'package:atomic_x_core/atomicxcore.dart';

typedef OnReceiveGiftCallback = void Function(
    Gift gift, int count, LiveUserInfo sender);

typedef OnSendGiftCallback = void Function(Gift gift, int count);
