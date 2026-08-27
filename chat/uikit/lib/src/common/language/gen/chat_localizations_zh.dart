// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'chat_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ChatLocalizationsZh extends ChatLocalizations {
  ChatLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get voiceTranslate => '翻译';

  @override
  String get voiceCancelTranslation => '取消翻译';

  @override
  String get voiceSwitchLanguage => '切换语言';

  @override
  String get voiceReadAloud => '朗读';

  @override
  String get voiceStopReadAloud => '停止';

  @override
  String get voiceSwitchLanguageSheetTitle => '切换翻译语言';

  @override
  String get voiceTranslateFailed => '翻译失败';

  @override
  String get voiceTtsFailed => '朗读失败';

  @override
  String get voiceMessageSettings => '语音消息设置';

  @override
  String get voiceClone => '音色克隆';

  @override
  String get voiceSelect => '音色选择';

  @override
  String get voiceCloneTip => '请录制一段 10-18 秒的语音，用于克隆您的专属音色';

  @override
  String get voiceCloneReadingTipTitle => '建议朗读以下文字：';

  @override
  String get voiceCloneSampleText =>
      '大家好，我是您的专属语音助手，很高兴为您服务。今天天气真不错，希望您有一个愉快的心情。';

  @override
  String get voiceCloneStartRecord => '点击开始录音';

  @override
  String get voiceCloneStopRecord => '点击停止录音';

  @override
  String get voiceCloneRecordDone => '录音完成';

  @override
  String get voiceCloneNameHint => '请输入音色名称（可选）';

  @override
  String get voiceCloneSubmit => '提交克隆';

  @override
  String get voiceCloneAuthTip =>
      '创建声音需要获取您的人声音频。该敏感信息仅用于当前玩法使用，如不同意授权，可能无法使用音色克隆功能。点击录制代表同意授权。';

  @override
  String get voiceCloneSuccessTitle => '克隆成功';

  @override
  String get voiceCloneSuccessMessage => '您的专属音色已创建成功！';

  @override
  String get voiceCloneFailed => '克隆失败';

  @override
  String get voiceCloneEmptyRecord => '请先录制一段语音';

  @override
  String get voiceCloneTooShortTitle => '录音时间太短';

  @override
  String get voiceCloneTooShortMessage => '请录制至少3秒的语音';

  @override
  String get voiceCloneDefaultName => '我的音色';

  @override
  String get voiceSelectDefaultGroup => '默认音色';

  @override
  String get voiceSelectCustomGroup => '自定义音色';

  @override
  String get voiceSelectEmptyCustom => '暂无自定义音色';

  @override
  String get voiceCustomBadge => '自定义';

  @override
  String get voiceDelete => '删除';

  @override
  String get voiceConfirm => '确定';

  @override
  String get voiceDeleteFailed => '删除失败';

  @override
  String get voiceDefault => '默认';

  @override
  String get voiceXiaoxuMale => '小旭（男）';

  @override
  String get voiceXiaomeiFemale => '小美（女）';

  @override
  String get voiceXiaoxinFemale => '小新（女）';

  @override
  String get voiceXiaoyueFemale => '小月（女）';

  @override
  String get listenFromHere => '从当前听';

  @override
  String get listenSelfSpeaker => '我';

  @override
  String listenSays(String speaker) {
    return '$speaker说：';
  }

  @override
  String listenSentImage(String speaker) {
    return '$speaker发送了图片';
  }

  @override
  String listenSentVideo(String speaker) {
    return '$speaker发送了视频';
  }

  @override
  String listenSentFile(String speaker) {
    return '$speaker发送了文件';
  }

  @override
  String listenSentMerged(String speaker, String title) {
    return '$speaker发送了$title';
  }

  @override
  String get login => '登录';

  @override
  String get logout => '退出登录';

  @override
  String get chat => '消息';

  @override
  String get me => '我的';

  @override
  String get theme => '主题';

  @override
  String get themeLight => '明亮';

  @override
  String get themeDark => '暗黑';

  @override
  String get followSystem => '跟随系统';

  @override
  String get color => '颜色';

  @override
  String get themeColor => '主题颜色';

  @override
  String get selectThemeColor => '选择主题颜色';

  @override
  String get colorHue => '色相';

  @override
  String get colorSaturation => '饱和度';

  @override
  String get colorBrightness => '亮度';

  @override
  String get colorHex => '色值';

  @override
  String get reset => '重置';

  @override
  String get language => '语言';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageAr => 'اَلْعَرَبِيَّة';

  @override
  String get contact => '通讯录';

  @override
  String get messageRevokedBySelf => '你撤回了一条消息';

  @override
  String get messageRevokedByOther => '对方撤回了一条消息';

  @override
  String messageRevokedByUser(Object user) {
    return '$user 撤回了一条消息';
  }

  @override
  String groupMemberJoined(Object user) {
    return '$user 加入了群组';
  }

  @override
  String groupMemberInvited(Object operator, Object users) {
    return '$operator 邀请 $users 加入了群组';
  }

  @override
  String groupMemberQuit(Object user) {
    return '$user 退出了群组';
  }

  @override
  String groupMemberKicked(Object operator, Object users) {
    return '$operator 将 $users 踢出了群组';
  }

  @override
  String groupAdminSet(Object users) {
    return '$users 被设置为管理员';
  }

  @override
  String groupAdminCancelled(Object users) {
    return '$users 被取消了管理员资格';
  }

  @override
  String groupMessagePinned(Object user) {
    return '$user 置顶了一条消息';
  }

  @override
  String groupMessageUnpinned(Object user) {
    return '$user 取消了一条消息置顶';
  }

  @override
  String get you => '你';

  @override
  String get muted => '被禁言';

  @override
  String get unmuted => '被解除禁言';

  @override
  String get day => '天';

  @override
  String get hour => '小时';

  @override
  String get min => '分钟';

  @override
  String get second => '秒';

  @override
  String get messageTypeImage => '[图片]';

  @override
  String get messageTypeVoice => '[语音]';

  @override
  String get messageTypeFile => '[文件]';

  @override
  String get messageTypeVideo => '[视频]';

  @override
  String get messageTypeSticker => '[动画表情]';

  @override
  String get messageTypeCustom => '[自定义消息]';

  @override
  String get groupNameChangedTo => '修改群名称为';

  @override
  String get groupIntroChangedTo => '修改群简介为';

  @override
  String get groupNoticeChangedTo => '修改群公告为';

  @override
  String get groupNoticeDeleted => '删除了群公告';

  @override
  String get groupAvatarChanged => '修改了群头像';

  @override
  String get groupOwnerTransferredTo => '将群主转让给';

  @override
  String get groupMuteAllEnabled => '已开启全员禁言';

  @override
  String get groupMuteAllDisabled => '已关闭全员禁言';

  @override
  String get unknown => '未知';

  @override
  String get groupJoinMethodChangedTo => '修改了入群方式为';

  @override
  String get groupInviteMethodChangedTo => '修改了邀请方式为';

  @override
  String get weekdaySunday => '星期日';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get yesterday => '昨天';

  @override
  String dateMonthDayFormat(int month, int day) {
    return '$month月$day日';
  }

  @override
  String dateYearMonthDayFormat(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get userID => '用户ID';

  @override
  String get groupIDLabel => '群 ID';

  @override
  String get userIDLabel => '用户 ID';

  @override
  String get file => '文件';

  @override
  String get recordAVideo => '摄像';

  @override
  String get audioCall => '语音通话';

  @override
  String get videoCall => '视频通话';

  @override
  String get send => '发送';

  @override
  String get more => '更多';

  @override
  String get delete => '删除';

  @override
  String get clearMessage => '清空聊天记录';

  @override
  String get pin => '置顶聊天';

  @override
  String get unpin => '取消置顶';

  @override
  String get startConversation => '发起单聊';

  @override
  String get createGroupChat => '创建群聊';

  @override
  String get addFriend => '添加好友';

  @override
  String get addGroup => '添加群组';

  @override
  String get addContact => '添加联系人';

  @override
  String get joinGroup => '加入群聊';

  @override
  String get createGroupTips => '创建群组';

  @override
  String get createCommunity => '创建社群';

  @override
  String get groupIDInvalid => '群组 ID 非法，请检查群组 ID 是否填写正确。';

  @override
  String get productDocumentation => '查看产品文档';

  @override
  String get create => '创建';

  @override
  String get groupName => '群名称';

  @override
  String get groupIDOption => '群ID（选填）';

  @override
  String get groupFaceUrl => '群头像';

  @override
  String get groupMemberSelected => '已选择的群成员';

  @override
  String get groupWorkType => '好友工作群(Work)';

  @override
  String get groupPublicType => '陌生人社交群(Public)';

  @override
  String get groupMeetingType => '临时会议群(Meeting)';

  @override
  String get groupCommunityType => '社群(Community)';

  @override
  String get groupWorkDesc =>
      '好友工作群(Work）：类似普通微信群，创建后仅支持已在群内的好友邀请加群，且无需被邀请方同意或群主审批。';

  @override
  String get groupPublicDesc =>
      '陌生人社交群(Public）：类似 QQ 群，创建后群主可以指定群管理员，用户搜索群 ID 发起加群申请后，需要群主或管理员审批通过才能入群。';

  @override
  String get groupMeetingDesc =>
      '临时会议群(Meeting）：创建后可以随意进出，且支持查看入群前消息；适用于音视频会议场景、在线教育场景等与实时音视频产品结合的场景。';

  @override
  String get groupCommunityDesc =>
      '社群(Community)：创建后可以随意进出，最多支持100000人，支持历史消息存储，用户搜索群 ID 发起加群申请后，无需管理员审批即可进群。';

  @override
  String get groupDetail => '群聊详情';

  @override
  String get transferGroupOwner => '转让群主';

  @override
  String get publicGroup => '公开群';

  @override
  String get groupOfAnnouncement => '群公告';

  @override
  String get groupManagement => '群管理';

  @override
  String get groupType => '群类型';

  @override
  String get addGroupWay => '主动加群方式';

  @override
  String get inviteGroupType => '邀请进群方式';

  @override
  String get myAliasInGroup => '我的群名片';

  @override
  String get doNotDisturb => '消息免打扰';

  @override
  String get groupMember => '群成员';

  @override
  String get profileRemark => '备注名';

  @override
  String get groupEdit => '编辑';

  @override
  String get blackList => '黑名单';

  @override
  String get profileBlack => '加入黑名单';

  @override
  String get deleteFriend => '删除好友';

  @override
  String get search => '搜索';

  @override
  String get chatHistory => '聊天记录';

  @override
  String get groups => '群组';

  @override
  String get newFriend => '新的联系人';

  @override
  String get myGroups => '我的群聊';

  @override
  String get contactInfo => '详细资料';

  @override
  String get tuiEmojiSmile => '[微笑]';

  @override
  String get tuiEmojiExpect => '[期待]';

  @override
  String get tuiEmojiBlink => '[眨眼]';

  @override
  String get tuiEmojiGuffaw => '[大笑]';

  @override
  String get tuiEmojiKindSmile => '[姨母笑]';

  @override
  String get tuiEmojiHaha => '[哈哈哈]';

  @override
  String get tuiEmojiCheerful => '[愉快]';

  @override
  String get tuiEmojiSpeechless => '[无语]';

  @override
  String get tuiEmojiAmazed => '[惊讶]';

  @override
  String get tuiEmojiSorrow => '[悲伤]';

  @override
  String get tuiEmojiComplacent => '[得意]';

  @override
  String get tuiEmojiSilly => '[傻了]';

  @override
  String get tuiEmojiLustful => '[色]';

  @override
  String get tuiEmojiGiggle => '[憨笑]';

  @override
  String get tuiEmojiKiss => '[亲亲]';

  @override
  String get tuiEmojiWail => '[大哭]';

  @override
  String get tuiEmojiTearsLaugh => '[哭笑]';

  @override
  String get tuiEmojiTrapped => '[困]';

  @override
  String get tuiEmojiMask => '[口罩]';

  @override
  String get tuiEmojiFear => '[恐惧]';

  @override
  String get tuiEmojiBareTeeth => '[龇牙]';

  @override
  String get tuiEmojiFlareUp => '[发怒]';

  @override
  String get tuiEmojiYawn => '[打哈欠]';

  @override
  String get tuiEmojiTact => '[机智]';

  @override
  String get tuiEmojiStareyes => '[星星眼]';

  @override
  String get tuiEmojiShutUp => '[闭嘴]';

  @override
  String get tuiEmojiSigh => '[叹气]';

  @override
  String get tuiEmojiHehe => '[呵呵]';

  @override
  String get tuiEmojiSilent => '[收声]';

  @override
  String get tuiEmojiSurprised => '[惊喜]';

  @override
  String get tuiEmojiAskance => '[白眼]';

  @override
  String get tuiEmojiOk => '[OK]';

  @override
  String get tuiEmojiShit => '[便便]';

  @override
  String get tuiEmojiMonster => '[怪兽]';

  @override
  String get tuiEmojiDaemon => '[恶魔]';

  @override
  String get tuiEmojiRage => '[恶魔怒]';

  @override
  String get tuiEmojiFool => '[衰]';

  @override
  String get tuiEmojiPig => '[猪]';

  @override
  String get tuiEmojiCow => '[牛]';

  @override
  String get tuiEmojiAi => '[AI]';

  @override
  String get tuiEmojiSkull => '[骷髅]';

  @override
  String get tuiEmojiBombs => '[炸弹]';

  @override
  String get tuiEmojiCoffee => '[咖啡]';

  @override
  String get tuiEmojiCake => '[蛋糕]';

  @override
  String get tuiEmojiBeer => '[啤酒]';

  @override
  String get tuiEmojiFlower => '[花]';

  @override
  String get tuiEmojiWatermelon => '[瓜]';

  @override
  String get tuiEmojiRich => '[壕]';

  @override
  String get tuiEmojiHeart => '[爱心]';

  @override
  String get tuiEmojiMoon => '[月亮]';

  @override
  String get tuiEmojiSun => '[太阳]';

  @override
  String get tuiEmojiStar => '[星星]';

  @override
  String get tuiEmojiRedPacket => '[红包]';

  @override
  String get tuiEmojiCelebrate => '[庆祝]';

  @override
  String get tuiEmojiBless => '[福]';

  @override
  String get tuiEmojiFortune => '[发]';

  @override
  String get tuiEmojiConvinced => '[服]';

  @override
  String get tuiEmojiProhibit => '[禁]';

  @override
  String get tuiEmoji666 => '[666]';

  @override
  String get tuiEmoji857 => '[857]';

  @override
  String get tuiEmojiKnife => '[刀]';

  @override
  String get tuiEmojiLike => '[赞]';

  @override
  String get sendMessage => '发送消息';

  @override
  String get quitGroup => '退出群聊';

  @override
  String get dismissGroup => '解散该群';

  @override
  String get groupNoticeEmpty => '暂无群公告';

  @override
  String get next => '下一步';

  @override
  String get agree => '同意';

  @override
  String get accept => '接受';

  @override
  String get refuse => '拒绝';

  @override
  String get noFriendApplicationList => '暂无新的联系人请求';

  @override
  String get noBlackList => '暂无黑名单用户';

  @override
  String get noGroupList => '暂无群聊';

  @override
  String get noGroupApplicationList => '暂无群申请';

  @override
  String get groupChatNotifications => '群聊通知';

  @override
  String get invite => '邀请';

  @override
  String get groupApplicationAllReadyBeenProcessed => '此邀请或者申请请求已经被处理。';

  @override
  String get accepted => '已同意';

  @override
  String get refused => '已拒绝';

  @override
  String get copy => '复制';

  @override
  String get recall => '撤回';

  @override
  String get forward => '转发';

  @override
  String get quote => '引用';

  @override
  String get searchUserID => '请输入 User ID 搜索用户';

  @override
  String get searchGroupID => '群 ID';

  @override
  String get searchGroupIDHint => '请输入群 ID 搜索群聊';

  @override
  String get addFailed => '添加失败';

  @override
  String get joinGroupFailed => '加入失败';

  @override
  String get alreadyFriend => '已经是好友';

  @override
  String get signature => '个性签名';

  @override
  String get fillInTheVerificationInformation => '填写验证信息';

  @override
  String get joinedGroupSuccessfully => '成功';

  @override
  String get contactAddedSuccessfully => '联系人添加成功';

  @override
  String get message => '消息';

  @override
  String get groupWork => '工作群';

  @override
  String get groupPublic => '公开群';

  @override
  String get groupMeeting => '会议群';

  @override
  String get groupCommunity => '社群';

  @override
  String get groupAVChatRoom => '直播群';

  @override
  String get groupAddAny => '自动审批';

  @override
  String get groupAddAuth => '管理员审批';

  @override
  String get groupAddForbid => '禁止加群';

  @override
  String get groupInviteForbid => '禁止邀请';

  @override
  String get groupOwner => '群主';

  @override
  String get member => '成员';

  @override
  String get admin => '管理员';

  @override
  String get modifyGroupName => '修改群名称';

  @override
  String get modifyGroupNickname => '修改群名片';

  @override
  String get chatBackground => '聊天背景';

  @override
  String get selectChatBackground => '选择聊天背景';

  @override
  String get chatBackgroundDefault => '默认';

  @override
  String get chatBackgroundCustom => '已设置';

  @override
  String get quitGroupTip => '您确认退出该群？';

  @override
  String get dismissGroupTip => '您确认解散该群？';

  @override
  String get clearMsgTip => '确认清除聊天记录？';

  @override
  String get muteAll => '全员禁言';

  @override
  String get addMuteMemberTip => '添加需要禁言的群成员';

  @override
  String get groupMuteTip => '全员禁言开启后，只允许群主和管理员发言。';

  @override
  String get deleteFriendTip => '确认删除联系人？';

  @override
  String get remarkEdit => '修改备注';

  @override
  String get detail => '详情';

  @override
  String get setAdmin => '设置为管理员';

  @override
  String get cancelAdmin => '取消管理员';

  @override
  String get deleteGroupMemberTip => '确认删除群成员？';

  @override
  String get settingSuccess => '设置成功！';

  @override
  String get settingFail => '设置失败！';

  @override
  String get noMore => '没有更多了';

  @override
  String get sayTimeShort => '说话时间太短';

  @override
  String get recordLimitTips => '已达到最大语音长度';

  @override
  String get chooseAvatar => '选择头像';

  @override
  String get inputGroupName => '请输入群名称';

  @override
  String get error => '错误';

  @override
  String maxCountFile(Object maxCount) {
    return '最多只能选择 $maxCount 个文件';
  }

  @override
  String get groupIntroDeleted => '删除了群简介';

  @override
  String get groupJoinForbidden => '禁止加群';

  @override
  String get groupJoinApproval => '管理员审批';

  @override
  String get groupJoinFree => '自由加群';

  @override
  String get groupInviteForbidden => '禁止邀请';

  @override
  String get groupInviteApproval => '管理员审批';

  @override
  String get groupInviteFree => '自由邀请';

  @override
  String get friendLimit => '您的好友数已达系统上限';

  @override
  String get otherFriendLimit => '对方的好友数已达系统上限';

  @override
  String get inBlacklist => '被加好友在自己的黑名单中';

  @override
  String get setInBlacklist => '您已被被对方设置为黑名单';

  @override
  String get forbidAddFriend => '对方已禁止加好友';

  @override
  String get waitAgreeFriend => '等待好友审核同意';

  @override
  String get userNotExist => '该用户不存在';

  @override
  String get addGroupPermissionDeny => '禁止加群';

  @override
  String get addGroupAlreadyMember => '已经是群成员';

  @override
  String get addGroupNotFound => '群组不存在';

  @override
  String get addGroupFullMember => '群已满员';

  @override
  String chatRecords(Object count) {
    return '$count条相关记录';
  }

  @override
  String get addRule => '加我为好友时';

  @override
  String get allowAny => '允许任何人';

  @override
  String get denyAny => '拒绝任何人';

  @override
  String get needConfirm => '需要验证';

  @override
  String get noSignature => '暂无个性签名';

  @override
  String get gender => '性别';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get birthday => '生日';

  @override
  String get setNickname => '修改昵称';

  @override
  String get setSignature => '修改个性签名';

  @override
  String get messageNum => '条';

  @override
  String get draft => '[草稿]';

  @override
  String get sendMessageFail => '发送失败';

  @override
  String get resendTips => '确定重发吗？';

  @override
  String get stopCallTip => '通话时长';

  @override
  String get startCall => '发起通话';

  @override
  String get acceptCall => '已接听';

  @override
  String get groupCallSend => '发起了群通话';

  @override
  String get groupCallEnd => '通话结束';

  @override
  String get groupCallNoAnswer => '未接听';

  @override
  String get groupCallReject => '拒绝群通话';

  @override
  String get groupCallAccept => '接听';

  @override
  String get groupCallConfirmSwitchToAudio => '同意视频转语音';

  @override
  String get unknownCall => '未知通话';

  @override
  String get join => '加入';

  @override
  String peopleOnCall(Object number) {
    return '$number 人正在通话中';
  }

  @override
  String get groupReadBy => '已读';

  @override
  String get groupDeliveredTo => '未读';

  @override
  String get readReceiptAllRead => '全部已读';

  @override
  String readReceiptNPersonRead(int count) {
    return '$count人已读';
  }

  @override
  String get messageReadReceipt => '消息阅读状态';

  @override
  String get messageReadReceiptEnabledDesc =>
      '关闭后，您收发的消息均不带消息阅读状态，您将无法看到对方是否已读，同时对方也无法看到您是否已读。';

  @override
  String get messageReadReceiptDisabledDesc =>
      '开启后，您在群聊中收发的消息均带有消息阅读状态，并且可以看到对方是否已读。与您单聊的好友若也开启了消息阅读状态，您与好友在单聊中收发的消息也将带有消息阅读状态。';

  @override
  String get markAsRead => '标为已读';

  @override
  String get markAsUnread => '标为未读';

  @override
  String get multiSelect => '多选';

  @override
  String get postEmojis => '贴表情';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get allEmojis => '全部';

  @override
  String get selectChat => '选择会话';

  @override
  String selectedCount(int count) {
    return '已选择 $count 条';
  }

  @override
  String get forwardIndividually => '逐条转发';

  @override
  String get forwardMerged => '合并转发';

  @override
  String get groupChatHistory => '群聊的聊天记录';

  @override
  String c2cChatHistoryFormat(String name) {
    return '$name的聊天记录';
  }

  @override
  String chatHistoryForSomebodyFormat(String name1, String name2) {
    return '$name1和$name2的聊天记录';
  }

  @override
  String get forwardCompatibleText => '请升级到最新版本查看聊天记录';

  @override
  String get forwardFailedMessageTip => '发送失败消息不支持转发！';

  @override
  String get forwardSeparateLimitTip => '转发消息过多，暂不支持逐条转发';

  @override
  String get deleteMessagesConfirmTip => '确定删除已选消息？';

  @override
  String get deleteConversationTip => '确定删除该会话？';

  @override
  String get conversationListAtAll => '[@所有人]';

  @override
  String get conversationListAtMe => '[有人@我]';

  @override
  String get messageInputAllMembers => '所有人';

  @override
  String get selectMentionMember => '选择提醒的人';

  @override
  String get tapToRemove => '点击移除';

  @override
  String get messageTypeSecurityStrike => '涉及敏感内容';

  @override
  String get convertToText => '转文字';

  @override
  String get convertToTextFailed => '转换失败';

  @override
  String get hide => '隐藏';

  @override
  String get translate => '翻译';

  @override
  String get translateFailed => '翻译失败';

  @override
  String get translateDefaultTips => '由腾讯云 IM 提供翻译支持';

  @override
  String get translating => '翻译中...';

  @override
  String get translateTargetLanguage => '翻译目标语言';

  @override
  String get backToLatest => '回到最新位置';

  @override
  String newMessageCount(int count) {
    return '$count 条新消息';
  }

  @override
  String get holdToTalk => '按住说话';

  @override
  String get sendMessageOrHoldToTalk => '发消息或按住说话...';

  @override
  String get releaseToSend => '松手发送';

  @override
  String get releaseToCancel => '松手取消';

  @override
  String recordCountdownTips(int seconds) {
    return '${seconds}s 后将停止录音';
  }

  @override
  String get backToQuotePosition => '回到引用位置';

  @override
  String get quotedMessageRevoked => '引用内容已撤回';

  @override
  String get quotedMessageNotFound => '无法找到引用内容';

  @override
  String get quotedOriginalMessageUnreachable => '无法定位到原消息';

  @override
  String reactionUserSummary(String name, int totalCount, int othersCount) {
    return '$name等$totalCount人';
  }

  @override
  String get messageTypeMerged => '[合并消息]';

  @override
  String get messageTypeUnknown => '[消息]';

  @override
  String get releaseToConvert => '松手转文字';

  @override
  String get voiceToTextFailed => '未识别到文字内容';

  @override
  String get sendOriginalVoice => '发送原语音';

  @override
  String get addMembers => '添加成员';

  @override
  String get album => '相册';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get takeAPhoto => '拍照';

  @override
  String get callRejectCaller => '对方已拒绝';

  @override
  String get callRejectCallee => '已拒绝';

  @override
  String get callCancelCaller => '已取消';

  @override
  String get callCancelCallee => '对方已取消';

  @override
  String get callTimeoutCaller => '对方无应答';

  @override
  String get callTimeoutCallee => '超时无应答';

  @override
  String get callLineBusyCaller => '对方忙线中';

  @override
  String get callLineBusyCallee => '忙线未接听';

  @override
  String get callingSwitchToAudio => '视频转语音';

  @override
  String get callingSwitchToAudioAccept => '确认视频转语音';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class ChatLocalizationsZhHans extends ChatLocalizationsZh {
  ChatLocalizationsZhHans() : super('zh_Hans');

  @override
  String get voiceTranslate => '翻译';

  @override
  String get voiceCancelTranslation => '取消翻译';

  @override
  String get voiceSwitchLanguage => '切换语言';

  @override
  String get voiceReadAloud => '朗读';

  @override
  String get voiceStopReadAloud => '停止';

  @override
  String get voiceSwitchLanguageSheetTitle => '切换翻译语言';

  @override
  String get voiceTranslateFailed => '翻译失败';

  @override
  String get voiceTtsFailed => '朗读失败';

  @override
  String get voiceMessageSettings => '语音消息设置';

  @override
  String get voiceClone => '音色克隆';

  @override
  String get voiceSelect => '音色选择';

  @override
  String get voiceCloneTip => '请录制一段 10-18 秒的语音，用于克隆您的专属音色';

  @override
  String get voiceCloneReadingTipTitle => '建议朗读以下文字：';

  @override
  String get voiceCloneSampleText =>
      '大家好，我是您的专属语音助手，很高兴为您服务。今天天气真不错，希望您有一个愉快的心情。';

  @override
  String get voiceCloneStartRecord => '点击开始录音';

  @override
  String get voiceCloneStopRecord => '点击停止录音';

  @override
  String get voiceCloneRecordDone => '录音完成';

  @override
  String get voiceCloneNameHint => '请输入音色名称（可选）';

  @override
  String get voiceCloneSubmit => '提交克隆';

  @override
  String get voiceCloneAuthTip =>
      '创建声音需要获取您的人声音频。该敏感信息仅用于当前玩法使用，如不同意授权，可能无法使用音色克隆功能。点击录制代表同意授权。';

  @override
  String get voiceCloneSuccessTitle => '克隆成功';

  @override
  String get voiceCloneSuccessMessage => '您的专属音色已创建成功！';

  @override
  String get voiceCloneFailed => '克隆失败';

  @override
  String get voiceCloneEmptyRecord => '请先录制一段语音';

  @override
  String get voiceCloneTooShortTitle => '录音时间太短';

  @override
  String get voiceCloneTooShortMessage => '请录制至少3秒的语音';

  @override
  String get voiceCloneDefaultName => '我的音色';

  @override
  String get voiceSelectDefaultGroup => '默认音色';

  @override
  String get voiceSelectCustomGroup => '自定义音色';

  @override
  String get voiceSelectEmptyCustom => '暂无自定义音色';

  @override
  String get voiceCustomBadge => '自定义';

  @override
  String get voiceDelete => '删除';

  @override
  String get voiceConfirm => '确定';

  @override
  String get voiceDeleteFailed => '删除失败';

  @override
  String get voiceDefault => '默认';

  @override
  String get voiceXiaoxuMale => '小旭（男）';

  @override
  String get voiceXiaomeiFemale => '小美（女）';

  @override
  String get voiceXiaoxinFemale => '小新（女）';

  @override
  String get voiceXiaoyueFemale => '小月（女）';

  @override
  String get listenFromHere => '从当前听';

  @override
  String get listenSelfSpeaker => '我';

  @override
  String listenSays(String speaker) {
    return '$speaker说：';
  }

  @override
  String listenSentImage(String speaker) {
    return '$speaker发送了图片';
  }

  @override
  String listenSentVideo(String speaker) {
    return '$speaker发送了视频';
  }

  @override
  String listenSentFile(String speaker) {
    return '$speaker发送了文件';
  }

  @override
  String listenSentMerged(String speaker, String title) {
    return '$speaker发送了$title';
  }

  @override
  String get login => '登录';

  @override
  String get logout => '退出登录';

  @override
  String get chat => '消息';

  @override
  String get me => '我的';

  @override
  String get theme => '主题';

  @override
  String get themeLight => '明亮';

  @override
  String get themeDark => '暗黑';

  @override
  String get followSystem => '跟随系统';

  @override
  String get color => '颜色';

  @override
  String get themeColor => '主题颜色';

  @override
  String get selectThemeColor => '选择主题颜色';

  @override
  String get colorHue => '色相';

  @override
  String get colorSaturation => '饱和度';

  @override
  String get colorBrightness => '亮度';

  @override
  String get colorHex => '色值';

  @override
  String get reset => '重置';

  @override
  String get language => '语言';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageAr => 'اَلْعَرَبِيَّة';

  @override
  String get contact => '通讯录';

  @override
  String get messageRevokedBySelf => '你撤回了一条消息';

  @override
  String get messageRevokedByOther => '对方撤回了一条消息';

  @override
  String messageRevokedByUser(Object user) {
    return '$user 撤回了一条消息';
  }

  @override
  String groupMemberJoined(Object user) {
    return '$user 加入了群组';
  }

  @override
  String groupMemberInvited(Object operator, Object users) {
    return '$operator 邀请 $users 加入了群组';
  }

  @override
  String groupMemberQuit(Object user) {
    return '$user 退出了群组';
  }

  @override
  String groupMemberKicked(Object operator, Object users) {
    return '$operator 将 $users 踢出了群组';
  }

  @override
  String groupAdminSet(Object users) {
    return '$users 被设置为管理员';
  }

  @override
  String groupAdminCancelled(Object users) {
    return '$users 被取消了管理员资格';
  }

  @override
  String groupMessagePinned(Object user) {
    return '$user 置顶了一条消息';
  }

  @override
  String groupMessageUnpinned(Object user) {
    return '$user 取消了一条消息置顶';
  }

  @override
  String get you => '你';

  @override
  String get muted => '被禁言';

  @override
  String get unmuted => '被解除禁言';

  @override
  String get day => '天';

  @override
  String get hour => '小时';

  @override
  String get min => '分钟';

  @override
  String get second => '秒';

  @override
  String get messageTypeImage => '[图片]';

  @override
  String get messageTypeVoice => '[语音]';

  @override
  String get messageTypeFile => '[文件]';

  @override
  String get messageTypeVideo => '[视频]';

  @override
  String get messageTypeSticker => '[动画表情]';

  @override
  String get messageTypeCustom => '[自定义消息]';

  @override
  String get groupNameChangedTo => '修改群名称为';

  @override
  String get groupIntroChangedTo => '修改群简介为';

  @override
  String get groupNoticeChangedTo => '修改群公告为';

  @override
  String get groupNoticeDeleted => '删除了群公告';

  @override
  String get groupAvatarChanged => '修改了群头像';

  @override
  String get groupOwnerTransferredTo => '将群主转让给';

  @override
  String get groupMuteAllEnabled => '已开启全员禁言';

  @override
  String get groupMuteAllDisabled => '已关闭全员禁言';

  @override
  String get unknown => '未知';

  @override
  String get groupJoinMethodChangedTo => '修改了入群方式为';

  @override
  String get groupInviteMethodChangedTo => '修改了邀请方式为';

  @override
  String get weekdaySunday => '星期日';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get yesterday => '昨天';

  @override
  String dateMonthDayFormat(int month, int day) {
    return '$month月$day日';
  }

  @override
  String dateYearMonthDayFormat(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get userID => '用户ID';

  @override
  String get groupIDLabel => '群 ID';

  @override
  String get userIDLabel => '用户 ID';

  @override
  String get file => '文件';

  @override
  String get recordAVideo => '摄像';

  @override
  String get audioCall => '语音通话';

  @override
  String get videoCall => '视频通话';

  @override
  String get send => '发送';

  @override
  String get more => '更多';

  @override
  String get delete => '删除';

  @override
  String get clearMessage => '清空聊天记录';

  @override
  String get pin => '置顶聊天';

  @override
  String get unpin => '取消置顶';

  @override
  String get startConversation => '发起单聊';

  @override
  String get createGroupChat => '创建群聊';

  @override
  String get addFriend => '添加好友';

  @override
  String get addGroup => '添加群组';

  @override
  String get addContact => '添加联系人';

  @override
  String get joinGroup => '加入群聊';

  @override
  String get createGroupTips => '创建群组';

  @override
  String get createCommunity => '创建社群';

  @override
  String get groupIDInvalid => '群组 ID 非法，请检查群组 ID 是否填写正确。';

  @override
  String get productDocumentation => '查看产品文档';

  @override
  String get create => '创建';

  @override
  String get groupName => '群名称';

  @override
  String get groupIDOption => '群ID（选填）';

  @override
  String get groupFaceUrl => '群头像';

  @override
  String get groupMemberSelected => '已选择的群成员';

  @override
  String get groupWorkType => '好友工作群(Work)';

  @override
  String get groupPublicType => '陌生人社交群(Public)';

  @override
  String get groupMeetingType => '临时会议群(Meeting)';

  @override
  String get groupCommunityType => '社群(Community)';

  @override
  String get groupWorkDesc =>
      '好友工作群(Work）：类似普通微信群，创建后仅支持已在群内的好友邀请加群，且无需被邀请方同意或群主审批。';

  @override
  String get groupPublicDesc =>
      '陌生人社交群(Public）：类似 QQ 群，创建后群主可以指定群管理员，用户搜索群 ID 发起加群申请后，需要群主或管理员审批通过才能入群。';

  @override
  String get groupMeetingDesc =>
      '临时会议群(Meeting）：创建后可以随意进出，且支持查看入群前消息；适用于音视频会议场景、在线教育场景等与实时音视频产品结合的场景。';

  @override
  String get groupCommunityDesc =>
      '社群(Community)：创建后可以随意进出，最多支持100000人，支持历史消息存储，用户搜索群 ID 发起加群申请后，无需管理员审批即可进群。';

  @override
  String get groupDetail => '群聊详情';

  @override
  String get transferGroupOwner => '转让群主';

  @override
  String get publicGroup => '公开群';

  @override
  String get groupOfAnnouncement => '群公告';

  @override
  String get groupManagement => '群管理';

  @override
  String get groupType => '群类型';

  @override
  String get addGroupWay => '主动加群方式';

  @override
  String get inviteGroupType => '邀请进群方式';

  @override
  String get myAliasInGroup => '我的群名片';

  @override
  String get doNotDisturb => '消息免打扰';

  @override
  String get groupMember => '群成员';

  @override
  String get profileRemark => '备注名';

  @override
  String get groupEdit => '编辑';

  @override
  String get blackList => '黑名单';

  @override
  String get profileBlack => '加入黑名单';

  @override
  String get deleteFriend => '删除好友';

  @override
  String get search => '搜索';

  @override
  String get chatHistory => '聊天记录';

  @override
  String get groups => '群组';

  @override
  String get newFriend => '新的联系人';

  @override
  String get myGroups => '我的群聊';

  @override
  String get contactInfo => '详细资料';

  @override
  String get tuiEmojiSmile => '[微笑]';

  @override
  String get tuiEmojiExpect => '[期待]';

  @override
  String get tuiEmojiBlink => '[眨眼]';

  @override
  String get tuiEmojiGuffaw => '[大笑]';

  @override
  String get tuiEmojiKindSmile => '[姨母笑]';

  @override
  String get tuiEmojiHaha => '[哈哈哈]';

  @override
  String get tuiEmojiCheerful => '[愉快]';

  @override
  String get tuiEmojiSpeechless => '[无语]';

  @override
  String get tuiEmojiAmazed => '[惊讶]';

  @override
  String get tuiEmojiSorrow => '[悲伤]';

  @override
  String get tuiEmojiComplacent => '[得意]';

  @override
  String get tuiEmojiSilly => '[傻了]';

  @override
  String get tuiEmojiLustful => '[色]';

  @override
  String get tuiEmojiGiggle => '[憨笑]';

  @override
  String get tuiEmojiKiss => '[亲亲]';

  @override
  String get tuiEmojiWail => '[大哭]';

  @override
  String get tuiEmojiTearsLaugh => '[哭笑]';

  @override
  String get tuiEmojiTrapped => '[困]';

  @override
  String get tuiEmojiMask => '[口罩]';

  @override
  String get tuiEmojiFear => '[恐惧]';

  @override
  String get tuiEmojiBareTeeth => '[龇牙]';

  @override
  String get tuiEmojiFlareUp => '[发怒]';

  @override
  String get tuiEmojiYawn => '[打哈欠]';

  @override
  String get tuiEmojiTact => '[机智]';

  @override
  String get tuiEmojiStareyes => '[星星眼]';

  @override
  String get tuiEmojiShutUp => '[闭嘴]';

  @override
  String get tuiEmojiSigh => '[叹气]';

  @override
  String get tuiEmojiHehe => '[呵呵]';

  @override
  String get tuiEmojiSilent => '[收声]';

  @override
  String get tuiEmojiSurprised => '[惊喜]';

  @override
  String get tuiEmojiAskance => '[白眼]';

  @override
  String get tuiEmojiOk => '[OK]';

  @override
  String get tuiEmojiShit => '[便便]';

  @override
  String get tuiEmojiMonster => '[怪兽]';

  @override
  String get tuiEmojiDaemon => '[恶魔]';

  @override
  String get tuiEmojiRage => '[恶魔怒]';

  @override
  String get tuiEmojiFool => '[衰]';

  @override
  String get tuiEmojiPig => '[猪]';

  @override
  String get tuiEmojiCow => '[牛]';

  @override
  String get tuiEmojiAi => '[AI]';

  @override
  String get tuiEmojiSkull => '[骷髅]';

  @override
  String get tuiEmojiBombs => '[炸弹]';

  @override
  String get tuiEmojiCoffee => '[咖啡]';

  @override
  String get tuiEmojiCake => '[蛋糕]';

  @override
  String get tuiEmojiBeer => '[啤酒]';

  @override
  String get tuiEmojiFlower => '[花]';

  @override
  String get tuiEmojiWatermelon => '[瓜]';

  @override
  String get tuiEmojiRich => '[壕]';

  @override
  String get tuiEmojiHeart => '[爱心]';

  @override
  String get tuiEmojiMoon => '[月亮]';

  @override
  String get tuiEmojiSun => '[太阳]';

  @override
  String get tuiEmojiStar => '[星星]';

  @override
  String get tuiEmojiRedPacket => '[红包]';

  @override
  String get tuiEmojiCelebrate => '[庆祝]';

  @override
  String get tuiEmojiBless => '[福]';

  @override
  String get tuiEmojiFortune => '[发]';

  @override
  String get tuiEmojiConvinced => '[服]';

  @override
  String get tuiEmojiProhibit => '[禁]';

  @override
  String get tuiEmoji666 => '[666]';

  @override
  String get tuiEmoji857 => '[857]';

  @override
  String get tuiEmojiKnife => '[刀]';

  @override
  String get tuiEmojiLike => '[赞]';

  @override
  String get sendMessage => '发送消息';

  @override
  String get quitGroup => '退出群聊';

  @override
  String get dismissGroup => '解散该群';

  @override
  String get groupNoticeEmpty => '暂无群公告';

  @override
  String get next => '下一步';

  @override
  String get agree => '同意';

  @override
  String get accept => '接受';

  @override
  String get refuse => '拒绝';

  @override
  String get noFriendApplicationList => '暂无新的联系人请求';

  @override
  String get noBlackList => '暂无黑名单用户';

  @override
  String get noGroupList => '暂无群聊';

  @override
  String get noGroupApplicationList => '暂无群申请';

  @override
  String get groupChatNotifications => '群聊通知';

  @override
  String get invite => '邀请';

  @override
  String get groupApplicationAllReadyBeenProcessed => '此邀请或者申请请求已经被处理。';

  @override
  String get accepted => '已同意';

  @override
  String get refused => '已拒绝';

  @override
  String get copy => '复制';

  @override
  String get recall => '撤回';

  @override
  String get forward => '转发';

  @override
  String get quote => '引用';

  @override
  String get searchUserID => '请输入 User ID 搜索用户';

  @override
  String get searchGroupID => '群 ID';

  @override
  String get searchGroupIDHint => '请输入群 ID 搜索群聊';

  @override
  String get addFailed => '添加失败';

  @override
  String get joinGroupFailed => '加入失败';

  @override
  String get alreadyFriend => '已经是好友';

  @override
  String get signature => '个性签名';

  @override
  String get fillInTheVerificationInformation => '填写验证信息';

  @override
  String get joinedGroupSuccessfully => '成功';

  @override
  String get contactAddedSuccessfully => '联系人添加成功';

  @override
  String get message => '消息';

  @override
  String get groupWork => '工作群';

  @override
  String get groupPublic => '公开群';

  @override
  String get groupMeeting => '会议群';

  @override
  String get groupCommunity => '社群';

  @override
  String get groupAVChatRoom => '直播群';

  @override
  String get groupAddAny => '自动审批';

  @override
  String get groupAddAuth => '管理员审批';

  @override
  String get groupAddForbid => '禁止加群';

  @override
  String get groupInviteForbid => '禁止邀请';

  @override
  String get groupOwner => '群主';

  @override
  String get member => '成员';

  @override
  String get admin => '管理员';

  @override
  String get modifyGroupName => '修改群名称';

  @override
  String get modifyGroupNickname => '修改群名片';

  @override
  String get chatBackground => '聊天背景';

  @override
  String get selectChatBackground => '选择聊天背景';

  @override
  String get chatBackgroundDefault => '默认';

  @override
  String get chatBackgroundCustom => '已设置';

  @override
  String get quitGroupTip => '您确认退出该群？';

  @override
  String get dismissGroupTip => '您确认解散该群？';

  @override
  String get clearMsgTip => '确认清除聊天记录？';

  @override
  String get muteAll => '全员禁言';

  @override
  String get addMuteMemberTip => '添加需要禁言的群成员';

  @override
  String get groupMuteTip => '全员禁言开启后，只允许群主和管理员发言。';

  @override
  String get deleteFriendTip => '确认删除联系人？';

  @override
  String get remarkEdit => '修改备注';

  @override
  String get detail => '详情';

  @override
  String get setAdmin => '设置为管理员';

  @override
  String get cancelAdmin => '取消管理员';

  @override
  String get deleteGroupMemberTip => '确认删除群成员？';

  @override
  String get settingSuccess => '设置成功！';

  @override
  String get settingFail => '设置失败！';

  @override
  String get noMore => '没有更多了';

  @override
  String get sayTimeShort => '说话时间太短';

  @override
  String get recordLimitTips => '已达到最大语音长度';

  @override
  String get chooseAvatar => '选择头像';

  @override
  String get inputGroupName => '请输入群名称';

  @override
  String get error => '错误';

  @override
  String maxCountFile(Object maxCount) {
    return '最多只能选择 $maxCount 个文件';
  }

  @override
  String get groupIntroDeleted => '删除了群简介';

  @override
  String get groupJoinForbidden => '禁止加群';

  @override
  String get groupJoinApproval => '管理员审批';

  @override
  String get groupJoinFree => '自由加群';

  @override
  String get groupInviteForbidden => '禁止邀请';

  @override
  String get groupInviteApproval => '管理员审批';

  @override
  String get groupInviteFree => '自由邀请';

  @override
  String get friendLimit => '您的好友数已达系统上限';

  @override
  String get otherFriendLimit => '对方的好友数已达系统上限';

  @override
  String get inBlacklist => '被加好友在自己的黑名单中';

  @override
  String get setInBlacklist => '您已被被对方设置为黑名单';

  @override
  String get forbidAddFriend => '对方已禁止加好友';

  @override
  String get waitAgreeFriend => '等待好友审核同意';

  @override
  String get userNotExist => '该用户不存在';

  @override
  String get addGroupPermissionDeny => '禁止加群';

  @override
  String get addGroupAlreadyMember => '已经是群成员';

  @override
  String get addGroupNotFound => '群组不存在';

  @override
  String get addGroupFullMember => '群已满员';

  @override
  String chatRecords(Object count) {
    return '$count条相关记录';
  }

  @override
  String get addRule => '加我为好友时';

  @override
  String get allowAny => '允许任何人';

  @override
  String get denyAny => '拒绝任何人';

  @override
  String get needConfirm => '需要验证';

  @override
  String get noSignature => '暂无个性签名';

  @override
  String get gender => '性别';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get birthday => '生日';

  @override
  String get setNickname => '修改昵称';

  @override
  String get setSignature => '修改个性签名';

  @override
  String get messageNum => '条';

  @override
  String get draft => '[草稿]';

  @override
  String get sendMessageFail => '发送失败';

  @override
  String get resendTips => '确定重发吗？';

  @override
  String get stopCallTip => '通话时长';

  @override
  String get startCall => '发起通话';

  @override
  String get acceptCall => '已接听';

  @override
  String get groupCallSend => '发起了群通话';

  @override
  String get groupCallEnd => '通话结束';

  @override
  String get groupCallNoAnswer => '未接听';

  @override
  String get groupCallReject => '拒绝群通话';

  @override
  String get groupCallAccept => '接听';

  @override
  String get groupCallConfirmSwitchToAudio => '同意视频转语音';

  @override
  String get unknownCall => '未知通话';

  @override
  String get join => '加入';

  @override
  String peopleOnCall(Object number) {
    return '$number 人正在通话中';
  }

  @override
  String get groupReadBy => '已读';

  @override
  String get groupDeliveredTo => '未读';

  @override
  String get readReceiptAllRead => '全部已读';

  @override
  String readReceiptNPersonRead(int count) {
    return '$count人已读';
  }

  @override
  String get messageReadReceipt => '消息阅读状态';

  @override
  String get messageReadReceiptEnabledDesc =>
      '关闭后，您收发的消息均不带消息阅读状态，您将无法看到对方是否已读，同时对方也无法看到您是否已读。';

  @override
  String get messageReadReceiptDisabledDesc =>
      '开启后，您在群聊中收发的消息均带有消息阅读状态，并且可以看到对方是否已读。与您单聊的好友若也开启了消息阅读状态，您与好友在单聊中收发的消息也将带有消息阅读状态。';

  @override
  String get markAsRead => '标为已读';

  @override
  String get markAsUnread => '标为未读';

  @override
  String get multiSelect => '多选';

  @override
  String get postEmojis => '贴表情';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get allEmojis => '全部';

  @override
  String get selectChat => '选择会话';

  @override
  String selectedCount(int count) {
    return '已选择 $count 条';
  }

  @override
  String get forwardIndividually => '逐条转发';

  @override
  String get forwardMerged => '合并转发';

  @override
  String get groupChatHistory => '群聊的聊天记录';

  @override
  String c2cChatHistoryFormat(String name) {
    return '$name的聊天记录';
  }

  @override
  String chatHistoryForSomebodyFormat(String name1, String name2) {
    return '$name1和$name2的聊天记录';
  }

  @override
  String get forwardCompatibleText => '请升级到最新版本查看聊天记录';

  @override
  String get forwardFailedMessageTip => '发送失败消息不支持转发！';

  @override
  String get forwardSeparateLimitTip => '转发消息过多，暂不支持逐条转发';

  @override
  String get deleteMessagesConfirmTip => '确定删除已选消息？';

  @override
  String get deleteConversationTip => '确定删除该会话？';

  @override
  String get conversationListAtAll => '[@所有人]';

  @override
  String get conversationListAtMe => '[有人@我]';

  @override
  String get messageInputAllMembers => '所有人';

  @override
  String get selectMentionMember => '选择提醒的人';

  @override
  String get tapToRemove => '点击移除';

  @override
  String get messageTypeSecurityStrike => '涉及敏感内容';

  @override
  String get convertToText => '转文字';

  @override
  String get convertToTextFailed => '转换失败';

  @override
  String get hide => '隐藏';

  @override
  String get translate => '翻译';

  @override
  String get translateFailed => '翻译失败';

  @override
  String get translateDefaultTips => '由腾讯云 IM 提供翻译支持';

  @override
  String get translating => '翻译中...';

  @override
  String get translateTargetLanguage => '翻译目标语言';

  @override
  String get backToLatest => '回到最新位置';

  @override
  String newMessageCount(int count) {
    return '$count 条新消息';
  }

  @override
  String get holdToTalk => '按住说话';

  @override
  String get sendMessageOrHoldToTalk => '发消息或按住说话...';

  @override
  String get releaseToSend => '松手发送';

  @override
  String get releaseToCancel => '松手取消';

  @override
  String recordCountdownTips(int seconds) {
    return '${seconds}s 后将停止录音';
  }

  @override
  String get backToQuotePosition => '回到引用位置';

  @override
  String get quotedMessageRevoked => '引用内容已撤回';

  @override
  String get quotedMessageNotFound => '无法找到引用内容';

  @override
  String get quotedOriginalMessageUnreachable => '无法定位到原消息';

  @override
  String reactionUserSummary(String name, int totalCount, int othersCount) {
    return '$name等$totalCount人';
  }

  @override
  String get messageTypeMerged => '[合并消息]';

  @override
  String get messageTypeUnknown => '[消息]';

  @override
  String get releaseToConvert => '松手转文字';

  @override
  String get voiceToTextFailed => '未识别到文字内容';

  @override
  String get sendOriginalVoice => '发送原语音';

  @override
  String get addMembers => '添加成员';

  @override
  String get album => '相册';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get takeAPhoto => '拍照';

  @override
  String get callRejectCaller => '对方已拒绝';

  @override
  String get callRejectCallee => '已拒绝';

  @override
  String get callCancelCaller => '已取消';

  @override
  String get callCancelCallee => '对方已取消';

  @override
  String get callTimeoutCaller => '对方无应答';

  @override
  String get callTimeoutCallee => '超时无应答';

  @override
  String get callLineBusyCaller => '对方忙线中';

  @override
  String get callLineBusyCallee => '忙线未接听';

  @override
  String get callingSwitchToAudio => '视频转语音';

  @override
  String get callingSwitchToAudioAccept => '确认视频转语音';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class ChatLocalizationsZhHant extends ChatLocalizationsZh {
  ChatLocalizationsZhHant() : super('zh_Hant');

  @override
  String get voiceTranslate => '翻譯';

  @override
  String get voiceCancelTranslation => '取消翻譯';

  @override
  String get voiceSwitchLanguage => '切換語言';

  @override
  String get voiceReadAloud => '朗讀';

  @override
  String get voiceStopReadAloud => '停止';

  @override
  String get voiceSwitchLanguageSheetTitle => '切換翻譯語言';

  @override
  String get voiceTranslateFailed => '翻譯失敗';

  @override
  String get voiceTtsFailed => '朗讀失敗';

  @override
  String get voiceMessageSettings => '語音訊息設定';

  @override
  String get voiceClone => '音色複製';

  @override
  String get voiceSelect => '音色選擇';

  @override
  String get voiceCloneTip => '請錄製一段 10-18 秒的語音，用於複製您的專屬音色';

  @override
  String get voiceCloneReadingTipTitle => '建議朗讀以下文字：';

  @override
  String get voiceCloneSampleText =>
      '大家好，我是您的專屬語音助手，很高興為您服務。今天天氣真不錯，希望您有一個愉快的心情。';

  @override
  String get voiceCloneStartRecord => '點擊開始錄音';

  @override
  String get voiceCloneStopRecord => '點擊停止錄音';

  @override
  String get voiceCloneRecordDone => '錄音完成';

  @override
  String get voiceCloneNameHint => '請輸入音色名稱（可選）';

  @override
  String get voiceCloneSubmit => '提交複製';

  @override
  String get voiceCloneAuthTip =>
      '建立聲音需要取得您的人聲音訊。該敏感資訊僅用於目前玩法使用，如不同意授權，可能無法使用音色複製功能。點擊錄製代表同意授權。';

  @override
  String get voiceCloneSuccessTitle => '複製成功';

  @override
  String get voiceCloneSuccessMessage => '您的專屬音色已建立成功！';

  @override
  String get voiceCloneFailed => '音色複製失敗';

  @override
  String get voiceCloneEmptyRecord => '請先錄製一段語音';

  @override
  String get voiceCloneTooShortTitle => '錄音時間太短';

  @override
  String get voiceCloneTooShortMessage => '請錄製至少3秒的語音';

  @override
  String get voiceCloneDefaultName => '我的音色';

  @override
  String get voiceSelectDefaultGroup => '預設音色';

  @override
  String get voiceSelectCustomGroup => '自訂音色';

  @override
  String get voiceSelectEmptyCustom => '暫無自訂音色';

  @override
  String get voiceCustomBadge => '自訂';

  @override
  String get voiceDelete => '刪除';

  @override
  String get voiceConfirm => '確定';

  @override
  String get voiceDeleteFailed => '刪除失敗';

  @override
  String get voiceDefault => '預設';

  @override
  String get voiceXiaoxuMale => '小旭（男）';

  @override
  String get voiceXiaomeiFemale => '小美（女）';

  @override
  String get voiceXiaoxinFemale => '小新（女）';

  @override
  String get voiceXiaoyueFemale => '小月（女）';

  @override
  String get listenFromHere => '從目前聽';

  @override
  String get listenSelfSpeaker => '我';

  @override
  String listenSays(String speaker) {
    return '$speaker說：';
  }

  @override
  String listenSentImage(String speaker) {
    return '$speaker傳送了圖片';
  }

  @override
  String listenSentVideo(String speaker) {
    return '$speaker傳送了影片';
  }

  @override
  String listenSentFile(String speaker) {
    return '$speaker傳送了檔案';
  }

  @override
  String listenSentMerged(String speaker, String title) {
    return '$speaker傳送了$title';
  }

  @override
  String get login => '登录';

  @override
  String get logout => '登出';

  @override
  String get chat => '訊息';

  @override
  String get me => '我的';

  @override
  String get theme => '主題';

  @override
  String get themeLight => '明亮';

  @override
  String get themeDark => '暗黑';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get color => '顏色';

  @override
  String get themeColor => '主題顏色';

  @override
  String get selectThemeColor => '選擇主題顏色';

  @override
  String get colorHue => '色相';

  @override
  String get colorSaturation => '飽和度';

  @override
  String get colorBrightness => '亮度';

  @override
  String get colorHex => '色值';

  @override
  String get reset => '重設';

  @override
  String get language => '語言';

  @override
  String get languageZh => '簡體中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageAr => 'اَلْعَرَبِيَّة';

  @override
  String get contact => '通訊錄';

  @override
  String get messageRevokedBySelf => '你撤回了一條消息';

  @override
  String get messageRevokedByOther => '對方撤回了一條消息';

  @override
  String messageRevokedByUser(Object user) {
    return '$user 撤回了一條消息';
  }

  @override
  String groupMemberJoined(Object user) {
    return '$user 加入了群組';
  }

  @override
  String groupMemberInvited(Object operator, Object users) {
    return '$operator 邀請 $users 加入了群組';
  }

  @override
  String groupMemberQuit(Object user) {
    return '$user 退出了群組';
  }

  @override
  String groupMemberKicked(Object operator, Object users) {
    return '$operator 將 $users 踢出了群組';
  }

  @override
  String groupAdminSet(Object users) {
    return '$users 被設置為管理員';
  }

  @override
  String groupAdminCancelled(Object users) {
    return '$users 被取消了管理員資格';
  }

  @override
  String groupMessagePinned(Object user) {
    return '$user 置頂了一條消息';
  }

  @override
  String groupMessageUnpinned(Object user) {
    return '$user 取消了一條消息置頂';
  }

  @override
  String get you => '你';

  @override
  String get muted => '被禁言';

  @override
  String get unmuted => '被解除禁言';

  @override
  String get day => '天';

  @override
  String get hour => '小時';

  @override
  String get min => '分鐘';

  @override
  String get second => '秒';

  @override
  String get messageTypeImage => '[圖片]';

  @override
  String get messageTypeVoice => '[語音]';

  @override
  String get messageTypeFile => '[文件]';

  @override
  String get messageTypeVideo => '[視頻]';

  @override
  String get messageTypeSticker => '[動畫表情]';

  @override
  String get messageTypeCustom => '[自定義消息]';

  @override
  String get groupNameChangedTo => '修改群名稱為';

  @override
  String get groupIntroChangedTo => '修改群簡介為';

  @override
  String get groupNoticeChangedTo => '修改群公告為';

  @override
  String get groupNoticeDeleted => '刪除了群公告';

  @override
  String get groupAvatarChanged => '修改了群頭像';

  @override
  String get groupOwnerTransferredTo => '將群主轉讓給';

  @override
  String get groupMuteAllEnabled => '開啟了全員禁言';

  @override
  String get groupMuteAllDisabled => '關閉了全員禁言';

  @override
  String get unknown => '未知';

  @override
  String get groupJoinMethodChangedTo => '修改了入群方式為';

  @override
  String get groupInviteMethodChangedTo => '修改了邀請方式為';

  @override
  String get weekdaySunday => '星期日';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get yesterday => '昨天';

  @override
  String dateMonthDayFormat(int month, int day) {
    return '$month月$day日';
  }

  @override
  String dateYearMonthDayFormat(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get userID => '用戶ID';

  @override
  String get groupIDLabel => '群 ID';

  @override
  String get userIDLabel => '用戶 ID';

  @override
  String get file => '文件';

  @override
  String get recordAVideo => '錄製';

  @override
  String get audioCall => '語音通話';

  @override
  String get videoCall => '視訊通話';

  @override
  String get send => '傳送';

  @override
  String get more => '更多';

  @override
  String get delete => '刪除';

  @override
  String get clearMessage => '清空聊天記錄';

  @override
  String get pin => '置頂聊天';

  @override
  String get unpin => '取消置頂';

  @override
  String get startConversation => '發起單聊';

  @override
  String get createGroupChat => '建立群聊';

  @override
  String get addFriend => '新增好友';

  @override
  String get addGroup => '加群組';

  @override
  String get addContact => '添加聯繫人';

  @override
  String get joinGroup => '加入群聊';

  @override
  String get createGroupTips => '創建群組';

  @override
  String get createCommunity => '創建社群';

  @override
  String get groupIDInvalid => '群組 ID 非法，請檢查群組 ID 是否填寫正確。';

  @override
  String get productDocumentation => '查看產品文檔';

  @override
  String get create => '創建';

  @override
  String get groupName => '群名稱';

  @override
  String get groupIDOption => '群ID (選填)';

  @override
  String get groupFaceUrl => '群頭像';

  @override
  String get groupMemberSelected => '已選擇的群成員';

  @override
  String get groupWorkType => '好友工作群(Work)';

  @override
  String get groupPublicType => '陌生人社交群(Public)';

  @override
  String get groupMeetingType => '臨時會議群(Meeting)';

  @override
  String get groupCommunityType => '社群(Community)';

  @override
  String get groupWorkDesc =>
      '好友工作群(Work）：類似普通微信群，創建後僅支持已在群內的好友邀請加群，且無需被邀請方同意或群主審批。';

  @override
  String get groupPublicDesc =>
      '陌生人社交群(Public）：類似 QQ 群，創建後群主可以指定群管理員，用戶搜索群 ID 發起加群申請後，需要群主或管理員審批通過才能入群。';

  @override
  String get groupMeetingDesc =>
      '臨時會議群(Meeting）：創建後可以隨意進出，且支持查看入群前消息；適用於音視頻會議場景、在線教育場景等與實時音視頻產品結合的場景。';

  @override
  String get groupCommunityDesc =>
      '社群(Community)：創建後可以隨意進出，最多支持100000人，支持歷史消息存儲，用戶搜索群 ID 發起加群申請後，無需管理員審批即可進群。';

  @override
  String get groupDetail => '群聊詳情';

  @override
  String get transferGroupOwner => '轉讓群主';

  @override
  String get publicGroup => '公開群';

  @override
  String get groupOfAnnouncement => '群通知';

  @override
  String get groupManagement => '管理群組';

  @override
  String get groupType => '群組類型';

  @override
  String get addGroupWay => '主動加群方式';

  @override
  String get inviteGroupType => '邀請進群方式';

  @override
  String get myAliasInGroup => '我的群名片';

  @override
  String get doNotDisturb => '消息免打擾';

  @override
  String get groupMember => '群成員';

  @override
  String get profileRemark => '備註名';

  @override
  String get groupEdit => '編輯';

  @override
  String get blackList => '黑名單';

  @override
  String get profileBlack => '加入黑名單';

  @override
  String get deleteFriend => '刪除好友';

  @override
  String get search => '搜尋';

  @override
  String get chatHistory => '聊天記錄';

  @override
  String get groups => '群組';

  @override
  String get newFriend => '新的聯繫人';

  @override
  String get myGroups => '我的群聊';

  @override
  String get contactInfo => '詳細資料';

  @override
  String get tuiEmojiSmile => '[微笑]';

  @override
  String get tuiEmojiExpect => '[期待]';

  @override
  String get tuiEmojiBlink => '[眨眼]';

  @override
  String get tuiEmojiGuffaw => '[大笑]';

  @override
  String get tuiEmojiKindSmile => '[姨母笑]';

  @override
  String get tuiEmojiHaha => '[哈哈哈]';

  @override
  String get tuiEmojiCheerful => '[愉快]';

  @override
  String get tuiEmojiSpeechless => '[無語]';

  @override
  String get tuiEmojiAmazed => '[驚訝]';

  @override
  String get tuiEmojiSorrow => '[悲傷]';

  @override
  String get tuiEmojiComplacent => '[得意]';

  @override
  String get tuiEmojiSilly => '[傻了]';

  @override
  String get tuiEmojiLustful => '[色]';

  @override
  String get tuiEmojiGiggle => '[憨笑]';

  @override
  String get tuiEmojiKiss => '[親親]';

  @override
  String get tuiEmojiWail => '[大哭]';

  @override
  String get tuiEmojiTearsLaugh => '[哭笑]';

  @override
  String get tuiEmojiTrapped => '[困]';

  @override
  String get tuiEmojiMask => '[口罩]';

  @override
  String get tuiEmojiFear => '[恐懼]';

  @override
  String get tuiEmojiBareTeeth => '[齜牙]';

  @override
  String get tuiEmojiFlareUp => '[發怒]';

  @override
  String get tuiEmojiYawn => '[打哈欠]';

  @override
  String get tuiEmojiTact => '[機智]';

  @override
  String get tuiEmojiStareyes => '[星星眼]';

  @override
  String get tuiEmojiShutUp => '[閉嘴]';

  @override
  String get tuiEmojiSigh => '[嘆氣]';

  @override
  String get tuiEmojiHehe => '[呵呵]';

  @override
  String get tuiEmojiSilent => '[收聲]';

  @override
  String get tuiEmojiSurprised => '[驚喜]';

  @override
  String get tuiEmojiAskance => '[白眼]';

  @override
  String get tuiEmojiOk => '[OK]';

  @override
  String get tuiEmojiShit => '[便便]';

  @override
  String get tuiEmojiMonster => '[怪獸]';

  @override
  String get tuiEmojiDaemon => '[惡魔]';

  @override
  String get tuiEmojiRage => '[惡魔怒]';

  @override
  String get tuiEmojiFool => '[衰]';

  @override
  String get tuiEmojiPig => '[豬]';

  @override
  String get tuiEmojiCow => '[牛]';

  @override
  String get tuiEmojiAi => '[AI]';

  @override
  String get tuiEmojiSkull => '[骷髏]';

  @override
  String get tuiEmojiBombs => '[炸彈]';

  @override
  String get tuiEmojiCoffee => '[咖啡]';

  @override
  String get tuiEmojiCake => '[蛋糕]';

  @override
  String get tuiEmojiBeer => '[啤酒]';

  @override
  String get tuiEmojiFlower => '[花]';

  @override
  String get tuiEmojiWatermelon => '[瓜]';

  @override
  String get tuiEmojiRich => '[壕]';

  @override
  String get tuiEmojiHeart => '[愛心]';

  @override
  String get tuiEmojiMoon => '[月亮]';

  @override
  String get tuiEmojiSun => '[太陽]';

  @override
  String get tuiEmojiStar => '[星星]';

  @override
  String get tuiEmojiRedPacket => '[红包]';

  @override
  String get tuiEmojiCelebrate => '[慶祝]';

  @override
  String get tuiEmojiBless => '[福]';

  @override
  String get tuiEmojiFortune => '[發]';

  @override
  String get tuiEmojiConvinced => '[服]';

  @override
  String get tuiEmojiProhibit => '[禁]';

  @override
  String get tuiEmoji666 => '[666]';

  @override
  String get tuiEmoji857 => '[857]';

  @override
  String get tuiEmojiKnife => '[刀]';

  @override
  String get tuiEmojiLike => '[讚]';

  @override
  String get sendMessage => '發送消息';

  @override
  String get quitGroup => '退出群聊';

  @override
  String get dismissGroup => '解散該群';

  @override
  String get groupNoticeEmpty => '暫無群公告';

  @override
  String get next => '下一步';

  @override
  String get agree => '接受';

  @override
  String get accept => '接受';

  @override
  String get refuse => '拒絕';

  @override
  String get noFriendApplicationList => '暫無新的聯絡人請求';

  @override
  String get noBlackList => '暫無黑名單用戶';

  @override
  String get noGroupList => '暫無群聊';

  @override
  String get noGroupApplicationList => '暫無群申請';

  @override
  String get groupChatNotifications => '群對話通知';

  @override
  String get invite => '邀請';

  @override
  String get groupApplicationAllReadyBeenProcessed => '此邀請或者申請請求已經被處理。';

  @override
  String get accepted => '已同意';

  @override
  String get refused => '已拒絕';

  @override
  String get copy => '复制';

  @override
  String get recall => '撤回';

  @override
  String get forward => '轉發';

  @override
  String get quote => '引用';

  @override
  String get searchUserID => '請輸入用戶 ID 搜尋用戶';

  @override
  String get searchGroupID => '群 ID';

  @override
  String get searchGroupIDHint => '請輸入群組 ID 搜尋群聊';

  @override
  String get addFailed => '添加失敗';

  @override
  String get joinGroupFailed => '加入失敗';

  @override
  String get alreadyFriend => '已經是好友';

  @override
  String get signature => '個性簽名';

  @override
  String get fillInTheVerificationInformation => '填寫驗證資訊';

  @override
  String get joinedGroupSuccessfully => '成功';

  @override
  String get contactAddedSuccessfully => '成功加聯絡人';

  @override
  String get message => '訊息';

  @override
  String get groupWork => '工作群';

  @override
  String get groupPublic => '公開群';

  @override
  String get groupMeeting => '會議群';

  @override
  String get groupCommunity => '社群';

  @override
  String get groupAVChatRoom => '直播群';

  @override
  String get groupAddAny => '自動審批';

  @override
  String get groupAddAuth => '管理員審批';

  @override
  String get groupAddForbid => '禁止加群';

  @override
  String get groupInviteForbid => '禁止邀請';

  @override
  String get groupOwner => '群主';

  @override
  String get member => '成員';

  @override
  String get admin => '管理員';

  @override
  String get modifyGroupName => '修改群名稱';

  @override
  String get modifyGroupNickname => '修改群名片';

  @override
  String get chatBackground => '聊天背景';

  @override
  String get selectChatBackground => '選擇聊天背景';

  @override
  String get chatBackgroundDefault => '預設';

  @override
  String get chatBackgroundCustom => '已設定';

  @override
  String get quitGroupTip => '您確認退出該群？';

  @override
  String get dismissGroupTip => '您確認解散該群？';

  @override
  String get clearMsgTip => '確認清除聊天記錄？';

  @override
  String get muteAll => '全員禁言';

  @override
  String get addMuteMemberTip => '添加需要禁言的群成員';

  @override
  String get groupMuteTip => '全員禁言開啟後，只允許群主和管理員發言。';

  @override
  String get deleteFriendTip => '確認刪除聯繫人？';

  @override
  String get remarkEdit => '修改備註';

  @override
  String get detail => '詳情';

  @override
  String get setAdmin => '設置為管理員';

  @override
  String get cancelAdmin => '取消管理員';

  @override
  String get deleteGroupMemberTip => '確認刪除群組成員？';

  @override
  String get settingSuccess => '設置成功！';

  @override
  String get settingFail => '設置失敗！';

  @override
  String get noMore => '沒有更多了';

  @override
  String get sayTimeShort => '說話時間太短';

  @override
  String get recordLimitTips => '已達到最大語音長度';

  @override
  String get chooseAvatar => '選擇頭像';

  @override
  String get inputGroupName => '請輸入群組名稱';

  @override
  String get error => '錯誤';

  @override
  String maxCountFile(Object maxCount) {
    return '最多只能選擇 $maxCount 個文件';
  }

  @override
  String get groupIntroDeleted => '刪除了群簡介';

  @override
  String get groupJoinForbidden => '禁止加群';

  @override
  String get groupJoinApproval => '管理員審批';

  @override
  String get groupJoinFree => '自由加群';

  @override
  String get groupInviteForbidden => '禁止邀請';

  @override
  String get groupInviteApproval => '管理員審批';

  @override
  String get groupInviteFree => '自由邀請';

  @override
  String get friendLimit => '您的好友數已達系統上限';

  @override
  String get otherFriendLimit => '對方的好友數已達系統上限';

  @override
  String get inBlacklist => '被加好友在自己的黑名單中';

  @override
  String get setInBlacklist => '您已被被對方設置為黑名單';

  @override
  String get forbidAddFriend => '對方已禁止加好友';

  @override
  String get waitAgreeFriend => '等待好友審核同意';

  @override
  String get userNotExist => '該用戶不存在';

  @override
  String get addGroupPermissionDeny => '禁止加群';

  @override
  String get addGroupAlreadyMember => '已經是群成員';

  @override
  String get addGroupNotFound => '群組不存在';

  @override
  String get addGroupFullMember => '群已滿員';

  @override
  String chatRecords(Object count) {
    return '$count條相關記錄';
  }

  @override
  String get addRule => '加我為好友時';

  @override
  String get allowAny => '允許任何人';

  @override
  String get denyAny => '拒絕任何人';

  @override
  String get needConfirm => '需要驗證';

  @override
  String get noSignature => '暫無個性簽名';

  @override
  String get gender => '性別';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get birthday => '生日';

  @override
  String get setNickname => '修改暱稱';

  @override
  String get setSignature => '修改個性簽名';

  @override
  String get messageNum => '條';

  @override
  String get draft => '[草稿]';

  @override
  String get sendMessageFail => '發送失敗';

  @override
  String get resendTips => '確定重發嗎？';

  @override
  String get stopCallTip => '通話時長';

  @override
  String get startCall => '發起通話';

  @override
  String get acceptCall => '已接聽';

  @override
  String get groupCallSend => '發起了群通話';

  @override
  String get groupCallEnd => '通話結束';

  @override
  String get groupCallNoAnswer => '未接聽';

  @override
  String get groupCallReject => '拒絕群通話';

  @override
  String get groupCallAccept => '接聽';

  @override
  String get groupCallConfirmSwitchToAudio => '同意視頻轉語音';

  @override
  String get unknownCall => '未知通話';

  @override
  String get join => '加入';

  @override
  String peopleOnCall(Object number) {
    return '$number人正在通話中';
  }

  @override
  String get groupReadBy => '已讀';

  @override
  String get groupDeliveredTo => '未讀';

  @override
  String get readReceiptAllRead => '全部已讀';

  @override
  String readReceiptNPersonRead(int count) {
    return '$count人已讀';
  }

  @override
  String get messageReadReceipt => '消息閱讀狀態';

  @override
  String get messageReadReceiptEnabledDesc =>
      '關閉後，您收發的消息均不帶消息閱讀狀態，您將無法看到對方是否已讀，同時對方也無法看到您是否已讀。';

  @override
  String get messageReadReceiptDisabledDesc =>
      '開啟後，您在群聊中收發的消息均帶有消息閱讀狀態，並且可以看到對方是否已讀。與您單聊的好友若也開啟了消息閱讀狀態，您與好友在單聊中收發的消息也將帶有消息閱讀狀態。';

  @override
  String get markAsRead => '標為已讀';

  @override
  String get markAsUnread => '標為未讀';

  @override
  String get multiSelect => '多選';

  @override
  String get postEmojis => '貼表情';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get allEmojis => '全部';

  @override
  String get selectChat => '選擇會話';

  @override
  String selectedCount(int count) {
    return '已選擇 $count 條';
  }

  @override
  String get forwardIndividually => '逐條轉發';

  @override
  String get forwardMerged => '合併轉發';

  @override
  String get groupChatHistory => '群聊的聊天記錄';

  @override
  String c2cChatHistoryFormat(String name) {
    return '$name的聊天記錄';
  }

  @override
  String chatHistoryForSomebodyFormat(String name1, String name2) {
    return '$name1和$name2的聊天記錄';
  }

  @override
  String get forwardCompatibleText => '請升級到最新版本查看聊天記錄';

  @override
  String get forwardFailedMessageTip => '發送失敗訊息不支援轉發！';

  @override
  String get forwardSeparateLimitTip => '轉發訊息過多，暫不支援逐條轉發';

  @override
  String get deleteMessagesConfirmTip => '確定刪除已選消息？';

  @override
  String get deleteConversationTip => '確定刪除該會話？';

  @override
  String get conversationListAtAll => '[@所有人]';

  @override
  String get conversationListAtMe => '[有人@我]';

  @override
  String get messageInputAllMembers => '所有人';

  @override
  String get selectMentionMember => '選擇提醒的人';

  @override
  String get tapToRemove => '點擊移除';

  @override
  String get messageTypeSecurityStrike => '涉及敏感內容';

  @override
  String get convertToText => '轉文字';

  @override
  String get convertToTextFailed => '轉換失敗';

  @override
  String get hide => '隱藏';

  @override
  String get translate => '翻譯';

  @override
  String get translateFailed => '翻譯失敗';

  @override
  String get translateDefaultTips => '由騰訊雲 IM 提供翻譯支持';

  @override
  String get translating => '翻譯中...';

  @override
  String get translateTargetLanguage => '翻譯目標語言';

  @override
  String get backToLatest => '回到最新位置';

  @override
  String newMessageCount(int count) {
    return '$count 條新訊息';
  }

  @override
  String get holdToTalk => '按住說話';

  @override
  String get sendMessageOrHoldToTalk => '發訊息或按住說話...';

  @override
  String get releaseToSend => '鬆手發送';

  @override
  String get releaseToCancel => '鬆手取消';

  @override
  String recordCountdownTips(int seconds) {
    return '${seconds}s 後將停止錄音';
  }

  @override
  String get backToQuotePosition => '回到引用位置';

  @override
  String get quotedMessageRevoked => '引用內容已撤回';

  @override
  String get quotedMessageNotFound => '無法找到引用內容';

  @override
  String get quotedOriginalMessageUnreachable => '無法定位到原消息';

  @override
  String reactionUserSummary(String name, int totalCount, int othersCount) {
    return '$name等$totalCount人';
  }

  @override
  String get messageTypeMerged => '[合併消息]';

  @override
  String get messageTypeUnknown => '[消息]';

  @override
  String get releaseToConvert => '鬆手轉文字';

  @override
  String get voiceToTextFailed => '未識別到文字內容';

  @override
  String get sendOriginalVoice => '發送原語音';

  @override
  String get addMembers => '加成員';

  @override
  String get album => '相册';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確定';

  @override
  String get takeAPhoto => '拍照';

  @override
  String get callRejectCaller => '對方已拒絕';

  @override
  String get callRejectCallee => '已拒絕';

  @override
  String get callCancelCaller => '已取消';

  @override
  String get callCancelCallee => '對方已取消';

  @override
  String get callTimeoutCaller => '對方無應答';

  @override
  String get callTimeoutCallee => '超時無應答';

  @override
  String get callLineBusyCaller => '對方忙線中';

  @override
  String get callLineBusyCallee => '忙線未接聽';

  @override
  String get callingSwitchToAudio => '視頻轉語音';

  @override
  String get callingSwitchToAudioAccept => '確認視頻轉語音';
}
