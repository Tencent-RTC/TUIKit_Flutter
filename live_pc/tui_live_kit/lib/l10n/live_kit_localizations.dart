import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'live_kit_localizations_en.dart';
import 'live_kit_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of LiveKitLocalizations
/// returned by `LiveKitLocalizations.of(context)`.
///
/// Applications need to include `LiveKitLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/live_kit_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: LiveKitLocalizations.localizationsDelegates,
///   supportedLocales: LiveKitLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the LiveKitLocalizations.supportedLocales
/// property.
abstract class LiveKitLocalizations {
  LiveKitLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static LiveKitLocalizations of(BuildContext context) {
    return Localizations.of<LiveKitLocalizations>(
      context,
      LiveKitLocalizations,
    )!;
  }

  static const LocalizationsDelegate<LiveKitLocalizations> delegate =
      _LiveKitLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @barrageEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无消息'**
  String get barrageEmpty;

  /// No description provided for @barrageLatest.
  ///
  /// In zh, this message translates to:
  /// **'最新消息'**
  String get barrageLatest;

  /// No description provided for @barrageBackToBottom.
  ///
  /// In zh, this message translates to:
  /// **'回到底部'**
  String get barrageBackToBottom;

  /// No description provided for @barrageInputHint.
  ///
  /// In zh, this message translates to:
  /// **'发条弹幕互动一下...'**
  String get barrageInputHint;

  /// No description provided for @interactionTitle.
  ///
  /// In zh, this message translates to:
  /// **'互动消息'**
  String get interactionTitle;

  /// No description provided for @giftEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无礼物'**
  String get giftEmpty;

  /// No description provided for @giftSent.
  ///
  /// In zh, this message translates to:
  /// **'送出'**
  String get giftSent;

  /// No description provided for @audienceTitle.
  ///
  /// In zh, this message translates to:
  /// **'观众'**
  String get audienceTitle;

  /// No description provided for @audienceEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无观众'**
  String get audienceEmpty;

  /// No description provided for @audienceMute.
  ///
  /// In zh, this message translates to:
  /// **'禁言'**
  String get audienceMute;

  /// No description provided for @audienceUnmute.
  ///
  /// In zh, this message translates to:
  /// **'取消禁言'**
  String get audienceUnmute;

  /// No description provided for @audienceKick.
  ///
  /// In zh, this message translates to:
  /// **'踢出'**
  String get audienceKick;

  /// No description provided for @audienceMutedTag.
  ///
  /// In zh, this message translates to:
  /// **'已禁言'**
  String get audienceMutedTag;

  /// No description provided for @loginBrandTitle.
  ///
  /// In zh, this message translates to:
  /// **'直播推流助手'**
  String get loginBrandTitle;

  /// No description provided for @loginTabUsername.
  ///
  /// In zh, this message translates to:
  /// **'用户名登录'**
  String get loginTabUsername;

  /// No description provided for @loginUsernameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入用户名'**
  String get loginUsernameHint;

  /// No description provided for @loginButton.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginButton;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get commonConfirm;

  /// No description provided for @errorDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get errorDialogTitle;

  /// No description provided for @sceneGame.
  ///
  /// In zh, this message translates to:
  /// **'游戏直播'**
  String get sceneGame;

  /// No description provided for @sceneMovie.
  ///
  /// In zh, this message translates to:
  /// **'观影陪伴'**
  String get sceneMovie;

  /// No description provided for @sceneChat.
  ///
  /// In zh, this message translates to:
  /// **'连麦聊天'**
  String get sceneChat;

  /// No description provided for @sceneTalk.
  ///
  /// In zh, this message translates to:
  /// **'日常唠嗑'**
  String get sceneTalk;

  /// No description provided for @sceneRest.
  ///
  /// In zh, this message translates to:
  /// **'休息中'**
  String get sceneRest;

  /// No description provided for @sceneDefault.
  ///
  /// In zh, this message translates to:
  /// **'场景一'**
  String get sceneDefault;

  /// No description provided for @sceneCustomSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'自定义{index}'**
  String sceneCustomSuggestion(Object index);

  /// No description provided for @sceneCopySuffix.
  ///
  /// In zh, this message translates to:
  /// **'{name} 副本'**
  String sceneCopySuffix(Object name);

  /// No description provided for @sceneMenuRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get sceneMenuRename;

  /// No description provided for @sceneMenuDuplicate.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get sceneMenuDuplicate;

  /// No description provided for @sceneMenuDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get sceneMenuDelete;

  /// No description provided for @sceneRenameTitle.
  ///
  /// In zh, this message translates to:
  /// **'重命名场景'**
  String get sceneRenameTitle;

  /// No description provided for @sceneNameHint.
  ///
  /// In zh, this message translates to:
  /// **'场景名称'**
  String get sceneNameHint;

  /// No description provided for @sceneAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加预设场景'**
  String get sceneAddTitle;

  /// No description provided for @sceneIconPick.
  ///
  /// In zh, this message translates to:
  /// **'选择图标'**
  String get sceneIconPick;

  /// No description provided for @sceneGroupLandscape.
  ///
  /// In zh, this message translates to:
  /// **'横屏场景'**
  String get sceneGroupLandscape;

  /// No description provided for @sceneGroupPortrait.
  ///
  /// In zh, this message translates to:
  /// **'竖屏场景'**
  String get sceneGroupPortrait;

  /// No description provided for @sourceAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加画面源'**
  String get sourceAddTitle;

  /// No description provided for @sourceTypeCamera.
  ///
  /// In zh, this message translates to:
  /// **'摄像头'**
  String get sourceTypeCamera;

  /// No description provided for @sourceTypeCameraDesc.
  ///
  /// In zh, this message translates to:
  /// **'采集摄像头画面'**
  String get sourceTypeCameraDesc;

  /// No description provided for @sourceTypeScreen.
  ///
  /// In zh, this message translates to:
  /// **'屏幕'**
  String get sourceTypeScreen;

  /// No description provided for @sourceTypeScreenDesc.
  ///
  /// In zh, this message translates to:
  /// **'屏幕 / 窗口捕获'**
  String get sourceTypeScreenDesc;

  /// No description provided for @sourceTypeImage.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get sourceTypeImage;

  /// No description provided for @sourceTypeImageDesc.
  ///
  /// In zh, this message translates to:
  /// **'静态图片素材'**
  String get sourceTypeImageDesc;

  /// No description provided for @sourceTypeOnlineVideo.
  ///
  /// In zh, this message translates to:
  /// **'在线视频'**
  String get sourceTypeOnlineVideo;

  /// No description provided for @sourceTypeOnlineVideoDesc.
  ///
  /// In zh, this message translates to:
  /// **'网络视频流地址'**
  String get sourceTypeOnlineVideoDesc;

  /// No description provided for @sourceTypeVideoFile.
  ///
  /// In zh, this message translates to:
  /// **'视频文件'**
  String get sourceTypeVideoFile;

  /// No description provided for @sourceTypeVideoFileDesc.
  ///
  /// In zh, this message translates to:
  /// **'本地视频文件'**
  String get sourceTypeVideoFileDesc;

  /// No description provided for @sourceNameCamera.
  ///
  /// In zh, this message translates to:
  /// **'摄像头画面'**
  String get sourceNameCamera;

  /// No description provided for @sourceNameScreen.
  ///
  /// In zh, this message translates to:
  /// **'屏幕共享'**
  String get sourceNameScreen;

  /// No description provided for @sourceListEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前场景暂无画面源\n点击右上角 + 添加'**
  String get sourceListEmpty;

  /// No description provided for @errorStartMixing.
  ///
  /// In zh, this message translates to:
  /// **'启动混流失败'**
  String get errorStartMixing;

  /// No description provided for @errorSourceNotFound.
  ///
  /// In zh, this message translates to:
  /// **'画面源不存在'**
  String get errorSourceNotFound;

  /// No description provided for @errorAddSource.
  ///
  /// In zh, this message translates to:
  /// **'添加画面源失败（错误码 {code}）'**
  String errorAddSource(Object code);

  /// No description provided for @cameraEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑摄像头'**
  String get cameraEditTitle;

  /// No description provided for @cameraAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加摄像头'**
  String get cameraAddTitle;

  /// No description provided for @cameraDeviceLabel.
  ///
  /// In zh, this message translates to:
  /// **'选择可用摄像头'**
  String get cameraDeviceLabel;

  /// No description provided for @cameraDeviceHint.
  ///
  /// In zh, this message translates to:
  /// **'选择摄像头'**
  String get cameraDeviceHint;

  /// No description provided for @cameraNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未检测到摄像头设备'**
  String get cameraNotFound;

  /// No description provided for @cameraResolutionLabel.
  ///
  /// In zh, this message translates to:
  /// **'采集分辨率'**
  String get cameraResolutionLabel;

  /// No description provided for @cameraMirrorLabel.
  ///
  /// In zh, this message translates to:
  /// **'镜像'**
  String get cameraMirrorLabel;

  /// No description provided for @imageEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑图片'**
  String get imageEditTitle;

  /// No description provided for @imageAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加图片'**
  String get imageAddTitle;

  /// No description provided for @imageFileLabel.
  ///
  /// In zh, this message translates to:
  /// **'图片文件'**
  String get imageFileLabel;

  /// No description provided for @imagePickPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'选择本地图片'**
  String get imagePickPlaceholder;

  /// No description provided for @imagePickButton.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get imagePickButton;

  /// No description provided for @imageFormatsHint.
  ///
  /// In zh, this message translates to:
  /// **'支持 BMP / JPG / PNG / GIF 格式'**
  String get imageFormatsHint;

  /// No description provided for @videoFileEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑视频文件'**
  String get videoFileEditTitle;

  /// No description provided for @videoFileAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加视频文件'**
  String get videoFileAddTitle;

  /// No description provided for @videoFileLabel.
  ///
  /// In zh, this message translates to:
  /// **'视频文件'**
  String get videoFileLabel;

  /// No description provided for @videoPickPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'选择本地视频'**
  String get videoPickPlaceholder;

  /// No description provided for @videoPickButton.
  ///
  /// In zh, this message translates to:
  /// **'选择视频'**
  String get videoPickButton;

  /// No description provided for @videoFileFormatsHint.
  ///
  /// In zh, this message translates to:
  /// **'支持 MP4 / MOV / M4V / MKV / AVI / FLV / WMV 格式'**
  String get videoFileFormatsHint;

  /// No description provided for @onlineVideoEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑在线视频'**
  String get onlineVideoEditTitle;

  /// No description provided for @onlineVideoAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加在线视频'**
  String get onlineVideoAddTitle;

  /// No description provided for @onlineVideoUrlLabel.
  ///
  /// In zh, this message translates to:
  /// **'视频地址'**
  String get onlineVideoUrlLabel;

  /// No description provided for @onlineVideoUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'http:// 或 https:// 开头的视频地址'**
  String get onlineVideoUrlHint;

  /// No description provided for @onlineVideoProtocolHint.
  ///
  /// In zh, this message translates to:
  /// **'仅支持 HTTP / HTTPS 协议'**
  String get onlineVideoProtocolHint;

  /// No description provided for @onlineVideoUrlInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入合法的 http / https 视频地址'**
  String get onlineVideoUrlInvalid;

  /// No description provided for @onlineVideoCacheLabel.
  ///
  /// In zh, this message translates to:
  /// **'网络缓存'**
  String get onlineVideoCacheLabel;

  /// No description provided for @onlineVideoCacheAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get onlineVideoCacheAuto;

  /// No description provided for @onlineVideoCacheAutoScale.
  ///
  /// In zh, this message translates to:
  /// **'0（自动）'**
  String get onlineVideoCacheAutoScale;

  /// No description provided for @screenEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑屏幕共享'**
  String get screenEditTitle;

  /// No description provided for @screenAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加屏幕共享'**
  String get screenAddTitle;

  /// No description provided for @screenTabWindow.
  ///
  /// In zh, this message translates to:
  /// **'窗口'**
  String get screenTabWindow;

  /// No description provided for @screenEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未发现可共享的{kind}\n请检查「系统设置 → 隐私与安全性 → 屏幕录制」权限'**
  String screenEmpty(Object kind);

  /// No description provided for @screenEnumFailed.
  ///
  /// In zh, this message translates to:
  /// **'枚举共享源失败'**
  String get screenEnumFailed;

  /// No description provided for @filePickRequired.
  ///
  /// In zh, this message translates to:
  /// **'请选择{label}文件'**
  String filePickRequired(Object label);

  /// No description provided for @fileFormatUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'不支持的{label}格式：.{ext}'**
  String fileFormatUnsupported(Object label, Object ext);

  /// No description provided for @fileNotReadable.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在或不可读'**
  String get fileNotReadable;

  /// No description provided for @playbackVolume.
  ///
  /// In zh, this message translates to:
  /// **'播放音量'**
  String get playbackVolume;

  /// No description provided for @tabSources.
  ///
  /// In zh, this message translates to:
  /// **'画面源'**
  String get tabSources;

  /// No description provided for @tabBeauty.
  ///
  /// In zh, this message translates to:
  /// **'美颜'**
  String get tabBeauty;

  /// No description provided for @tabMore.
  ///
  /// In zh, this message translates to:
  /// **'更多能力'**
  String get tabMore;

  /// No description provided for @featureInDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'功能开发中'**
  String get featureInDevelopment;

  /// No description provided for @featureComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'敬请期待'**
  String get featureComingSoon;

  /// No description provided for @beautyNoCamera.
  ///
  /// In zh, this message translates to:
  /// **'当前场景下未添加摄像头'**
  String get beautyNoCamera;

  /// No description provided for @beautyFilterTitle.
  ///
  /// In zh, this message translates to:
  /// **'美颜滤镜'**
  String get beautyFilterTitle;

  /// No description provided for @beautySkinSmooth.
  ///
  /// In zh, this message translates to:
  /// **'磨皮'**
  String get beautySkinSmooth;

  /// No description provided for @beautyWhiteness.
  ///
  /// In zh, this message translates to:
  /// **'美白'**
  String get beautyWhiteness;

  /// No description provided for @beautySharpen.
  ///
  /// In zh, this message translates to:
  /// **'锐化'**
  String get beautySharpen;

  /// No description provided for @beautyRuddy.
  ///
  /// In zh, this message translates to:
  /// **'红润'**
  String get beautyRuddy;

  /// No description provided for @orientationLandscape.
  ///
  /// In zh, this message translates to:
  /// **'横屏'**
  String get orientationLandscape;

  /// No description provided for @orientationPortrait.
  ///
  /// In zh, this message translates to:
  /// **'竖屏'**
  String get orientationPortrait;

  /// No description provided for @liveStart.
  ///
  /// In zh, this message translates to:
  /// **'开始直播'**
  String get liveStart;

  /// No description provided for @liveEnd.
  ///
  /// In zh, this message translates to:
  /// **'结束直播'**
  String get liveEnd;

  /// No description provided for @liveInfoEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'修改直播间信息'**
  String get liveInfoEditTitle;

  /// No description provided for @liveInfoNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'直播间名称'**
  String get liveInfoNameLabel;

  /// No description provided for @liveInfoVisibilityLabel.
  ///
  /// In zh, this message translates to:
  /// **'可见范围'**
  String get liveInfoVisibilityLabel;

  /// No description provided for @liveInfoVisibilityPublic.
  ///
  /// In zh, this message translates to:
  /// **'公开'**
  String get liveInfoVisibilityPublic;

  /// No description provided for @liveInfoVisibilityPrivate.
  ///
  /// In zh, this message translates to:
  /// **'隐私'**
  String get liveInfoVisibilityPrivate;

  /// No description provided for @liveInfoSave.
  ///
  /// In zh, this message translates to:
  /// **'保存设置'**
  String get liveInfoSave;

  /// No description provided for @liveDefaultName.
  ///
  /// In zh, this message translates to:
  /// **'{name}的房间'**
  String liveDefaultName(Object name);

  /// No description provided for @liveStatsGiftSenders.
  ///
  /// In zh, this message translates to:
  /// **'{count} 人送礼'**
  String liveStatsGiftSenders(Object count);

  /// No description provided for @liveSummaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'直播已结束'**
  String get liveSummaryTitle;

  /// No description provided for @liveSummarySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'本场直播数据一览'**
  String get liveSummarySubtitle;

  /// No description provided for @liveSummaryDuration.
  ///
  /// In zh, this message translates to:
  /// **'直播时长'**
  String get liveSummaryDuration;

  /// No description provided for @liveSummaryViewers.
  ///
  /// In zh, this message translates to:
  /// **'累计观看'**
  String get liveSummaryViewers;

  /// No description provided for @liveSummaryLikes.
  ///
  /// In zh, this message translates to:
  /// **'点赞总数'**
  String get liveSummaryLikes;

  /// No description provided for @liveSummaryGiftSenders.
  ///
  /// In zh, this message translates to:
  /// **'送礼人数'**
  String get liveSummaryGiftSenders;

  /// No description provided for @liveSummaryDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get liveSummaryDone;

  /// No description provided for @languageSwitch.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get languageSwitch;

  /// No description provided for @languageFollowSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageFollowSystem;
}

class _LiveKitLocalizationsDelegate
    extends LocalizationsDelegate<LiveKitLocalizations> {
  const _LiveKitLocalizationsDelegate();

  @override
  Future<LiveKitLocalizations> load(Locale locale) {
    return SynchronousFuture<LiveKitLocalizations>(
      lookupLiveKitLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_LiveKitLocalizationsDelegate old) => false;
}

LiveKitLocalizations lookupLiveKitLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LiveKitLocalizationsEn();
    case 'zh':
      return LiveKitLocalizationsZh();
  }

  throw FlutterError(
    'LiveKitLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
