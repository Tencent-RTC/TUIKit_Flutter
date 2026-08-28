import 'package:flutter/widgets.dart';

/// Builds the in-room group chat page for the given [roomId].
///
/// Provided by the host App layer (which depends on the chat UIKit) so that the
/// room package does not need a direct dependency on the chat package.
/// When it is null, the in-room chat entry is hidden.
typedef RoomChatPageBuilder = Widget Function(String roomId);
