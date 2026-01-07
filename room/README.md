_English | [简体中文](README.zh-CN.md)_
# Tencent Cloud UIKit for Video Conference

<img src="https://qcloudimg.tencent-cloud.cn/raw/1539bcd27bb2f03a019d55bf65f6c1f5.png" align="left" width=120 height=120>  TUIRoomKit (tencent_conference_uikit) is Tencent Cloud launched a positioning enterprise meeting, online class, network salon and other scenes of the UI component, through the integration of the component, you only need to write a few lines of code can add similar video conference functions for your App, and support screen sharing, member management, ban the ban painting, chat and other functions. TUIRoomKit supports Windows, Mac, Android, iOS, Flutter, Web, Electron and other development platforms.

<a href="https://apps.apple.com/cn/app/%E8%85%BE%E8%AE%AF%E4%BA%91%E9%9F%B3%E8%A7%86%E9%A2%91/id1400663224"><img src="https://qcloudimg.tencent-cloud.cn/raw/348148fb6fd16423c03b7c6de2929c2e.svg" height=40></a> <a href="https://dldir1.qq.com/hudongzhibo/liteav/TRTCDemo.apk"><img src="https://qcloudimg.tencent-cloud.cn/raw/83597d40f8aded40a65b801392fdc724.svg" height=40></a> <a href="https://trtc.io/demo/homepage/#/detail?scene=roomkit"><img src="https://qcloudimg.tencent-cloud.cn/raw/623bd0e0c83a4762155f8363e845b052.svg" height=40></a>



## Features

<p align="center">
  <img src="https://cloudcache.intl.tencent-cloud.com/cms/backend-cms/9d93360651fc11ee974d5254005f490f.png"/>
</p>

- Easy access: Provide open source components with UI, save 90% development time, fast online video conference function.
- Platform connectivity: TUIRoomKit components of all platforms are interconnected and accessible.
- Screen sharing: Based on the screen acquisition capability of each platform jointly polished by 3000+ market applications, with exclusive AI coding algorithm, lower bit rate and clearer picture.
- Member management: It supports multiple standard room management functions such as all mute, single member gag, drawing, inviting to speak, kicking out of the room, etc.
- Other features: Support room members chat screen, sound Settings and other features, welcome to use.

## Make a first video Conference 

### Environment preparation

<table>
<tr>
<td rowspan="1" colSpan="1" >Platform</td>

<td rowspan="1" colSpan="1" >Version</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >Flutter</td>

<td rowspan="1" colSpan="1" >3.29.3 and above versions.</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >Android</td>

<td rowspan="1" colSpan="1" >Android 5.0 (SDK API level 21) or later. </td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >iOS</td>

<td rowspan="1" colSpan="1" >iOS 14.0 and higher.</td>
</tr>
</table>

## Active the service

You can follow the steps below to activate the TRTC Conference product service and receive a free 14-day trial version.

> **Note：**
> 
> If you wish to purchase the paid version, please refer to [TRTC Conference Monthly Packages](https://trtc.io/document/59409), follow the [Purchasing Guide](https://trtc.io/document/54634) to complete the purchase.
> 

1. Visit [TRTC Console > Applications](https://console.trtc.io/), select **Create application**.

   ![](https://qcloudimg.tencent-cloud.cn/raw/b3210cf77e12641226cb1bccc78df1d3.png)

2. In the Create application pop-up, select **Conference** and enter the application name, click **Create**.

   ![](https://qcloudimg.tencent-cloud.cn/raw/a0b8f00ed1c7b03d84a2ba3120dd73ab.png)

3. After completing the application creation, you will default entry to the application details page, select the **Free Trail** in the floating window, and click to** Get started for free**.

   ![](https://qcloudimg.tencent-cloud.cn/raw/9e5c3ec74c3e77e8057f7850504a622c.png)

4. After the activation is completed, you can view the edition information on the current page. The `SDKAppID` and `SDKSecretKey` here will be used in the integration guide.

    ![](https://qcloudimg.tencent-cloud.cn/raw/0f6c1af2be80b2a6afebc4ac3e960ea6.png)

### Access and use

- Step 1: Add the dependency

  Add the [tencent_conference_uikit](https://pub.dev/packages/tencent_conference_uikit) plugin dependency in `pubspec.yaml` file in your project.
  ```
  dependencies:  
   tencent_conference_uikit: latest release version
  ```
  Execute the following command to install the plugin.
  ```
  flutter pub get
  ```

- Step 2: Complete Project Configuration

  - Use `Xcode` to open your project, select [Project] -> [Building Settings] -> [Deployment], and set the [Strip Style] to **Non-Global Symbols** to retain all global symbol information.

  - To use the audio and video functions on **iOS**, you need to authorize the use of the mic and camera (For Android, the relevant permissions have been declared in the SDK, so you do not need to manually configure them). 
    
    Add the following two items to the `Info.plist` of the App, which correspond to the prompt messages of the mic and camera when the system pops up the authorization dialog box. 
    ```
    <key>NSCameraUsageDescription</key>
    <string>TUIRoom needs access to your Camera permission</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>TUIRoom needs access to your Mic permission</string>
    ```
    After completing the above additions, add the following preprocessor definitions in your `ios/Podfile` to enable camera and microphone permissions.
    ```ruby
    post_install do |installer|
      installer.pods_project.targets.each do |target|
        flutter_additional_ios_build_settings(target)
          target.build_configurations.each do |config|
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
          '$(inherited)',
          'PERMISSION_MICROPHONE=1',
          'PERMISSION_CAMERA=1',
          ]
        end
      end
    end
    ```

- Step 3: Login `tencent_conference_uikit` plugin

  Add the following code to your project, which serves to log in to the component by calling the relevant APIs in TUIRoomKit. This step is extremely critical, as only after logging in can you use the various functions of TUIRoomKit, so please be patient and check if the relevant parameters are configured correctly:
  ```dart
  import 'package:rtc_room_engine/rtc_room_engine.dart';


  var loginResult = await LoginStore.shared.login(
    SDKAPPID, // Please replace with your SDKAPPID
    'userId', // Please replace with your user ID
    'userSig',// Please replace with your userSig
  );

  if (loginResult.isSuccess) {
    // login success
  } else {
    // login error
  }
  ```

  **Parameter Description**

  Here is a detailed introduction to the key parameters used in the login function:
  - **SDKAppID**：Obtained it in [Active the service](#active-the-service).

  - **UserID**：The ID of the current user, which is a string that can only contain English letters (a-z and A-Z), numbers (0-9), hyphens (-), and underscores (_).

  - **UserSig**：The authentication credential used by Tencent Cloud to verify whether the current user is allowed to use the TRTC service. You can get it by using the SDKSecretKey to encrypt information such as SDKAppID and UserID. You can generate a temporary UserSig on the [UserSig Tools](https://console.trtc.io/usersig) page in the TRTC console.
  ![](https://qcloudimg.tencent-cloud.cn/raw/1a7924c7e94b4f32b3d4d99053850a56.png)

  - For more information, please refer to the [UserSig](https://trtc.io/document/35166).
    

  > **Note:**
  > 
  >   - **Many developers have contacted us with questions regarding this step. Below are some of the frequently encountered problems:**
  >     - The `SDKAppID` is set incorrectly.
  >     - `UserSig` is set to the value of `SDKSecretKey` mistakenly. The `UserSig` is generated by using the `SDKSecretKey` for the purpose of encrypting information such as `SDKAppID`, `UserID`, and the expiration time. But the value of the `UserSig` cannot be directly substituted with the value of the `SDKSecretKey`.
  >     - The `UserID` is set to a simple string such as 1, 123, or 111, and your colleague may be using the same UserID while working on a project simultaneously. In this case, login will fail as TUIRoomKit doesn't support login on multiple terminals with the same UserID. Therefore, we recommend you use some distinguishable UserID values during debugging.
  >   - The [sample code](https://github.com/Tencent-RTC/TUIRoomKit/blob/main/Flutter/tencent_conference_uikit/example/lib/debug/generate_test_user_sig.dart) on GitHub uses the `genTestUserSig` function to calculate `UserSig` locally, so as to help you complete the current integration process more quickly. However, this scheme exposes your `SDKSecretKey` in the application code, which makes it difficult for you to upgrade and protect your `SDKSecretKey` subsequently. Therefore, we strongly recommend you run the `UserSig` calculation logic on the server and make the application request the `UserSig` calculated in real time every time the application uses the TUIRoomKit component from the server.

- Step 4: User `tencent_conference_uikit` plugin

  - Configure Routing and Internationalization
    Wrap your app with `ComponentTheme` and set up routing and internationalization. Refer to the following code:
    ```dart
    import 'package:tuikit_atomic_x/atomicx.dart';
    import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';

    class MyApp extends StatelessWidget {
      const MyApp({super.key});

      @override
      Widget build(BuildContext context) {
        return ComponentTheme(
          child: MaterialApp(
            navigatorObservers: [RoomNavigatorObserver.instance],
            localizationsDelegates: const [
              ...RoomLocalizations.localizationsDelegates,
            ],
            supportedLocales: const [Locale('en'), Locale('zh')],
            // ...
          ),
        );
      }
    }
    ```

  - Set self username and profile photo (optional)

    ```dart
    import 'package:atomic_x_core/atomicxcore.dart';

    LoginStore.shared.setSelfInfo(
        userInfo: UserProfile(userID: 'userID', nickname: 'userName', avatarURL: 'avatarURL'),
    );
    ```

  - Create a Room
    ```dart
    import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';
    import 'package:atomic_x_core/atomicxcore.dart';

    final options = CreateRoomOptions(
      roomName: 'Your Room Name',  // Room name
    );
    final behavior = RoomBehavior.create(options);
    final config = ConnectConfig(
      autoEnableCamera: true,       // Whether to automatically enable the camera
      autoEnableMicrophone: true,   // Whether to automatically enable the microphone
      autoEnableSpeaker: true,      // Whether to automatically use the speaker
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomMainWidget(
          roomID: 'roomId',  // Your room id
          behavior: behavior,
          config: config,
        ),
      ),
    );
    ```

  - Enter a Room
    ```dart
    import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';

    final behavior = RoomBehavior.enter();
    final config = ConnectConfig(
      autoEnableCamera: true,       // Whether to automatically enable the camera
      autoEnableMicrophone: true,   // Whether to automatically enable the microphone
      autoEnableSpeaker: true,      // Whether to automatically use the speaker
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomMainWidget(
          roomID: 'roomId',  // Your room id
          behavior: behavior,
          config: config,
        ),
      ),
    );
    ```
