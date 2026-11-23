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

  /// No description provided for @barrageNewMessages.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条新消息'**
  String barrageNewMessages(Object count);

  /// No description provided for @barrageInputHint.
  ///
  /// In zh, this message translates to:
  /// **'发条弹幕互动一下...'**
  String get barrageInputHint;

  /// No description provided for @barrageErrorMuted.
  ///
  /// In zh, this message translates to:
  /// **'你已被禁言，暂时无法发送评论'**
  String get barrageErrorMuted;

  /// No description provided for @barrageErrorAllMuted.
  ///
  /// In zh, this message translates to:
  /// **'当前直播间已开启全员禁言'**
  String get barrageErrorAllMuted;

  /// No description provided for @barrageErrorTooFrequent.
  ///
  /// In zh, this message translates to:
  /// **'发送太快了，请稍后再试'**
  String get barrageErrorTooFrequent;

  /// No description provided for @barrageErrorContentRejected.
  ///
  /// In zh, this message translates to:
  /// **'评论内容不符合规范，请修改后重试'**
  String get barrageErrorContentRejected;

  /// No description provided for @barrageErrorTooLong.
  ///
  /// In zh, this message translates to:
  /// **'评论内容过长，请缩短后发送'**
  String get barrageErrorTooLong;

  /// No description provided for @barrageErrorLoginExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录已失效，请重新登录'**
  String get barrageErrorLoginExpired;

  /// No description provided for @barrageErrorLoginElsewhere.
  ///
  /// In zh, this message translates to:
  /// **'账号已在其他设备登录，请重新登录'**
  String get barrageErrorLoginElsewhere;

  /// No description provided for @barrageErrorNotJoined.
  ///
  /// In zh, this message translates to:
  /// **'尚未进入直播间，暂时无法发送评论'**
  String get barrageErrorNotJoined;

  /// No description provided for @barrageErrorRoomUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'直播间已不可用，无法发送评论'**
  String get barrageErrorRoomUnavailable;

  /// No description provided for @barrageErrorNoPermission.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法在当前直播间发送评论'**
  String get barrageErrorNoPermission;

  /// No description provided for @barrageErrorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络连接异常，请检查网络后重试'**
  String get barrageErrorNetwork;

  /// No description provided for @barrageErrorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'评论发送超时，请稍后重试'**
  String get barrageErrorTimeout;

  /// No description provided for @barrageErrorSendRejected.
  ///
  /// In zh, this message translates to:
  /// **'评论未能发送，请稍后重试'**
  String get barrageErrorSendRejected;

  /// No description provided for @barrageErrorSendFailed.
  ///
  /// In zh, this message translates to:
  /// **'评论发送失败，请稍后重试'**
  String get barrageErrorSendFailed;

  /// No description provided for @interactionTitle.
  ///
  /// In zh, this message translates to:
  /// **'互动消息'**
  String get interactionTitle;

  /// No description provided for @barrageHostTag.
  ///
  /// In zh, this message translates to:
  /// **'主播'**
  String get barrageHostTag;

  /// No description provided for @giftEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无礼物'**
  String get giftEmpty;

  /// No description provided for @giftNewItems.
  ///
  /// In zh, this message translates to:
  /// **'{count} 件新礼物'**
  String giftNewItems(Object count);

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

  /// No description provided for @audienceMutedToast.
  ///
  /// In zh, this message translates to:
  /// **'已禁言「{name}」'**
  String audienceMutedToast(Object name);

  /// No description provided for @audienceUnmutedToast.
  ///
  /// In zh, this message translates to:
  /// **'已解除对「{name}」的禁言'**
  String audienceUnmutedToast(Object name);

  /// No description provided for @audienceKickedToast.
  ///
  /// In zh, this message translates to:
  /// **'已将「{name}」踢出直播间'**
  String audienceKickedToast(Object name);

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

  /// No description provided for @sceneDefault.
  ///
  /// In zh, this message translates to:
  /// **'场景'**
  String get sceneDefault;

  /// No description provided for @sceneCustomSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'场景 {index}'**
  String sceneCustomSuggestion(Object index);

  /// No description provided for @sceneCopySuffix.
  ///
  /// In zh, this message translates to:
  /// **'{name} {index}'**
  String sceneCopySuffix(Object name, Object index);

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

  /// No description provided for @sceneNameLimit.
  ///
  /// In zh, this message translates to:
  /// **'名称不能超过 20 个字符'**
  String get sceneNameLimit;

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

  /// No description provided for @errorSourceDuplicated.
  ///
  /// In zh, this message translates to:
  /// **'相同的内容已在当前场景中添加，不能重复添加'**
  String get errorSourceDuplicated;

  /// No description provided for @liveShareCopied.
  ///
  /// In zh, this message translates to:
  /// **'直播间 ID 已复制'**
  String get liveShareCopied;

  /// No description provided for @liveShareTooltip.
  ///
  /// In zh, this message translates to:
  /// **'分享直播间（复制房间 ID）'**
  String get liveShareTooltip;

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

  /// No description provided for @imageFormatsHintNoGif.
  ///
  /// In zh, this message translates to:
  /// **'支持 BMP / JPG / PNG 格式'**
  String get imageFormatsHintNoGif;

  /// No description provided for @imageSizeTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'图片尺寸不能超过 8192×8192'**
  String get imageSizeTooLarge;

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
  /// **'支持 MOV / MP4 / MKV 格式'**
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
  /// **'rtmp:// 直播流，或 .m3u8 / .flv / .mov / .mp4 / .mkv 格式的 http(s) 媒体地址'**
  String get onlineVideoUrlHint;

  /// No description provided for @onlineVideoUrlInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入合法的 RTMP 直播流地址或 HTTP(S) 媒体地址\nHTTP(S) 媒体地址支持 .m3u8 / .flv / .mov / .mp4 / .mkv 格式'**
  String get onlineVideoUrlInvalid;

  /// No description provided for @onlineVideoCacheLabel.
  ///
  /// In zh, this message translates to:
  /// **'网络缓存'**
  String get onlineVideoCacheLabel;

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

  /// No description provided for @beautyAllCamerasHidden.
  ///
  /// In zh, this message translates to:
  /// **'摄像头已屏蔽，取消屏蔽后可设置美颜'**
  String get beautyAllCamerasHidden;

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

  /// No description provided for @beautyRuddy.
  ///
  /// In zh, this message translates to:
  /// **'红润'**
  String get beautyRuddy;

  /// No description provided for @runtimeSourceError.
  ///
  /// In zh, this message translates to:
  /// **'画面源\"{sourceName}\"：{reason}'**
  String runtimeSourceError(Object sourceName, Object reason);

  /// No description provided for @errorImageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败'**
  String get errorImageLoadFailed;

  /// No description provided for @errorCameraNotAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'摄像头未授权'**
  String get errorCameraNotAuthorized;

  /// No description provided for @errorCameraIsOccupied.
  ///
  /// In zh, this message translates to:
  /// **'摄像头被占用'**
  String get errorCameraIsOccupied;

  /// No description provided for @errorCameraDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'摄像头已断开'**
  String get errorCameraDisconnected;

  /// No description provided for @errorVideoFileNotExist.
  ///
  /// In zh, this message translates to:
  /// **'视频文件不存在'**
  String get errorVideoFileNotExist;

  /// No description provided for @errorOnlineVideoProtocol.
  ///
  /// In zh, this message translates to:
  /// **'在线视频协议不支持'**
  String get errorOnlineVideoProtocol;

  /// No description provided for @errorLocalVideoFormat.
  ///
  /// In zh, this message translates to:
  /// **'本地视频格式不支持'**
  String get errorLocalVideoFormat;

  /// No description provided for @errorHevcDecoder.
  ///
  /// In zh, this message translates to:
  /// **'无可用解码器'**
  String get errorHevcDecoder;

  /// No description provided for @errorInvalidParams.
  ///
  /// In zh, this message translates to:
  /// **'参数错误'**
  String get errorInvalidParams;

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get errorUnknown;

  /// No description provided for @errorOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试'**
  String get errorOperationFailed;

  /// No description provided for @errorOnlineVideoConnectFailed.
  ///
  /// In zh, this message translates to:
  /// **'在线视频连接失败'**
  String get errorOnlineVideoConnectFailed;

  /// No description provided for @errorOnlineVideoConnectionLost.
  ///
  /// In zh, this message translates to:
  /// **'在线视频连接中断'**
  String get errorOnlineVideoConnectionLost;

  /// No description provided for @errorScreenSourceClosed.
  ///
  /// In zh, this message translates to:
  /// **'分享的窗口或屏幕已关闭'**
  String get errorScreenSourceClosed;

  /// No description provided for @errorScreenDisplayChanged.
  ///
  /// In zh, this message translates to:
  /// **'显示器已断开或发生变更'**
  String get errorScreenDisplayChanged;

  /// No description provided for @errorCameraRunFailed.
  ///
  /// In zh, this message translates to:
  /// **'摄像头运行失败'**
  String get errorCameraRunFailed;

  /// No description provided for @errorScreenRunFailed.
  ///
  /// In zh, this message translates to:
  /// **'屏幕采集失败'**
  String get errorScreenRunFailed;

  /// No description provided for @errorImageRunFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片显示失败'**
  String get errorImageRunFailed;

  /// No description provided for @errorVideoFilePlayFailed.
  ///
  /// In zh, this message translates to:
  /// **'视频文件播放失败'**
  String get errorVideoFilePlayFailed;

  /// No description provided for @errorOnlineVideoPlayFailed.
  ///
  /// In zh, this message translates to:
  /// **'在线视频播放失败'**
  String get errorOnlineVideoPlayFailed;

  /// No description provided for @mixingStoppedSourceLost.
  ///
  /// In zh, this message translates to:
  /// **'画面源丢失，混流已停止'**
  String get mixingStoppedSourceLost;

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

  /// No description provided for @liveStarting.
  ///
  /// In zh, this message translates to:
  /// **'开播中…'**
  String get liveStarting;

  /// No description provided for @liveStartFailed.
  ///
  /// In zh, this message translates to:
  /// **'开播失败，错误码：{code}；错误信息：{message}'**
  String liveStartFailed(Object code, Object message);

  /// No description provided for @liveStartFailedSensitiveInfo.
  ///
  /// In zh, this message translates to:
  /// **'开播失败：直播间名称等信息包含敏感内容，请修改后重试'**
  String get liveStartFailedSensitiveInfo;

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

  /// No description provided for @liveSummaryDuration.
  ///
  /// In zh, this message translates to:
  /// **'直播时长'**
  String get liveSummaryDuration;

  /// No description provided for @liveSummaryGiftsSent.
  ///
  /// In zh, this message translates to:
  /// **'收到礼物'**
  String get liveSummaryGiftsSent;

  /// No description provided for @liveSummaryViewers.
  ///
  /// In zh, this message translates to:
  /// **'观看人次'**
  String get liveSummaryViewers;

  /// No description provided for @liveSummaryMessages.
  ///
  /// In zh, this message translates to:
  /// **'评论数'**
  String get liveSummaryMessages;

  /// No description provided for @liveSummaryLikes.
  ///
  /// In zh, this message translates to:
  /// **'点赞次数'**
  String get liveSummaryLikes;

  /// No description provided for @liveSummaryGiftSenders.
  ///
  /// In zh, this message translates to:
  /// **'送礼人数'**
  String get liveSummaryGiftSenders;

  /// No description provided for @liveSummaryGiftIncome.
  ///
  /// In zh, this message translates to:
  /// **'礼物收益'**
  String get liveSummaryGiftIncome;

  /// No description provided for @liveSummaryUnitPiece.
  ///
  /// In zh, this message translates to:
  /// **'件'**
  String get liveSummaryUnitPiece;

  /// No description provided for @liveSummaryUnitCoin.
  ///
  /// In zh, this message translates to:
  /// **'币'**
  String get liveSummaryUnitCoin;

  /// No description provided for @liveSummaryUnitPerson.
  ///
  /// In zh, this message translates to:
  /// **'人'**
  String get liveSummaryUnitPerson;

  /// No description provided for @liveSummaryUnitMessage.
  ///
  /// In zh, this message translates to:
  /// **'条'**
  String get liveSummaryUnitMessage;

  /// No description provided for @liveSummaryUnitTime.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get liveSummaryUnitTime;

  /// No description provided for @liveSummaryDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get liveSummaryDone;
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
