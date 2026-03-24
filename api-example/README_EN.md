# AtomicXCore API Example Demo — Flutter

English | [中文](./README.md)

## Introduction

This project is the Flutter API example demo for the **AtomicXCore SDK**, showcasing the full range of core capabilities through four progressive stages — from basic streaming to advanced interactive live broadcasting. Built with Flutter's native Widget system and `ValueListenable` reactive state management, it supports both Android and iOS platforms and serves as a comprehensive reference for developers integrating the AtomicXCore SDK.

## Feature Overview

| Stage | Module | Description |
|:---:|:---|:---|
| 1 | **BasicStreaming** | Live stream creation/joining, camera/microphone management, video rendering |
| 2 | **Interactive** | Barrage messages, gift system (with SVGA animations), likes, beauty filters, audio effects |
| 3 | **CoGuest** | Audience co-guest requests, host invitations, seat management, multi-person video |
| 4 | **LivePK** | Cross-room connection, PK battles, real-time scoring, countdown, battle result display |

> Each stage builds upon the previous one, progressively adding new capabilities.

## Tech Stack

| Category | Technology | Version |
|:---:|:---|:---|
| Framework | Flutter | 3.29.3 |
| Language | Dart | 3.7.2 |
| Core SDK | AtomicXCore (`atomic_x_core`) | ^4.0.0 |
| State Management | Flutter native ValueNotifier / ValueListenableBuilder | — |
| Animation Engine | svgaplayer_flutter | ^2.2.0 |
| Image Caching | cached_network_image | ^3.3.1 |
| Permission Handling | permission_handler | ^11.3.1 |
| Local Storage | shared_preferences | ^2.5.3 |
| Crypto | crypto | ^3.0.6 |
| Localization | Flutter Localizations + intl | — |
| Linting | flutter_lints | ^5.0.0 |

## Architecture

### Architecture Pattern

The project adopts a **Store + ValueListenable reactive architecture** (similar to a MVVM/Flux hybrid):

- **Store Layer**: Provided by the `atomic_x_core` SDK, including `LoginStore`, `LiveListStore`, `DeviceStore`, `BarrageStore`, `GiftStore`, etc. as global singletons or per-room instances
- **State Exposure**: Each Store exposes state objects via `xxxState` properties, with fields typed as `ValueListenable<T>` (Flutter native `ValueNotifier`)
- **UI Binding**: Uses `ValueListenableBuilder<T>` for precise, localized widget tree rebuilds
- **Event Callbacks**: The SDK provides a Listener callback pattern (e.g., `GiftListener`, `BattleListener`), registered via `addXxxListener` / `removeXxxListener`
- **No Third-Party State Management**: Does not use Provider, Riverpod, Bloc, etc. — entirely based on Flutter's native capabilities

### Project Structure

```
flutter/lib/
├── main.dart                                  # App entry (MaterialApp + locale listener)
├── components/                                # Reusable UI component layer
│   ├── components.dart                        # Barrel export file
│   ├── audio_effect_setting_widget.dart        # Audio effect panel (voice changer/reverb/ear monitor)
│   ├── barrage_widget.dart                     # Barrage message list + input
│   ├── beauty_setting_widget.dart              # Beauty filter panel (smooth/whiten/ruddy)
│   ├── co_host_user_list_widget.dart           # Available co-host list (paginated)
│   ├── device_setting_widget.dart              # Device management panel (camera/mic/mirror/quality)
│   ├── gift_animation_widget.dart              # Gift animation (SVGA fullscreen + sliding barrage)
│   ├── gift_panel_widget.dart                  # Gift selection panel (paginated grid + send)
│   ├── like_button.dart                        # Like button (heart particle Bézier curve effect)
│   ├── localized_manager.dart                  # Localization manager (Chinese/English toggle + persistence)
│   ├── permission_helper.dart                  # Runtime permission wrapper (camera/microphone)
│   ├── role.dart                               # Role enum (ANCHOR/AUDIENCE)
│   └── setting_panel_controller.dart           # Generic bottom sheet panel container
├── debug/
│   └── generate_test_user_sig.dart             # Debug utility for local UserSig generation
├── l10n/                                       # Localization resources
│   ├── app_en.arb                              # English strings (template file, 355 entries)
│   ├── app_zh.arb                              # Simplified Chinese strings (212 entries)
│   ├── app_localizations.dart                  # Generated l10n entry
│   ├── app_localizations_en.dart               # Generated English implementation
│   └── app_localizations_zh.dart               # Generated Chinese implementation
└── scenes/                                     # Business scene page layer
    ├── login/
    │   ├── login_page.dart                     # User login page
    │   └── profile_setup_page.dart             # Profile setup page (nickname + avatar)
    ├── feature_list/
    │   └── feature_list_page.dart              # Feature list home page (4 stage entry cards)
    ├── basic_streaming/
    │   └── basic_streaming_page.dart           # Stage 1: Basic Streaming
    ├── interactive/
    │   └── interactive_page.dart               # Stage 2: Interactive
    ├── co_guest/
    │   └── co_guest_page.dart                  # Stage 3: Audience Co-Guest
    └── live_pk/
        └── live_pk_page.dart                   # Stage 4: Live PK Battle
```

### App Flow

```
LoginPage (enter UserID → SDK login)
  │
  ├─ Nickname empty ──→ ProfileSetupPage (set nickname + choose avatar)
  │                          │
  │                          ▼
  └─ Nickname set ─────→ FeatureListPage (4 stage entry cards)
                             │
                             ├─ Select stage → Role selection BottomSheet
                             │   ├─ Anchor → Enter corresponding page directly
                             │   └─ Audience → Enter Room ID Dialog → Enter page
                             │
                             ├──→ BasicStreamingPage  (Stage 1)
                             ├──→ InteractivePage     (Stage 2)
                             ├──→ CoGuestPage         (Stage 3)
                             └──→ LivePKPage          (Stage 4)
```

### Store Types and Lifecycle

| Store | Type | Usage |
|:---|:---|:---|
| `LoginStore.shared` | Global singleton | Authentication, user info |
| `LiveListStore.shared` | Global singleton | Live room lifecycle management |
| `DeviceStore.shared` | Global singleton | Camera/microphone/video quality |
| `BaseBeautyStore.shared` | Global singleton | Beauty filter adjustment |
| `AudioEffectStore.shared` | Global singleton | Audio effects/ear monitor |
| `BarrageStore.create(liveID)` | Per-room instance | Barrage messaging |
| `GiftStore.create(liveID)` | Per-room instance | Gift sending/receiving |
| `LikeStore.create(liveID)` | Per-room instance | Like interaction |
| `CoGuestStore.create(liveID)` | Per-room instance | Audience co-guest management |
| `CoHostStore.create(liveID)` | Per-room instance | Cross-room connection |
| `BattleStore.create(liveID)` | Per-room instance | PK battle management |
| `LiveAudienceStore.create(liveID)` | Per-room instance | Audience list |
| `LiveSeatStore.create(liveID)` | Per-room instance | Seat management |

## AtomicXCore SDK API Reference

### Stage 1: BasicStreaming — Basic Live Streaming

| Store | Key APIs | Functionality |
|:---|:---|:---|
| `LoginStore` | `login()`, `setSelfInfo()`, `loginState` | User authentication & state management |
| `LiveListStore` | `createLive()`, `joinLive()`, `endLive()`, `leaveLive()` | Live room lifecycle management |
| `DeviceStore` | `openLocalCamera()`, `openLocalMicrophone()`, `switchCamera()` | Local device control |
| `LiveCoreWidget` | `LiveCoreController.create(CoreViewType)` | Video rendering widget |

### Stage 2: Interactive — Real-time Interaction

| Store | Key APIs | Functionality |
|:---|:---|:---|
| `BarrageStore` | `sendTextMessage()`, `barrageState.messageList` | Barrage message sending & receiving |
| `GiftStore` | `sendGift()`, `refreshUsableGifts()`, `setLanguage()` | Gift system |
| `LikeStore` | `sendLike()`, `addLikeListener()` | Like interaction |
| `BaseBeautyStore` | `setSmoothLevel()`, `setWhitenessLevel()`, `setRuddyLevel()` | Beauty filter adjustment |
| `AudioEffectStore` | `setAudioChangerType()`, `setAudioReverbType()`, `setVoiceEarMonitorEnable()` | Audio effects & ear monitor |

### Stage 3: CoGuest — Audience Co-Guest

| Store | Key APIs | Functionality |
|:---|:---|:---|
| `CoGuestStore` | `applyForSeat()`, `inviteToSeat()`, `acceptApplication()`, `disconnect()` | Co-guest request management |
| `LiveSeatStore` | `openRemoteCamera()`, `kickUserOutOfSeat()` | Seat & remote device management |
| `LiveAudienceStore` | `fetchAudienceList()` | Audience list |
| `LiveCoreWidget` | `videoWidgetBuilder` | Custom co-guest video overlay |

### Stage 4: LivePK — Live PK Battle

| Store | Key APIs | Functionality |
|:---|:---|:---|
| `CoHostStore` | `requestHostConnection()`, `acceptHostConnection()`, `exitHostConnection()` | Cross-room connection management |
| `BattleStore` | `requestBattle()`, `acceptBattle()`, `exitBattle()`, `battleState` | PK battle management & real-time scoring |
| `LiveListStore` | `fetchLiveList()` | Fetch available hosts for connection |

## Prerequisites

- **Flutter**: 3.29.3 (Dart SDK 3.7.2)
- **Android**: minSdkVersion 21+
- **iOS**: iOS 12.0+
- **IDE**: Android Studio / VS Code with Flutter plugin

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd atomic-api-example/flutter
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure SDK Credentials

Edit `lib/debug/generate_test_user_sig.dart` and fill in your Tencent Cloud application credentials:

```dart
const int SDKAPPID = 0;          // Replace with your SDKAPPID
const String SECRETKEY = '';      // Replace with your SECRETKEY
```

> ⚠️ **Security Note**: `SECRETKEY` is for local debugging only. In production, UserSig must be generated by your backend server. Never embed SECRETKEY in client release builds.

### 4. Run

```bash
# Android
flutter run -d android

# iOS
cd ios && pod install && cd ..
flutter run -d ios
```

## Permissions

### Android

| Permission | Purpose |
|:---|:---|
| `CAMERA` | Camera capture |
| `RECORD_AUDIO` | Microphone capture |
| `MODIFY_AUDIO_SETTINGS` | Audio settings adjustment |

### iOS

| Permission | Purpose |
|:---|:---|
| `NSCameraUsageDescription` | Live streaming video capture |
| `NSMicrophoneUsageDescription` | Live streaming audio capture |

## Localization

The project supports Chinese and English, using Flutter's official `flutter_localizations` + ARB approach:

| File | Description |
|:---|:---|
| `lib/l10n/app_en.arb` | English strings (template file, 355 entries) |
| `lib/l10n/app_zh.arb` | Simplified Chinese strings (212 entries) |

- Defaults to system language (Chinese system → zh, others → en)
- Users can manually switch language from the settings menu on the feature list page
- Language preference is persisted via `SharedPreferences`
