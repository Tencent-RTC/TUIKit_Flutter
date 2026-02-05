# TUICallKit for Flutter

[![pub package](https://img.shields.io/pub/v/tencent_calls_uikit.svg)](https://pub.dev/packages/tencent_calls_uikit)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey.svg)](https://pub.dev/packages/tencent_calls_uikit)

TUICallKit is a UIKit for audio and video calls launched by Tencent Cloud. It provides a complete audio and video calling solution, supporting one-to-one and group calls with a complete UI interface and call logic.

## Features

- 🎯 **One-to-One Calls**: Support for audio and video one-to-one calls
- 👥 **Group Calls**: Support for multi-party audio and video calls
- 🎨 **Complete UI**: Provides complete call interface, ready to use out of the box
- 🔔 **Incoming Call Alerts**: Support for ringtones, banner notifications, etc.
- 🎛️ **Call Controls**: Mute, speaker, camera switching and other functions
- 🪟 **Floating Window**: Support for mini-window mode without affecting other app usage
- 🌍 **Internationalization**: Multi-language support

## Requirements

- Flutter SDK: `>=3.3.0`
- Dart SDK: `>=3.4.0 <4.0.0`
- Android: minSdkVersion 21
- iOS: 12.0+

## Installation

Run this command in your Flutter project:

```bash
flutter pub add tencent_calls_uikit
```

## Quick Start

### 1. Initialization

Add NavigatorObserver when starting your app:

```dart
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [TUICallKit.navigatorObserver],
      home: YourHomePage(),
    );
  }
}
```

### 2. Login

```dart
// Login to TUICallKit
final result = await TUICallKit.instance.login(
  sdkAppId,     // Your SDKAppID
  userId,       // User ID
  userSig,      // User signature
);

if (result.code == 0) {
  print('Login successful');
} else {
  print('Login failed: ${result.message}');
}
```

### 3. Set User Information

```dart
await TUICallKit.instance.setSelfInfo(
  'nickname',   // User nickname
  'avatar_url', // User avatar URL
);
```

### 4. Make a Call

```dart
// Make an audio call
await TUICallKit.instance.calls(
  ['user1', 'user2'], // List of called users
  CallMediaType.audio, // Call type: audio
);

// Make a video call
await TUICallKit.instance.calls(
  ['user1'], // List of called users
  CallMediaType.video, // Call type: video
);
```

## Advanced Features

### Set Ringtone

```dart
await TUICallKit.instance.setCallingBell('assets/audios/phone_ringing.mp3');
```

### Enable Mute Mode

```dart
await TUICallKit.instance.enableMuteMode(true);
```

### Enable Floating Window

```dart
await TUICallKit.instance.enableFloatWindow(true);
```

### Enable Virtual Background

```dart
await TUICallKit.instance.enableVirtualBackground(true);
```

### Enable Incoming Banner

```dart
TUICallKit.instance.enableIncomingBanner(true);
```

### Enable AI Transcriber

```dart
TUICallKit.instance.enableAITranscriber(true)
```

## Permission Configuration

### Android

Add necessary permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

### iOS

Add permission descriptions in `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for voice calls</string>
```

## Example

Check out the complete example project in the `example` directory to learn how to integrate and use TUICallKit.

```bash
cd example
flutter run
```

## API Documentation

### TUICallKit Main Methods

| Method | Description |
|--------|-------------|
| `login(sdkAppId, userId, userSig)` | Login to TUICallKit |
| `logout()` | Logout from TUICallKit |
| `setSelfInfo(nickname, avatar)` | Set user information |
| `calls(userIdList, callMediaType, params)` | Make a call |
| `join(callId)` | Join a call |
| `setCallingBell(assetName)` | Set ringtone |
| `enableMuteMode(enable)` | Enable mute mode |
| `enableFloatWindow(enable)` | Enable floating window |
| `enableVirtualBackground(enable)` | Enable virtual background |
| `enableIncomingBanner(enable)` | Enable incoming call banner |

### CallMediaType Enum

- `CallMediaType.audio` - Audio call
- `CallMediaType.video` - Video call

## FAQ

### Q: How to get SDKAppID and UserSig?
A: Please refer to the Tencent Cloud official documentation: [Quick Integration](https://cloud.tencent.com/document/product/647/82985)

### Q: No sound during calls?
A: Please check device permission settings and ensure the app has microphone and speaker permissions.

### Q: App crashes during iOS device debugging?
A: Please ensure camera and microphone permission descriptions are properly configured in Info.plist.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version update details.

## License

This project is open source under the [MIT License](LICENSE).

## Support

- Official Documentation: [Tencent Cloud Audio/Video Calls](https://cloud.tencent.com/document/product/647/78742)
- Technical Support: Contact Tencent Cloud customer service
- Issue Reports: [GitHub Issues](https://github.com/Tencent-RTC/TUIKit_Flutter/issues)

