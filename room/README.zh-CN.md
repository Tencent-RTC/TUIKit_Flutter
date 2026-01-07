_简体中文 | [English](README.md)_
# 腾讯云 · 多人音视频房间解决方案

<img src="https://qcloudimg.tencent-cloud.cn/raw/1539bcd27bb2f03a019d55bf65f6c1f5.png" align="left" width=120 height=120>  TUIRoomKit 是腾讯云推出一款定位 企业会议、在线课堂、网络沙龙等场景的 UI 组件，通过集成该组件，您只需要编写几行代码就可以为您的 App 添加类似视频会议功能，并且支持屏幕分享、成员管理，禁麦禁画、聊天弹幕等功能。TUIRoomKit 支持 Windows、Mac、Android、iOS、Web、Electron 等多个开发平台。

## 产品特性

<p align="center">
  <img src="https://qcloudimg.tencent-cloud.cn/image/document/7be3c2af73da159e6c691010cec31b4a.png"/>
</p>

- 接入方便：提供带 UI 的开源组件，节省90%开发时间，快速上线在线视频会议功能。
- 平台互通：各平台的 TUIRoomKit 组件互联互通，沟通无障碍；
- 屏幕分享：基于3000+家市场应用共同打磨的各平台屏幕采集能力，搭配专属AI 编码算法，更低码率更清晰的画面；
- 成员管理：支持全体静音、单一成员禁言禁画、邀请发言、踢出房间等多个标准的房间管理功能；
- 其他特性：支持房间成员聊天弹幕、音效设置等其他特性，欢迎使用；

## 开始使用


### 环境准备

|         平台          |  版本   |
| -------------------- | ------ |
| Flutter |3.29.3 及以上版本。|
| Android |Android 5.0 （SDK API Level 21）及以上版本|
| iOS     |iOS 14.0 及更高。|

### 开通服务

在使用 `tencent_conference_uikit` 创建房间前，您需要开通 `tencent_conference_uikit` 专属的多人音视频互动服务，详细步骤如下：

1. 登录 [实时音视频 TRTC 控制台](https://console.cloud.tencent.com/trtc)，单击左侧应用管理页面，找到需要开通的应用（SDKAppID），点击详情按钮，进入应用概览界面。

   ![](https://qcloudimg.tencent-cloud.cn/raw/491d2a01203ba3642dedd0967183cbaa.png)

2. 在应用概览页面找到 **含 UI 低代码集成接入 **卡片，选择**多人音视频（TUIRoomKit）**，点击领取体验按钮，领取7天体验版 TUIRoomKit 进行接入测试。
   

> **注意：**
> 
>   - 领取体验版后仅开通 TUIRoomKit 7天的体验资格，测试过程中所产生的音视频时长等资源消耗，仍会按照实时音视频 TRTC 标准计费规则计费；
>   - 新账号首次可前往 [试用中心](https://cloud.tencent.com/act/pro/video_freetrial?from=19654) 免费领取10000分钟音视频时长；
>   - 如果所选 SDKAppID 体验版领取次数已达上限，需要购买 TUIRoomKit 包月套餐才能开通服务，请点击**场景套餐订阅**按钮或前往 [购买页](https://buy.cloud.tencent.com/trtc) 购买；

   ![](https://qcloudimg.tencent-cloud.cn/raw/2b9660e8f29f0ae307241fe003ec234d.png)

3. 领取完成后，可以看到体验版的基本信息，包括服务状态、版本信息和功能详情、到期时间。这里的 `SDKAppID`、`SDKSecretKey` 会在后续步骤中使用到。

   ![](https://qcloudimg.tencent-cloud.cn/raw/f262b385451c2c89dd710f578dc9c4e5.png)

### 接入使用
- 步骤一：安装 `tencent_conference_uikit` 依赖

  在您的工程 `pubspec.yaml` 文件中，添加[tencent_conference_uikit](https://pub.dev/packages/tencent_conference_uikit)插件依赖。
  ```
  dependencies:  
   tencent_conference_uikit: 最新版本
  ```
  执行以下命令安装组件
  ```
  flutter pub get
  ```

- 步骤二：完成工程配置

  - 使用`Xcode`打开您的工程，选择【项目】->【Building Settings】->【Deployment】，将其下的【Strip Style】设置为`Non-Global Symbols`，以保留所需要的全局符号信息。

  - 如您需要在iOS端使用音视频功能，需要授权麦克风和摄像头的使用权限（Android端已在SDK中声明相关权限，您无需手动进行相关配置）。
    
    在 App 的`Info.plist`中添加以下两项，分别对应麦克风和摄像头在系统弹出授权对话框时的提示信息。
    ```
    <key>NSCameraUsageDescription</key>
    <string>TUIRoom需要访问您的相机权限</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>TUIRoom需要访问您的麦克风权限</string>
    ```
    完成以上添加后，在您的`ios/Podfile`中添加以下预处理器定义，用于启用相机与麦克风权限。
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

- 步骤三：登陆 `tencent_conference_uikit` 组件
  ```dart
  import 'package:atomic_x_core/atomicxcore.dart';


  var loginResult = await LoginStore.shared.login(
    SDKAPPID, // 请替换为您的SDKAPPID
    'userId', // 请替换为您的User ID
    'userSig',// 请替换为您的userSig
  );

  if (loginResult.isSuccess) {
    // login success
  } else {
    // login error
  }
  ```
  **参数说明**

  这里详细介绍一下 login 函数中所需要用到的几个关键参数：
  - **SDKAppID**：在 [开通服务](#开通服务) 中的第4步中您已经获取到，这里不再赘述。

  - **UserID**：当前用户的 ID，字符串类型，只允许包含英文字母（a-z 和 A-Z）、数字（0-9）、连词符（-）和下划线（_）。

  - **UserSig**：使用 [开通服务](#开通服务) 的第4步中获取的 SDKSecretKey 对 SDKAppID、UserID 等信息进行加密，就可以得到 UserSig，它是一个鉴权用的票据，用于腾讯云识别当前用户是否能够使用 TRTC 的服务。您可以通过控制台中的 [辅助工具](https://console.cloud.tencent.com/im/tool-usersig) 生成一个临时可用的 UserSig。


    更多信息请参见 [如何计算及使用 UserSig](https://cloud.tencent.com/document/product/647/17275)。
    

  > **注意：**
  > 
  >   - **这个步骤也是目前我们收到的开发者反馈最多的步骤，常见问题如下：**
  >   - `SDKAppID`设置错误，国内站的`SDKAppID`一般是以140开头的10位整数。
  >   - `UserSig`被错配成了加密密钥（`SDKSecretKey`），`UserSig`是用`SDKSecretKey`把`SDKAppID`、`UserID`以及过期时间等信息加密得来的，而不是直接把`SDKSecretKey`配置成`UserSig`。
  >   - `UserID`被设置成“1”、“123”、“111”等简单字符串，由于 **TUIRoomEngine不支持同一个 UserID 多端登录**，所以在多人协作开发时，形如 “1”、“123”、“111” 这样的`UserID`很容易被您的同事占用，导致登录失败，因此我们建议您在调试的时候设置一些辨识度高的`UserID`。
  >   - `Github`中的[示例代码](https://github.com/Tencent-RTC/TUIRoomKit/blob/main/Flutter/tencent_conference_uikit/example/lib/debug/generate_test_user_sig.dart)使用了`genTestUserSig`函数在本地计算 UserSig 是为了更快地让您跑通当前的接入流程，但该方案会将您的 `SDKSecretKey`暴露在 App 的代码当中，这并不利于您后续升级和保护您的 SDKSecretKey，所以我们强烈建议您将`UserSig`的计算逻辑放在服务端进行，并由 App 在每次使用`TUIRoomKit`组件时向您的服务器请求实时计算出的 UserSig。

- 步骤四：使用 `tencent_conference_uikit` 组件

  - 配置路由和国际化
    使用`ComponentTheme`包裹您的APP,并设置路由和国际化。具体代码参考如下：
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

  - 设置自己头像、昵称（可选）
    ```dart
    import 'package:atomic_x_core/atomicxcore.dart';

    LoginStore.shared.setSelfInfo(
        userInfo: UserProfile(userID: 'userID', nickname: 'userName', avatarURL: 'avatarURL'),
    );
    ```

  - 创建房间
    ```dart
    import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';
    import 'package:atomic_x_core/atomicxcore.dart';

    final options = CreateRoomOptions(
      roomName: '您的房间名称',  // 房间名称
    );
    final behavior = RoomBehavior.create(options);
    final config = ConnectConfig(
      autoEnableCamera: true,       // 是否自动打开摄像头
      autoEnableMicrophone: true,   // 是否自动打开麦克风
      autoEnableSpeaker: true,      // 是否自动使用扬声器
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomMainWidget(
          roomID: 'roomId',  // 您的 room id
          behavior: behavior,
          config: config,
        ),
      ),
    );
    ```

  - 进入房间
    ```dart
    import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';

    final behavior = RoomBehavior.enter();
    final config = ConnectConfig(
      autoEnableCamera: true,       // 是否自动打开摄像头
      autoEnableMicrophone: true,   // 是否自动打开麦克风
      autoEnableSpeaker: true,      // 是否自动使用扬声器
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomMainWidget(
          roomID: 'roomId',  // 您的 room id
          behavior: behavior,
          config: config,
        ),
      ),
    );
    ```
