// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get loginTitle => 'LiveKit API Example';

  @override
  String get loginSubtitle => '登录以开始体验';

  @override
  String get loginUserIDPlaceholder => '请输入 User ID';

  @override
  String get loginUserSigPlaceholder => 'User Sig (自动生成)';

  @override
  String get loginButton => '登录';

  @override
  String get loginStatusNotLoggedIn => '未登录';

  @override
  String get loginStatusLoggingIn => '登录中...';

  @override
  String get loginStatusLoggedIn => '已登录';

  @override
  String get loginErrorEmptyUserID => '请输入 User ID';

  @override
  String loginErrorLoginFailed(String error) {
    return '登录失败: $error';
  }

  @override
  String get loginDebugTip => 'UserSig 将由本地自动生成（仅调试模式）';

  @override
  String get loginErrorKickedOffline => '您已被踢下线，请重新登录';

  @override
  String get loginErrorLoginExpired => '登录已过期，请重新登录';

  @override
  String get profileTitle => '完善资料';

  @override
  String get profileHeader => '设置个人资料';

  @override
  String get profileSubtitle => '设置您的昵称和头像，让其他人更容易认识你';

  @override
  String get profileNicknamePlaceholder => '请输入昵称';

  @override
  String get profileConfirm => '完成';

  @override
  String get profileSkip => '跳过';

  @override
  String get profileStatusSaved => '资料保存成功';

  @override
  String get profileErrorEmptyNickname => '请输入昵称';

  @override
  String profileErrorSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get featureListTitle => '功能列表';

  @override
  String get featureListSectionHeader => '选择功能';

  @override
  String get featureListLanguage => '语言切换';

  @override
  String get roleSelectTitle => '请选择身份';

  @override
  String get roleSelectSubtitle => '选择您要体验的角色';

  @override
  String get roleSelectAnchor => '主播';

  @override
  String get roleSelectAnchorDesc => '可以创建直播、发起连麦、开启 PK';

  @override
  String get roleSelectAudience => '观众';

  @override
  String get roleSelectAudienceDesc => '可以观看直播、发送弹幕、送礼、申请连麦';

  @override
  String get liveIDInputTitleAnchor => '输入房间号';

  @override
  String get liveIDInputTitleAudience => '输入房间号';

  @override
  String get liveIDInputMessageAnchor => '已随机生成房间号，您可以修改或重新随机';

  @override
  String get liveIDInputMessageAudience => '请输入要加入的房间号';

  @override
  String get liveIDInputPlaceholder => '9 位数字房间号';

  @override
  String get liveIDInputRandom => '🎲 随机生成';

  @override
  String get liveIDInputErrorEmpty => '房间号不能为空';

  @override
  String get stageBasicStreaming => '基础推拉流';

  @override
  String get stageBasicStreamingDesc => '开启/加入直播';

  @override
  String get stageInteractive => '实时互动';

  @override
  String get stageInteractiveDesc => '弹幕、礼物、点赞、美颜、音效';

  @override
  String get stageCoGuest => '观众连线';

  @override
  String get stageCoGuestDesc => '观众列表、观众申请连线、主播邀请连线、麦位管理';

  @override
  String get stageLivePK => '直播 PK';

  @override
  String get stageLivePKDesc => '主播跨房连线、PK 对战、分数展示';

  @override
  String get basicStreamingTitle => '基础推拉流';

  @override
  String get basicStreamingStartLive => '开始直播';

  @override
  String get basicStreamingStatusCreating => '正在创建直播...';

  @override
  String get basicStreamingStatusEnding => '正在结束直播...';

  @override
  String get basicStreamingStatusJoining => '正在加入直播...';

  @override
  String basicStreamingStatusCreated(String liveId) {
    return '直播创建成功: $liveId';
  }

  @override
  String basicStreamingStatusJoined(String liveId) {
    return '已加入直播: $liveId';
  }

  @override
  String get basicStreamingStatusEnded => '直播已结束';

  @override
  String basicStreamingStatusFailed(String error) {
    return '操作失败: $error';
  }

  @override
  String get basicStreamingEndLiveConfirmTitle => '结束直播';

  @override
  String get basicStreamingEndLiveConfirmMessage => '确定要结束直播吗？';

  @override
  String get interactiveTitle => '实时互动';

  @override
  String get interactiveSettingsTitle => '设置';

  @override
  String get interactiveBarrageTitle => '弹幕功能';

  @override
  String get interactiveBarrageDescription => '发送和接收弹幕消息';

  @override
  String get interactiveBarragePlaceholder => '说点什么...';

  @override
  String get interactiveBarrageSend => '发送弹幕';

  @override
  String get interactiveGiftTitle => '礼物';

  @override
  String get interactiveGiftDescription => '发送礼物和接收礼物';

  @override
  String get interactiveGiftSend => '发送';

  @override
  String get interactiveGiftSent => '送出了';

  @override
  String get interactiveLikeTitle => '点赞功能';

  @override
  String get interactiveLikeDescription => '发送点赞和接收点赞';

  @override
  String get interactiveLikeSend => '发送点赞';

  @override
  String get interactiveBeautyTitle => '美颜';

  @override
  String get interactiveBeautyDescription => '开启美颜效果';

  @override
  String get interactiveBeautySmooth => '磨皮';

  @override
  String get interactiveBeautyWhiteness => '美白';

  @override
  String get interactiveBeautyRuddy => '红润';

  @override
  String get interactiveBeautyReset => '重置全部';

  @override
  String get interactiveAudioEffectTitle => '音效';

  @override
  String get interactiveAudioEffectChangerTitle => '变声效果';

  @override
  String get interactiveAudioEffectChangerNone => '关闭';

  @override
  String get interactiveAudioEffectChangerChild => '小孩';

  @override
  String get interactiveAudioEffectChangerLittleGirl => '少女';

  @override
  String get interactiveAudioEffectChangerMan => '大叔';

  @override
  String get interactiveAudioEffectChangerEthereal => '空灵';

  @override
  String get interactiveAudioEffectReverbTitle => '混响效果';

  @override
  String get interactiveAudioEffectReverbNone => '关闭';

  @override
  String get interactiveAudioEffectReverbKtv => 'KTV';

  @override
  String get interactiveAudioEffectReverbSmallRoom => '小房间';

  @override
  String get interactiveAudioEffectReverbAuditorium => '大厅';

  @override
  String get interactiveAudioEffectReverbMetallic => '金属';

  @override
  String get interactiveAudioEffectEarMonitor => '耳返';

  @override
  String get interactiveAudioEffectEarMonitorVolume => '耳返音量';

  @override
  String get interactiveAudioEffectReset => '重置全部';

  @override
  String get interactiveErrorEmptyContent => '请输入弹幕内容';

  @override
  String get interactiveSuccessGift => '发送礼物成功';

  @override
  String get interactiveSuccessLike => '发送点赞成功';

  @override
  String get multiConnectTitle => '观众连线';

  @override
  String get coGuestAudienceListTitle => '在线观众';

  @override
  String get coGuestAudienceListEmpty => '暂无在线观众';

  @override
  String get coGuestAudienceListInvite => '连线';

  @override
  String get coGuestAudienceListInviting => '邀请中';

  @override
  String get coGuestAudienceListConnected => '连线中';

  @override
  String coGuestAudienceCount(int count) {
    return '在线 $count 人';
  }

  @override
  String get coGuestStatusApplying => '正在申请连线...';

  @override
  String get coGuestStatusCancelled => '已取消连线申请';

  @override
  String get coGuestStatusConnected => '连线成功';

  @override
  String get coGuestStatusDisconnected => '已断开连线';

  @override
  String get coGuestStatusInvited => '已发送连线邀请';

  @override
  String get coGuestApplicationTitle => '连线申请';

  @override
  String coGuestApplicationMessage(String user) {
    return '$user 申请与您连线';
  }

  @override
  String get coGuestApplicationAccept => '接受';

  @override
  String get coGuestApplicationReject => '拒绝';

  @override
  String get coGuestInvitationTitle => '连线邀请';

  @override
  String coGuestInvitationMessage(String user) {
    return '主播 $user 邀请您连线';
  }

  @override
  String get coGuestInvitationAccept => '接受';

  @override
  String get coGuestInvitationReject => '拒绝';

  @override
  String coGuestEventInviteAccepted(String user) {
    return '$user 已接受连线邀请';
  }

  @override
  String coGuestEventInviteRejected(String user) {
    return '$user 拒绝了连线邀请';
  }

  @override
  String coGuestEventApplicationCancelled(String user) {
    return '$user 取消了连线申请';
  }

  @override
  String coGuestEventApplicationRejected(String user) {
    return '$user 拒绝了您的连线申请';
  }

  @override
  String get coGuestEventApplicationTimeout => '连线申请超时，请重试';

  @override
  String get coGuestEventKickedOff => '您已被主播移出连线';

  @override
  String get coGuestEventInvitationCancelled => '主播取消了连线邀请';

  @override
  String coGuestManageTitle(String user) {
    return '管理 $user';
  }

  @override
  String get coGuestManageOpenCamera => '邀请打开摄像头';

  @override
  String get coGuestManageCloseCamera => '关闭摄像头';

  @override
  String get coGuestManageOpenMic => '邀请打开麦克风';

  @override
  String get coGuestManageCloseMic => '关闭麦克风';

  @override
  String get coGuestManageKickOff => '移出连线';

  @override
  String get coGuestSelfManageTitle => '设备管理';

  @override
  String get coGuestSelfManageDisconnect => '断开连线';

  @override
  String get coGuestSelfManageOpenCamera => '打开摄像头';

  @override
  String get coGuestSelfManageCloseCamera => '关闭摄像头';

  @override
  String get coGuestSelfManageOpenMic => '打开麦克风';

  @override
  String get coGuestSelfManageCloseMic => '关闭麦克风';

  @override
  String get coGuestDeviceCameraRequestTitle => '打开摄像头';

  @override
  String get coGuestDeviceCameraRequestMessage => '主播请求您打开摄像头';

  @override
  String get coGuestDeviceMicRequestTitle => '打开麦克风';

  @override
  String get coGuestDeviceMicRequestMessage => '主播请求您打开麦克风';

  @override
  String get coGuestDeviceCameraClosed => '主播已关闭您的摄像头';

  @override
  String get coGuestDeviceMicClosed => '主播已关闭您的麦克风';

  @override
  String get livePKTitle => '直播 PK';

  @override
  String get livePKCoHostConnect => '发起连线';

  @override
  String get livePKCoHostDisconnect => '断开连线';

  @override
  String get livePKCoHostConnecting => '连线请求中...';

  @override
  String get livePKCoHostConnected => '连线成功';

  @override
  String get livePKCoHostDisconnected => '已断开连线';

  @override
  String get livePKCoHostSelectHost => '选择连线主播';

  @override
  String get livePKCoHostEmptyList => '暂无其他直播间';

  @override
  String livePKCoHostRequestReceived(String user) {
    return '$user 请求与您连线';
  }

  @override
  String livePKCoHostRequestAccepted(String user) {
    return '$user 接受了连线';
  }

  @override
  String livePKCoHostRequestRejected(String user) {
    return '$user 拒绝了连线';
  }

  @override
  String get livePKCoHostRequestTimeout => '连线请求超时';

  @override
  String get livePKCoHostRequestCancelled => '对方取消了连线请求';

  @override
  String livePKCoHostUserLeft(String user) {
    return '$user 已退出连线';
  }

  @override
  String get livePKCoHostConfirmDisconnect => '确定要断开连线吗？';

  @override
  String get livePKBattleTitle => 'PK 对战';

  @override
  String get livePKBattleStart => '发起 PK';

  @override
  String get livePKBattleEnd => '结束 PK';

  @override
  String get livePKBattleRequesting => 'PK 请求中...';

  @override
  String get livePKBattleStarted => 'PK 已开始！';

  @override
  String get livePKBattleEnded => 'PK 已结束';

  @override
  String livePKBattleRequestReceived(String user) {
    return '$user 向您发起 PK 挑战';
  }

  @override
  String get livePKBattleRequestAccepted => '对方接受了 PK';

  @override
  String get livePKBattleRequestRejected => '对方拒绝了 PK';

  @override
  String get livePKBattleRequestTimeout => 'PK 请求超时';

  @override
  String livePKBattleDuration(int seconds) {
    return 'PK 时长 $seconds 秒';
  }

  @override
  String livePKBattleScore(int score1, int score2) {
    return '$score1 : $score2';
  }

  @override
  String get livePKBattleWin => '🏆 胜利';

  @override
  String get livePKBattleLose => '失败';

  @override
  String get livePKBattleDraw => '平局';

  @override
  String get livePKBattleMe => '我';

  @override
  String get livePKBattleConfirmEnd => '确定要结束 PK 吗？';

  @override
  String get livePKStatusIdle => '等待连线';

  @override
  String get livePKStatusCoHostConnected => '已连线 · 可发起 PK';

  @override
  String get livePKStatusBattling => 'PK 进行中';

  @override
  String get deviceSettingTitle => '设备管理';

  @override
  String get deviceSettingCamera => '摄像头';

  @override
  String get deviceSettingMicrophone => '麦克风';

  @override
  String get deviceSettingFrontCamera => '前置摄像头';

  @override
  String get deviceSettingMirror => '镜像模式';

  @override
  String get deviceSettingVideoQuality => '视频质量';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonError => '错误';

  @override
  String get commonSuccess => '成功';

  @override
  String get commonWarning => '警告';
}
