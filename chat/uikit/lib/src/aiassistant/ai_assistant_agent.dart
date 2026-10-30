/// One AI assistant supplied by the host application.
///
/// [id] is the business ID; messages must go to [imUserId]. The title and the
/// picker use [imNickname]; [name] is the backend display name and may differ.
class AIAssistantAgent {
  const AIAssistantAgent({
    required this.id,
    required this.name,
    required this.welcome,
    required this.imUserId,
    required this.imNickname,
  });

  final String id;
  final String name;
  final String welcome;
  final String imUserId;
  final String imNickname;

  String get conversationID => 'c2c_$imUserId';

  String get displayName {
    if (imNickname.trim().isNotEmpty) return imNickname;
    if (name.trim().isNotEmpty) return name;
    return imUserId;
  }
}

/// Loads the latest assistant directory for [AIAssistantPage].
typedef AIAssistantAgentLoader = Future<List<AIAssistantAgent>> Function();

class AIAssistantHandoffStatus {
  const AIAssistantHandoffStatus({
    this.callable = false,
    this.state = '',
    this.seatImUserId = '',
  });

  static const String stateQueued = 'queued';
  static const String stateOffered = 'offered';
  static const String stateAssigned = 'assigned';
  static const String stateClosed = 'closed';
  static const AIAssistantHandoffStatus inactive = AIAssistantHandoffStatus();

  final bool callable;
  final String state;
  final String seatImUserId;

  bool get isSeatCallable => callable && seatImUserId.trim().isNotEmpty;

  bool get isWaitingForSeat {
    if (isSeatCallable) return false;
    return const {stateQueued, stateOffered, stateAssigned}.contains(state);
  }
}

typedef AIAssistantHandoffStatusLoader = Future<AIAssistantHandoffStatus>
    Function();
