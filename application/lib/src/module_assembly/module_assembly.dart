import 'package:atomic_x_core/atomicxcore.dart';

class ModuleAssembly {
  static bool canStartNewRoom() {
    return CallStore.shared.state.selfInfo.value.status == CallParticipantStatus.none;
  }
}