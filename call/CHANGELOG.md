## Version 4.0.8
### Dependency Description
- Upgrade tuikit_atomic_x to 4.0.0.
### Bugfix
- Fixed the issue of the setCallingBell interface being invalid.

## Version 4.0.7
### Bugfix
- Add related exports for AtomicLocalizations.
- The minimum Android SDK version requirement has been lowered to 21.

## Version 4.0.6
### Bugfix
- Fixed the issue where AI transcription was not working correctly during the second phone call.

## Version 4.0.5
### New Features
- Added descriptions of new interfaces to the README file.

## Version 4.0.4
### New Features
- Supports new AI transcription solutions.

## Version 4.0.3
### New Features
- A more refined README document.

## Version 4.0.2
### New Features
- Optimizing the usage of CallStore.

## Version 4.0.1
### New Features
- Optimize floating window style.

## Version 4.0.0
### Dependency Description
- The plugin's dependencies have been updated; it now requires `atomic_x` as a core dependency library.

## Version 3.6.2
### Bug Fix
- Fixed an issue where the error code for the `call` interface was consistently -1.

## Version 3.6.1
### Bug Fix
- Optimize the group call UI experience.

## Version 3.6.0
### Bug Fix
- Fix the ringtone issue.

## Version 3.5.2
### Bug Fix
- Fix the ringtone issue.

## Version 3.5.1
### Dependency Description
- Upgrade tencent_cloud_uikit_core to 1.7.5.

## Version 3.5.0
### Dependency Description
- Upgrade the dependent RTCRoomEngine SDK version: 3.5.0.
### Bug Fix
- Fixed an issue where a remote user's status was incorrect after joining midway through the process.

## Version 3.4.1
### Bug Fix
- Optimize error message logic.

## Version 3.4.0
### Bug Fix
- Add a debouncing mechanism to the accept button to prevent repeated calls.

## Version 3.3.0
### Bug Fix
- Floating window & banner page opening no longer requires background page opening permission
- Fixed a series of Android ForegroundService related crashes
- Fixed the issue of automatic call rejection in certain scenarios

## Version 3.2.0
### Bug Fix
- Solve the crash caused by starting the keep-alive service in specific scenarios on Android
- Fix the problem that the stopFloatWindow interface is invalid

## Version 3.1.3
### Bug Fix
- Fixed the issue that in certain scenarios, when calling the join interface to join a call, the single-person call page is pulled up

## Version 3.1.2
### Bug Fix
- Fixed the issue that queryRecentCalls callback did not give List<TUICallRecords> type data

## Version 3.1.1
### Bug Fix
- Fixed the issue that the JoinInGroupCallWidget cannot be pulled up in the chat fusion scene group

## Version 3.1.0
### New Features
- Added queryRecentCalls and deleteRecordCalls interfaces

## Version 3.0.3
### Bug Fix
- Solve the problem of `file` version conflicts with some third-party libraries
- Solve the problem of automatic video rotation

## Version 3.0.2
### Bug Fix
- Fixed the issue where basic beauty effects were turned on by default
- Fixed the issue where an error message was displayed when entering the group log in the chat fusion scenario

## Version 3.0.1
### Bug Fix
- Fixed the issue of no call logs when using TUIVoIPExtension plugin.

## Version 3.0.0
### New Features
- Update onCallReceived, onCallBegin and onCallEnd callback parameters
- Added onUserInviting and onCallNotConnected callbacks
- Deprecated onCallCancelled callback

## Version 2.9.3
### Bug fix
- Callback data is not cleaned up when logging out
- The floating window userId sometimes shows that it is not empty
- Push notification for single-person call to open multi-person call interface

## Version 2.9.2
### Bug fix
- Fixed the UI error caused by calling again after the call is busy

## Version 2.9.1
### Bug fix
- Fix Android reject interface crash issue

## Version 2.9.0
### New Features
- Added calls and join interfaces
- Deprecated call, groupCall and joinInGroupCall interfaces

## Version 2.7.2
### Bug fix
- Android: Fixed the issue of not receiving onCallBegin and onCallEnd.

## Version 2.7.1
### New Features
- iOS: Adapt to the new version of TUIVoIPExtension plug-in. The new version of TUIVoIPExtension has more robust performance and can adapt to more complex usage scenarios.

## Version 2.7.0
### Bug fix
- Android&iOS: Fixed an issue where the incoming call banner was incorrectly displayed during a group call.
- Android&iOS: Fixed the issue where the UI for joining a group call is not refreshed in real time when used in Chat.
- Android&iOS: Fixed the issue where the UI page would be abnormal during a group call.
- ### Function Optimization:
- Android&iOS: Group calls display members' nicknames.
- Android: It is no longer necessary to judge whether to apply for camera permission during a voice call.

## Version 2.6.1
### Function Optimization:
- Android: Optimize the call logic when lock screen in Samsung Device.

## Version 2.6.0
### Function Optimization:
- Android: Optimize the call logic when lock screen.
### Bug fix
- iOS: Fixed an issue where the incoming call banner was incorrectly displayed during a group call.
### New Features
- Android&iOS：Added vibration function for incoming calls.

## Version 2.5.2
### Bug fix
- Fixed the issue that the text size of the call page follows the system text size changes

## Version 2.5.1
### New Features
- Android：Support USB Camera.

## Version 2.5.0
### Dependency Description
- Upgrade the dependent client SDK version: Android&iOS TUICallEngine:2.5.0.

## Version 2.4.0
### Dependency Description
- Upgrade the dependent client SDK version: Android&iOS TUICallEngine:2.4.0.

## Version 2.3.6
### Function Optimization:
- Android: Optimize the call logic when lock screen.
- Android&iOS: Optimize the public floating window.
- ### Bug fix
- iOS: Fixed the compilation error caused by agreeing to pull TXIMSDK_Plus_iOS and TXIMSDK_Plus_iOS_XCFramework.

## Version 2.3.5
### Function Optimization:
- Added method to package local calculation of user signature.
- ### Bug fix
- Android: Fixed the crash problem of the group call floating window.

## Version 2.3.4
### New Features
- Android&iOS：Added enableIncomingBanner interface to optimize incoming call display strategy.

## Version 2.3.3
### Function Optimization:
- Android&iOS：Optimize initialization Engine related logic.

## Version 2.3.2
### New Features
- Android & iOS : Support virtual background setting function.
- Android & iOS : Supports incoming call display floating window

## Version 2.3.1
### Bug fix
- Fixed method channel error on non-android and iOS platforms.

## 2.3.0
### New Features
- Android&iOS：Support the function of actively joining group calls.
### Function Optimization:
- Android&iOS：Optimize the login method when used together with tencent_cloud_chat_uikit.
### Dependency Description
- Upgraded tencent_cloud_uikit_core dependency to version 1.5.6.
- Upgrade the dependent client SDK version: Android&iOS TUICallEngine:2.3.0.915.

## 2.2.3
### Dependency Description
- Upgraded tencent_cloud_uikit_core dependency to version 1.5.2.

## 2.2.2
### New Features
- Android & iOS :The onCallReceived callback of TUICallObserver adds a new user-defined parameter userData.

## 2.2.1
### Bug Fixes
- Android: After killing the process, the application received the FCM push but did not answer it, and then entered the application page with an exception.

## 2.2.0
### New Features
- Android: Supports FCM push and needs to be used together with tencent_cloud_chat_push

## 2.1.1
### New Features
- Android&iOS : Use the new UI3.0.

## 2.1.0
### New Features
- Android&iOS : Use the new UI3.0.

## 2.0.6
### Bug Fixes
- iOS : The problem of missing some fields in iOS offline push information

## 2.0.5
### Bug Fixes
- iOS : Fixed the issue of abnormal ringtone when entering the call page during VoIP push and abnormal pulling of remote stream.
- Android :  Fixed an issue where the incoming call page would be abnormal when in the background when the floating window permission was not obtained.
## 2.0.4
### Bug Fixes
- Android&iOS : Fixed the intermittent issue of incoming call page not displaying sometimes after clicking on an incoming call notification.

## 2.0.2
### Bug Fixes
- Android : Fix the issue of call failure under multiple Flutter Engine conditions.

## 2.0.1
### Bug Fixes
- Android & iOS : Fixed an incompatibility issue caused by Tencent RTC Observer when using Tencent RTC components with other components that also use Tencent RTC.
- Android : Fixed an incompatibility issue when using TUIRoom in conjunction with other devices.

## 2.0.0
### Dependency Description
- Upgrade the dependent client SDK version: Android&iOS TUICore:7.6.5011, Android&iOS TUICallEngine:2.0.0.750.

## 1.9.1
## New Features
- iOS: Support Voip.
### Bug Fixes
- iOS: Fixed an issue where the call page would be abnormal when receiving a call in the background.

## 1.9.0
## New Features
- Android$iOS: Add an interface for setting ringtones.
### Function Optimization:
- Android & iOS: Optimize package purchasing prompts.
- Android & iOS: Optimize default bitrates for different resolutions, [see details](https://trtc.io/document/46660/51002/54904/54909).
### Bug Fixes
- iOS: Fixed the issue where the same Observer object can be registered twice.
### Dependency Description
- Upgrade the dependent client SDK version: Android&iOS TUICore:7.5.4852, Android&iOS TUICallEngine:1.9.0.680.

## 1.8.3
### Bug Fixes
- Android&iOS: Fixed the problem of no call message display when using tencent_cloud_chat_uikit.
- Android&iOS: Fixed the problem of occasionally pulling up the group call page during a single-person call.
- Android&iOS: Fixed the problem of occasionally pulling up the call page twice during a call.
- Android&iOS: Fixed the problem of abnormal display of call duration.
### Function Optimization:
- Android: Optimized the problem of failing to pull up the interface in the background when receiving a call.
### Dependency Description
- Upgrade tencent_cloud_uikit_core to version 1.1.1.

## 1.8.2
### Bug Fixes
- iOS: Fixed the problem of some compilers failing to compile due to the use of deprecated Swift interfaces.

## 1.8.1
### Bug Fixes
- Android&iOS: Fixed the problem of the video stream of the other party being displayed during a group call voice call.

## 1.8.0
## New Features
- Android&iOS: Built a new TUICallkit based on the Dart language, which makes it easier to customize your own UI style.
- Android&iOS: TUICallEngine adds multiple business interfaces such as hangup, accept, reject, etc.

## 1.7.6-preview
### Function Optimization:
- Android&iOS: Optimized the display of user information when the username and user avatar are not set.
- Android&iOS: Optimized the UI of one-to-one video calls.
### Bug Fixes:
- Android&iOS: Fixed the problem of abnormal pages generated when logging out during a call.
- Android: Fixed the problem of abnormal pages generated when kicked offline during a call.

## 1.7.5-preview
### New Features
- Android&iOS: Built a new TUICallkit based on the Dart language, which makes it easier to customize your own UI style.
- Android&iOS: TUICallEngine adds multiple business interfaces such as hangup, accept, reject, etc.

## 1.7.4
### Function Optimization:
- Android: Gravity sensing is turned off by default, optimizing the call experience on large screens and customized devices.
### Bug Fixes:
- Android&iOS: When A calls B (offline) and cancels it, A calls B again, and B logs in and comes online, there is an abnormal problem with B's cloud call records.

## 1.7.3
### Function Optimization
- Android: Supports development and debugging using emulators.
### Dependency Description
- Upgrade the dependent client SDK version: Android LiteAVSDK_Professional: 11.3.0.13176.

## 1.7.2
### Bug Fixes
- iOS: Upgrade the client SDK version to fix the problem of AppStore rejection due to Non-public API usage.

## 1.7.1
### New Features
- Android&iOS: Added cloud call records, you can open the service in the console to experience the query.
### Function Optimization
- Android: Lower the level of system keep-alive during the call, only display the keep-alive prompt in the status bar, and remove the notification and vibration.

## 1.6.3
### Bug Fixes:
- iOS: Fixed the problem of an empty page when adding a participant during a call after calling joinInGroupCall.
- iOS: Fixed the problem of user screen being covered after calling joinInGroupCall.

## 1.6.2
### Bug Fixes:
- Android: Fixed the crash problem caused by calling the joinInGroupCall API.

## 1.6.1
### Bug Fixes
- iOS: Fixed the problem of an empty midway page after calling joinInGroupCall.
- iOS: Fixed the problem of user screen blocking after calling joinInGroupCall.

## 1.6.0
### New Features
- Android&iOS: Added the hangup interface.
- Android&iOS: Added user-defined fields and user-defined call timeout duration.
- Android&iOS: Added a midway page for group calls.
### Function Optimization
- Android: Optimized the display of single-person video call avatars.
- Android&iOS: In group calls, inviting other group members to join the call is supported by default.
### Bug Fixes
- Android: Fixed the problem of no sound after connecting to Bluetooth on Android 12 and above devices.
- Android: Fixed the problem of occasional failure of muting on the called end.
- iOS: Fixed the problem of occasional failure to receive incoming call invitations after re-logging in.
- iOS: Fixed the problem of incorrect display of the nickname on the VoIP push page.
### Dependency Description
- Upgrade the dependent client SDK version: Android LiteAVSDK_Professional: 11.1.0.13111, iOS TXLiteAVSDK_Professional: 11.1.14143.

## 1.5.4
### New Features
- iOS: Supports VoIP message push function, providing a better call answering experience.
- Android&iOS: Added advanced parameters for offline push of Xiaomi, Huawei, and VIVO.
- Android&iOS: Supports setting encoding resolution, picture direction, etc.
- Android&iOS: Supports setting rendering direction, rendering mode (adaptive, fill), etc.
### Function Optimization
- Android: Optimized the totaltime parameter unit to milliseconds in the onCallEnd callback.
### Bug Fixes
- Android&iOS: Fixed the abnormal problem of the onCallReceived callback.
- iOS: Fixed the problem of incomplete display of the call page when the screen is rotated.

## 1.5.3
### Bug Fixes
- Android: Fixed the packaging failure problem.
- Android&iOS: Fixed the problem of throwing an exception when the callback method is not implemented.

## 1.5.2
### Bug Fixes
- Android: Fixed the compilation error caused by the API change of TUICallDefine.OfflinePushInfo.

## 1.5.1
### Bug Fixes
- Android&iOS: Fixed the problem of incorrect version dependency of tencent_calls_engine.

## 1.5.0
### Function Optimization
- Android: The ear-to-ear screen function is turned off by default.
- Android: Upgrade the gradle plugin and version.
- Android: Optimized the ringtone playback class to support loop playback.
## Bug Fixes
- Android&iOS: Fixed the problem of no onCallCancel callback when the callee failed to answer the call.
- Android: Fixed the problem of the caller's exception when the callee failed to answer the call.
- Android: Fixed the problem of the callee's interface being called again when the caller cancels the call during the first call permission check and the callee pulls up the interface again.
- Android: Fixed the problem of the userId parameter being empty in the network quality callback to the upper layer.
- iOS: Fixed the problem of incorrect Observer registration timing in the Example.

## 1.4.2
### Bug Fixes
- Android&iOS: Fixed the problem of call exceptions caused by incorrect Observer registration timing in the Example.
- iOS: Fixed the problem of occasional invalid settings of the removeObserver API.

## 1.4.1
### Bug Fixes
- Android: Fixed the problem of the OnCallEnd event being lost after the call ends.

## 1.4.0
### Bug Fixes
- Android&iOS: Fixed the problem of call exceptions when actively joining a room (joinInGroupCall).
- Android: Fixed the problem of call status exceptions when the app is backgrounded during a call and then returned to the foreground.
- Android: Fixed the problem of call initiation failure caused by login status when integrating the tencent_cloud_chat_uikit plugin at the same time.
- Android: Fixed the problem of call initiation failure caused by parameter check issues during group call initiation.

## 1.3.1
### New Features
- Android&iOS: Supports custom offline push messages during calls.
### Bug Fixes
- Android: Fixed the problem of the sdkappid is invalid prompt when integrating the tencent_cloud_chat_uikit plugin at the same time.

## 1.3.0
### Function Optimization
- iOS: Optimized the TUICallKit framework size.
### Bug Fixes
- Android&iOS: Fixed the problem of the call interface not disappearing when the server dissolves the room or kicks out a user.
- Android: Fixed the problem of the call interface not displaying when A calls offline user B, cancels the call, and then calls B again after B comes online.

## 1.2.2
### Bug Fixes
- iOS: Fixed the compilation error caused by static library linking.

## 1.2.0
### New Features
- Android&iOS: Supports 1v1 audio and video calls and group audio and video calls.
- Android&iOS: Supports custom avatars and nicknames.
- Android&iOS: Supports setting custom ringtones.
- Android&iOS: Supports opening a floating window during a call.
- Android&iOS: Supports incoming call services under multiple platform login status.