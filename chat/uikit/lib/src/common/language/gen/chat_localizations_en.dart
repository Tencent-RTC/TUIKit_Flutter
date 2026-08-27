// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'chat_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ChatLocalizationsEn extends ChatLocalizations {
  ChatLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get voiceTranslate => 'Translate';

  @override
  String get voiceCancelTranslation => 'Undo Translation';

  @override
  String get voiceSwitchLanguage => 'Switch Language';

  @override
  String get voiceReadAloud => 'Read Aloud';

  @override
  String get voiceStopReadAloud => 'Stop';

  @override
  String get voiceSwitchLanguageSheetTitle => 'Switch Translation Language';

  @override
  String get voiceTranslateFailed => 'Translation failed';

  @override
  String get voiceTtsFailed => 'Playback failed';

  @override
  String get voiceMessageSettings => 'Voice Message Settings';

  @override
  String get voiceClone => 'Voice Clone';

  @override
  String get voiceSelect => 'Voice Selection';

  @override
  String get voiceCloneTip =>
      'Record a 10-18 second voice clip to clone your exclusive voice.';

  @override
  String get voiceCloneReadingTipTitle => 'Suggested text to read:';

  @override
  String get voiceCloneSampleText =>
      'Hello everyone, I am your exclusive voice assistant, glad to be at your service. The weather is really nice today, hope you have a pleasant mood.';

  @override
  String get voiceCloneStartRecord => 'Tap to start recording';

  @override
  String get voiceCloneStopRecord => 'Tap to stop recording';

  @override
  String get voiceCloneRecordDone => 'Recording complete';

  @override
  String get voiceCloneNameHint => 'Enter a voice name (optional)';

  @override
  String get voiceCloneSubmit => 'Submit Clone';

  @override
  String get voiceCloneAuthTip =>
      'Creating a voice requires capturing your human voice audio. This sensitive information is only used for the current feature. If you do not agree to the authorization, you may not be able to use voice cloning. Recording implies consent to the authorization.';

  @override
  String get voiceCloneSuccessTitle => 'Clone Succeeded';

  @override
  String get voiceCloneSuccessMessage =>
      'Your exclusive voice has been created successfully!';

  @override
  String get voiceCloneFailed => 'Voice clone failed';

  @override
  String get voiceCloneEmptyRecord => 'Please record a voice clip first';

  @override
  String get voiceCloneTooShortTitle => 'Recording too short';

  @override
  String get voiceCloneTooShortMessage => 'Please record at least 3 seconds';

  @override
  String get voiceCloneDefaultName => 'My Voice';

  @override
  String get voiceSelectDefaultGroup => 'Default Voices';

  @override
  String get voiceSelectCustomGroup => 'Custom Voices';

  @override
  String get voiceSelectEmptyCustom => 'No custom voices yet';

  @override
  String get voiceCustomBadge => 'Custom';

  @override
  String get voiceDelete => 'Delete';

  @override
  String get voiceConfirm => 'OK';

  @override
  String get voiceDeleteFailed => 'Delete failed';

  @override
  String get voiceDefault => 'Default';

  @override
  String get voiceXiaoxuMale => 'Xiaoxu (Male)';

  @override
  String get voiceXiaomeiFemale => 'Xiaomei (Female)';

  @override
  String get voiceXiaoxinFemale => 'Xiaoxin (Female)';

  @override
  String get voiceXiaoyueFemale => 'Xiaoyue (Female)';

  @override
  String get listenFromHere => 'Listen';

  @override
  String get listenSelfSpeaker => 'I';

  @override
  String listenSays(String speaker) {
    return '$speaker said: ';
  }

  @override
  String listenSentImage(String speaker) {
    return '$speaker sent an image';
  }

  @override
  String listenSentVideo(String speaker) {
    return '$speaker sent a video';
  }

  @override
  String listenSentFile(String speaker) {
    return '$speaker sent a file';
  }

  @override
  String listenSentMerged(String speaker, String title) {
    return '$speaker sent: $title';
  }

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get chat => 'Messages';

  @override
  String get me => 'Me';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get followSystem => 'Follow System';

  @override
  String get color => 'Color';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get selectThemeColor => 'Select Theme Color';

  @override
  String get colorHue => 'Hue';

  @override
  String get colorSaturation => 'Saturation';

  @override
  String get colorBrightness => 'Brightness';

  @override
  String get colorHex => 'Hex';

  @override
  String get reset => 'Reset';

  @override
  String get language => 'Language';

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
  String get contact => 'Contacts';

  @override
  String get messageRevokedBySelf => 'You recalled a message';

  @override
  String get messageRevokedByOther => 'The other party recalled a message';

  @override
  String messageRevokedByUser(Object user) {
    return '$user recalled a message';
  }

  @override
  String groupMemberJoined(Object user) {
    return '$user joined the group';
  }

  @override
  String groupMemberInvited(Object operator, Object users) {
    return '$operator invited $users to join the group';
  }

  @override
  String groupMemberQuit(Object user) {
    return '$user left the group';
  }

  @override
  String groupMemberKicked(Object operator, Object users) {
    return '$operator removed $users from the group';
  }

  @override
  String groupAdminSet(Object users) {
    return '$users were set as administrators';
  }

  @override
  String groupAdminCancelled(Object users) {
    return '$users were removed from administrators';
  }

  @override
  String groupMessagePinned(Object user) {
    return '$user pinned a message';
  }

  @override
  String groupMessageUnpinned(Object user) {
    return '$user unpinned a message';
  }

  @override
  String get you => 'You';

  @override
  String get muted => 'muted';

  @override
  String get unmuted => 'unmuted';

  @override
  String get day => 'day';

  @override
  String get hour => 'hour';

  @override
  String get min => 'min';

  @override
  String get second => 'sec';

  @override
  String get messageTypeImage => '[Image]';

  @override
  String get messageTypeVoice => '[Voice]';

  @override
  String get messageTypeFile => '[File]';

  @override
  String get messageTypeVideo => '[Video]';

  @override
  String get messageTypeSticker => '[Sticker]';

  @override
  String get messageTypeCustom => '[Custom Message]';

  @override
  String get groupNameChangedTo => 'changed group name to';

  @override
  String get groupIntroChangedTo => 'changed group description to';

  @override
  String get groupNoticeChangedTo => 'changed group notice to';

  @override
  String get groupNoticeDeleted => 'deleted group notice';

  @override
  String get groupAvatarChanged => 'changed group avatar';

  @override
  String get groupOwnerTransferredTo => 'transferred group ownership to';

  @override
  String get groupMuteAllEnabled => 'enabled mute all members';

  @override
  String get groupMuteAllDisabled => 'disabled mute all members';

  @override
  String get unknown => 'Unknown';

  @override
  String get groupJoinMethodChangedTo => 'changed join method to';

  @override
  String get groupInviteMethodChangedTo => 'changed invite method to';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get yesterday => 'Yesterday';

  @override
  String dateMonthDayFormat(int month, int day) {
    return '$month/$day';
  }

  @override
  String dateYearMonthDayFormat(int year, int month, int day) {
    return '$month/$day/$year';
  }

  @override
  String get userID => 'User ID';

  @override
  String get groupIDLabel => 'Group ID';

  @override
  String get userIDLabel => 'User ID';

  @override
  String get file => 'File';

  @override
  String get recordAVideo => 'Record Video';

  @override
  String get audioCall => 'Audio Call';

  @override
  String get videoCall => 'Video Call';

  @override
  String get send => 'Send';

  @override
  String get more => 'More';

  @override
  String get delete => 'Delete';

  @override
  String get clearMessage => 'Clear chat history';

  @override
  String get pin => 'Pin chat';

  @override
  String get unpin => 'Unpin chat';

  @override
  String get startConversation => 'Start Chat';

  @override
  String get createGroupChat => 'Create Group';

  @override
  String get addFriend => 'Add friends';

  @override
  String get addGroup => 'Add Group';

  @override
  String get addContact => 'Add Contact';

  @override
  String get joinGroup => 'Join Group';

  @override
  String get createGroupTips => 'Create Group';

  @override
  String get createCommunity => 'Create Community';

  @override
  String get groupIDInvalid =>
      'Invalid group ID. Check whether the group ID is correct.';

  @override
  String get productDocumentation => 'View product documentation';

  @override
  String get create => 'Create';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupIDOption => 'Group ID (optional)';

  @override
  String get groupFaceUrl => 'Group Avatar';

  @override
  String get groupMemberSelected => 'Participants';

  @override
  String get groupWorkType => 'Friends Working group(Work)';

  @override
  String get groupPublicType => 'Stranger Social group(Public）';

  @override
  String get groupMeetingType => 'Temporary Meeting group(Meeting）';

  @override
  String get groupCommunityType => 'Community(Community)';

  @override
  String get groupWorkDesc =>
      'Friends work group (Work): Similar to ordinary WeChat groups, after creation, only friends who are already in the group can be invited to join the group, and there is no need for the approval of the invitee or the approval of the group owner.';

  @override
  String get groupPublicDesc =>
      'Stranger social group (Public): Similar to QQ group, the group owner can designate the group administrator after creation. After the user searches for the group ID and initiates a group application, the group owner or administrator must approve it before joining the group.';

  @override
  String get groupMeetingDesc =>
      'Temporary meeting group (Meeting): After creation, you can enter and leave at will, and support viewing of messages before joining the group; it is suitable for audio and video conference scenarios, online education scenarios, and other scenarios that are combined with real-time audio and video products.';

  @override
  String get groupCommunityDesc =>
      'Community(Community)：After creation, you can enter and leave at will, support up to 100,000 people, support historical message storage, and after users search for group ID and initiate a group application, they can join the group without administrator approval.';

  @override
  String get groupDetail => 'Group Chat Details';

  @override
  String get transferGroupOwner => 'Transfer Group Owner';

  @override
  String get publicGroup => 'Public Group';

  @override
  String get groupOfAnnouncement => 'Group Notice';

  @override
  String get groupManagement => 'Manage Group';

  @override
  String get groupType => 'Group Type';

  @override
  String get addGroupWay => 'Group Joining Method';

  @override
  String get inviteGroupType => 'Group Inviting Method';

  @override
  String get myAliasInGroup => 'My Group Nickname';

  @override
  String get doNotDisturb => 'Mute Notifications';

  @override
  String get groupMember => 'Group Members';

  @override
  String get profileRemark => 'Remark Name';

  @override
  String get groupEdit => 'Edit';

  @override
  String get blackList => 'Blocked List';

  @override
  String get profileBlack => 'Block';

  @override
  String get deleteFriend => 'Delete Contact';

  @override
  String get search => 'Search';

  @override
  String get chatHistory => 'Chat History';

  @override
  String get groups => 'Groups';

  @override
  String get newFriend => 'New Contacts';

  @override
  String get myGroups => 'Group Chats';

  @override
  String get contactInfo => 'Details';

  @override
  String get tuiEmojiSmile => '[Smile]';

  @override
  String get tuiEmojiExpect => '[Expect]';

  @override
  String get tuiEmojiBlink => '[Blink]';

  @override
  String get tuiEmojiGuffaw => '[Guffaw]';

  @override
  String get tuiEmojiKindSmile => '[Kind Smile]';

  @override
  String get tuiEmojiHaha => '[Haha]';

  @override
  String get tuiEmojiCheerful => '[Cheerful]';

  @override
  String get tuiEmojiSpeechless => '[Speechless]';

  @override
  String get tuiEmojiAmazed => '[Amazed]';

  @override
  String get tuiEmojiSorrow => '[Sorrow]';

  @override
  String get tuiEmojiComplacent => '[Complacent]';

  @override
  String get tuiEmojiSilly => '[Silly]';

  @override
  String get tuiEmojiLustful => '[Lustful]';

  @override
  String get tuiEmojiGiggle => '[Giggle]';

  @override
  String get tuiEmojiKiss => '[Kiss]';

  @override
  String get tuiEmojiWail => '[Wail]';

  @override
  String get tuiEmojiTearsLaugh => '[Tears Laugh]';

  @override
  String get tuiEmojiTrapped => '[Trapped]';

  @override
  String get tuiEmojiMask => '[Mask]';

  @override
  String get tuiEmojiFear => '[Fear]';

  @override
  String get tuiEmojiBareTeeth => '[Bare Teeth]';

  @override
  String get tuiEmojiFlareUp => '[Flare Up]';

  @override
  String get tuiEmojiYawn => '[Yawn]';

  @override
  String get tuiEmojiTact => '[Tact]';

  @override
  String get tuiEmojiStareyes => '[Stareyes]';

  @override
  String get tuiEmojiShutUp => '[Shut Up]';

  @override
  String get tuiEmojiSigh => '[Sigh]';

  @override
  String get tuiEmojiHehe => '[Hehe]';

  @override
  String get tuiEmojiSilent => '[Silent]';

  @override
  String get tuiEmojiSurprised => '[Surprised]';

  @override
  String get tuiEmojiAskance => '[Askance]';

  @override
  String get tuiEmojiOk => '[OK]';

  @override
  String get tuiEmojiShit => '[Shit]';

  @override
  String get tuiEmojiMonster => '[Monster]';

  @override
  String get tuiEmojiDaemon => '[Daemon]';

  @override
  String get tuiEmojiRage => '[Rage]';

  @override
  String get tuiEmojiFool => '[Fool]';

  @override
  String get tuiEmojiPig => '[Pig]';

  @override
  String get tuiEmojiCow => '[Cow]';

  @override
  String get tuiEmojiAi => '[AI]';

  @override
  String get tuiEmojiSkull => '[Skull]';

  @override
  String get tuiEmojiBombs => '[Bombs]';

  @override
  String get tuiEmojiCoffee => '[Coffee]';

  @override
  String get tuiEmojiCake => '[Cake]';

  @override
  String get tuiEmojiBeer => '[Beer]';

  @override
  String get tuiEmojiFlower => '[Flower]';

  @override
  String get tuiEmojiWatermelon => '[Watermelon]';

  @override
  String get tuiEmojiRich => '[Rich]';

  @override
  String get tuiEmojiHeart => '[Heart]';

  @override
  String get tuiEmojiMoon => '[Moon]';

  @override
  String get tuiEmojiSun => '[Sun]';

  @override
  String get tuiEmojiStar => '[Star]';

  @override
  String get tuiEmojiRedPacket => '[Red Packet]';

  @override
  String get tuiEmojiCelebrate => '[Celebrate]';

  @override
  String get tuiEmojiBless => '[Bless]';

  @override
  String get tuiEmojiFortune => '[Fortune]';

  @override
  String get tuiEmojiConvinced => '[Convinced]';

  @override
  String get tuiEmojiProhibit => '[Prohibit]';

  @override
  String get tuiEmoji666 => '[666]';

  @override
  String get tuiEmoji857 => '[857]';

  @override
  String get tuiEmojiKnife => '[Knife]';

  @override
  String get tuiEmojiLike => '[Like]';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get quitGroup => 'Leave';

  @override
  String get dismissGroup => 'Disband Group';

  @override
  String get groupNoticeEmpty => 'No group notice';

  @override
  String get next => 'Next';

  @override
  String get agree => 'Accept';

  @override
  String get accept => 'Accept';

  @override
  String get refuse => 'Decline';

  @override
  String get noFriendApplicationList => 'Friend request is empty';

  @override
  String get noBlackList => 'Block list is empty';

  @override
  String get noGroupList => 'Group chats is empty';

  @override
  String get noGroupApplicationList => 'No group application yet';

  @override
  String get groupChatNotifications => 'Group Chat Notifications';

  @override
  String get invite => 'invite';

  @override
  String get groupApplicationAllReadyBeenProcessed =>
      'This invitation or request has been processed.';

  @override
  String get accepted => 'Agreed';

  @override
  String get refused => 'Declined';

  @override
  String get copy => 'Copy';

  @override
  String get recall => 'Recall';

  @override
  String get forward => 'Forward';

  @override
  String get quote => 'Quote';

  @override
  String get searchUserID => 'Please enter User ID to search for users';

  @override
  String get searchGroupID => 'Group ID';

  @override
  String get searchGroupIDHint => 'Please enter Group ID to search for groups';

  @override
  String get addFailed => 'Add failed';

  @override
  String get joinGroupFailed => 'Join group failed';

  @override
  String get alreadyFriend => 'Already friends';

  @override
  String get signature => 'Bio';

  @override
  String get fillInTheVerificationInformation =>
      'Fill in verification information';

  @override
  String get joinedGroupSuccessfully => 'success';

  @override
  String get contactAddedSuccessfully => 'Contact Added Successfully';

  @override
  String get message => 'Message';

  @override
  String get groupWork => 'Work';

  @override
  String get groupPublic => 'Public';

  @override
  String get groupMeeting => 'Meeting';

  @override
  String get groupCommunity => 'Community';

  @override
  String get groupAVChatRoom => 'AVChatRoom';

  @override
  String get groupAddAny => 'Auto Approval';

  @override
  String get groupAddAuth => 'Admin Approval';

  @override
  String get groupAddForbid => 'Prohibited from Joining';

  @override
  String get groupInviteForbid => 'Prohibited from Inviting';

  @override
  String get groupOwner => 'Owner';

  @override
  String get member => 'Member';

  @override
  String get admin => 'Admin';

  @override
  String get modifyGroupName => 'Edit Group Name';

  @override
  String get modifyGroupNickname => 'Edit Group Name card';

  @override
  String get chatBackground => 'Chat Background';

  @override
  String get selectChatBackground => 'Select Chat Background';

  @override
  String get chatBackgroundDefault => 'Default';

  @override
  String get chatBackgroundCustom => 'Custom';

  @override
  String get quitGroupTip => 'Leave the group?';

  @override
  String get dismissGroupTip => 'Disband the group?';

  @override
  String get clearMsgTip => 'Are you sure you want to clear the chat history?';

  @override
  String get muteAll => 'Mute All';

  @override
  String get addMuteMemberTip => 'Add members to mute';

  @override
  String get groupMuteTip =>
      'When Mute All is enabled, only the group owner and admins are allowed to send messages.';

  @override
  String get deleteFriendTip => 'Are you sure you want to delete the contact?';

  @override
  String get remarkEdit => 'Edit Alias';

  @override
  String get detail => 'Details';

  @override
  String get setAdmin => 'Set Administrator';

  @override
  String get cancelAdmin => 'Cancel Admin';

  @override
  String get deleteGroupMemberTip => 'Confirm to delete group member?';

  @override
  String get settingSuccess => 'Setup Success!';

  @override
  String get settingFail => 'Setup failed!';

  @override
  String get noMore => 'No more';

  @override
  String get sayTimeShort => 'Message too short';

  @override
  String get recordLimitTips => 'Maximum voice length reached';

  @override
  String get chooseAvatar => 'Choose Avatar';

  @override
  String get inputGroupName => 'Please enter a group name';

  @override
  String get error => 'Error';

  @override
  String maxCountFile(Object maxCount) {
    return 'You can only select at most $maxCount files';
  }

  @override
  String get groupIntroDeleted => 'deleted group description';

  @override
  String get groupJoinForbidden => 'Join forbidden';

  @override
  String get groupJoinApproval => 'Admin approval required';

  @override
  String get groupJoinFree => 'Free to join';

  @override
  String get groupInviteForbidden => 'Invite forbidden';

  @override
  String get groupInviteApproval => 'Admin approval required';

  @override
  String get groupInviteFree => 'Free to invite';

  @override
  String get friendLimit => 'The number of your contacts exceeds the limit.';

  @override
  String get otherFriendLimit =>
      'The number of the other user\'s contacts exceeds the limit.';

  @override
  String get inBlacklist => 'You have blocked this user.';

  @override
  String get setInBlacklist => 'You have been blocked.';

  @override
  String get forbidAddFriend => 'This user has disabled contact request.';

  @override
  String get waitAgreeFriend => 'Request sent';

  @override
  String get userNotExist => 'User does not exist.';

  @override
  String get addGroupPermissionDeny => 'Prohibited from Joining';

  @override
  String get addGroupAlreadyMember => 'The user is a group member';

  @override
  String get addGroupNotFound => 'The group does not exist';

  @override
  String get addGroupFullMember =>
      'The number of group members has reached the limit';

  @override
  String chatRecords(Object count) {
    return '$count related records';
  }

  @override
  String get addRule => 'Contact Request';

  @override
  String get allowAny => 'Allow anyone';

  @override
  String get denyAny => 'Deny anyone';

  @override
  String get needConfirm => 'Requires verification';

  @override
  String get noSignature => 'No signature yet';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get birthday => 'Birthday';

  @override
  String get setNickname => 'Edit nickname';

  @override
  String get setSignature => 'Edit signature';

  @override
  String get messageNum => 'messages';

  @override
  String get draft => '[Draft]';

  @override
  String get sendMessageFail => 'Send Failed';

  @override
  String get resendTips => 'Are you sure you want to resend?';

  @override
  String get stopCallTip => 'Duration';

  @override
  String get startCall => 'Start Call';

  @override
  String get acceptCall => 'Answered';

  @override
  String get groupCallSend => 'initiated a group call';

  @override
  String get groupCallEnd => 'End group call';

  @override
  String get groupCallNoAnswer => 'no answer';

  @override
  String get groupCallReject => 'declined call';

  @override
  String get groupCallAccept => 'answered';

  @override
  String get groupCallConfirmSwitchToAudio => 'confirm to audio call';

  @override
  String get unknownCall => 'Unknown call';

  @override
  String get join => 'join in';

  @override
  String peopleOnCall(Object number) {
    return '$number person are currently on the call';
  }

  @override
  String get groupReadBy => 'Read';

  @override
  String get groupDeliveredTo => 'Unread';

  @override
  String get readReceiptAllRead => 'Read by All';

  @override
  String readReceiptNPersonRead(int count) {
    return 'Read by $count';
  }

  @override
  String get messageReadReceipt => 'Message Read Receipt';

  @override
  String get messageReadReceiptEnabledDesc =>
      'If disabled, the message read status is hidden for all your messages and for all the messages sent by members in a chat.';

  @override
  String get messageReadReceiptDisabledDesc =>
      'If enabled, the message read status is displayed for all your messages and for all the messages sent by members in a chat.';

  @override
  String get markAsRead => 'Mark As Read';

  @override
  String get markAsUnread => 'Mark As Unread';

  @override
  String get multiSelect => 'Select';

  @override
  String get postEmojis => 'React';

  @override
  String get recentlyUsed => 'Recently used';

  @override
  String get allEmojis => 'All';

  @override
  String get selectChat => 'Select Chat';

  @override
  String selectedCount(int count) {
    return 'Selected $count';
  }

  @override
  String get forwardIndividually => 'Forward Individually';

  @override
  String get forwardMerged => 'Forward as Merged';

  @override
  String get groupChatHistory => 'Group Chat History';

  @override
  String c2cChatHistoryFormat(String name) {
    return '$name\'s Chat History';
  }

  @override
  String chatHistoryForSomebodyFormat(String name1, String name2) {
    return 'Chat History of $name1 and $name2';
  }

  @override
  String get forwardCompatibleText => 'Please upgrade to view chat history';

  @override
  String get forwardFailedMessageTip => 'Failed messages cannot be forwarded!';

  @override
  String get forwardSeparateLimitTip =>
      'Too many messages selected, individual forwarding is not supported';

  @override
  String get deleteMessagesConfirmTip =>
      'Are you sure you want to delete the selected messages?';

  @override
  String get deleteConversationTip =>
      'Are you sure you want to delete this conversation?';

  @override
  String get conversationListAtAll => '[@All]';

  @override
  String get conversationListAtMe => '[@Me]';

  @override
  String get messageInputAllMembers => 'All';

  @override
  String get selectMentionMember => 'Select Members';

  @override
  String get tapToRemove => 'Tap to remove';

  @override
  String get messageTypeSecurityStrike => 'Sensitive content involved';

  @override
  String get convertToText => 'Convert to Text';

  @override
  String get convertToTextFailed => 'Unable to convert';

  @override
  String get hide => 'Hide';

  @override
  String get translate => 'Translate';

  @override
  String get translateFailed => 'Unable to translate';

  @override
  String get translateDefaultTips => 'Translation powered by Tencent Cloud IM';

  @override
  String get translating => 'Translating...';

  @override
  String get translateTargetLanguage => 'Translate Target Language';

  @override
  String get backToLatest => 'Back to Latest';

  @override
  String newMessageCount(int count) {
    return '$count new messages';
  }

  @override
  String get holdToTalk => 'Hold to talk';

  @override
  String get sendMessageOrHoldToTalk => 'Type or hold to talk...';

  @override
  String get releaseToSend => 'Release to send';

  @override
  String get releaseToCancel => 'Release to cancel';

  @override
  String recordCountdownTips(int seconds) {
    return 'Recording will stop in ${seconds}s';
  }

  @override
  String get backToQuotePosition => 'Back to quote';

  @override
  String get quotedMessageRevoked => 'Quoted content recalled';

  @override
  String get quotedMessageNotFound => 'Quoted content unavailable';

  @override
  String get quotedOriginalMessageUnreachable =>
      'Unable to locate the original message';

  @override
  String reactionUserSummary(String name, int totalCount, int othersCount) {
    return '$name and $othersCount others';
  }

  @override
  String get messageTypeMerged => '[Chat Records]';

  @override
  String get messageTypeUnknown => '[Message]';

  @override
  String get releaseToConvert => 'Release to convert';

  @override
  String get voiceToTextFailed => 'No text recognized';

  @override
  String get sendOriginalVoice => 'Send original voice';

  @override
  String get addMembers => 'Add Members';

  @override
  String get album => 'Album';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get takeAPhoto => 'Take Photo';

  @override
  String get callRejectCaller => 'Call declined by user';

  @override
  String get callRejectCallee => 'Declined';

  @override
  String get callCancelCaller => 'Canceled';

  @override
  String get callCancelCallee => 'Call canceled by caller';

  @override
  String get callTimeoutCaller => 'Call was not answered';

  @override
  String get callTimeoutCallee => 'Call timeout';

  @override
  String get callLineBusyCaller => 'Line busy';

  @override
  String get callLineBusyCallee => 'Line busy';

  @override
  String get callingSwitchToAudio => 'Switch to voice call';

  @override
  String get callingSwitchToAudioAccept => 'Confirm video to voice';
}
