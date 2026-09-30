# AtomicXCore

## 5.0.2

- Chat: Fixed an issue where the isFriend and isInBlacklist fields returned by getContactInfo were incorrect.
- Chat: Fixed an issue where the selfRole field in GroupInfo still showed Member after exiting a group.
- Live: Added the iOSAppGroup parameter to the startScreenShare API.
- Live: Fixed a race condition where calling stop during ongoing preloading start could not cancel the operation.

## 5.0.1

- Chat：Renamed the loadConversationList and loadMoreConversationList APIs to loadConversations and loadMoreConversations respectively.

## 5.0.0

### Breaking changes

- Chat：Optimized the definitions of interfaces related to Contact, Conversation, Group, Message, and Search.
- Chat：Added support for message quoting functionality.

## 4.1.0

- Call: Added support for scaling the local video preview.
- Call: CallStore offline push now supports customizing the notification title and content.
- Live: Renamed the createLive API to startLive.
- Live: Added support for video layout templates 602 and 603 on Android, iOS, and Flutter.
- Live: Added support for landscape 1V1 and landscape 1V9 video layout templates.
- Live: Added enter/leave room awareness for all roles (anchor, audience, admin, etc.) in the live room.
- Live: Added support for video layout templates 602 and 603 in the anchor cross-room connection (PK) scenario.
- Live: Anchors can now mute the audio stream of the remote anchor within their own live room during cross-room connection.
- Barrage: Aligned with Native; added a custom message callback.
- Login: LoginStore added "kicked offline" and "login state expired" events.
- Flutter: Added support for starting and stopping the camera preview.
- Live: Fixed an issue where the video layout template could not be updated during a live stream.
- Live: Fixed an issue where a connected audience member was not properly removed from the seat after the process was killed in the video live streaming scenario.
- Live: Fixed an issue with abnormal audio quality parameter configuration when turning on the microphone in the voice chat room scenario.

## 4.0.2

Live: Removed the default auto-leave seat logic for voice chat room audience upon entering the room.

## 4.0.1

- Call: Changed the `enableCloudRecording` field from bool type to `TUICloudRecordPolicy` enum type.
- LiveInfo adapted to legacy `seatLayoutTemplateID` and other parameters.
- LiveCoreWidget optimized with some bug fixes.
- DeviceStore default video resolution changed to 720P.
- Added plugin version information.

## 4.0.0

- Webinar Support for Room: Added guest, audience, admin, and mute list management with paginated fetching for large-scale rooms.
- Upgrade rtc_room_engine dependencies to version 4.0.0.

## 3.6.7

- Optimize the performance of AI-powered message transcription.

## 3.6.6

- Optimize the performance of AI-powered message transcription.

## 3.6.5

- Added a new store related to AI transcription.

## 3.6.4

- Adjust the VideoWidgetBuilder parameters of LiveCoreWidget.
- Add the CoreViewType parameter to the create method of LiveCoreController.

## 3.6.3

- CallStore and CallParticipantStore have been merged.
- Removed CallParticipantView, added CallCoreView.

## 3.6.2

- Added multi-person room support: `RoomStore`, `RoomParticipantStore` (state management) and `RoomParticipantWidget` (UI component).
- Upgrade rtc_room_engine dependencies.

## 3.6.1

- Add AI bot user filtering logic to call store

## 3.6.0

- Added live streaming-related Store.
- Upgrade rtc_room_engine dependencies to version 3.6.0.

## 3.5.0

- Fix dependency leakage: Redefine Call structs and enums to encapsulate third-party implementation
  details.
- Upgrade rtc_room_engine dependencies to version 3.5.0.

## 3.4.1

- Add call-related store.
