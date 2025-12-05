// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'atomic_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AtomicLocalizationsEn extends AtomicLocalizations {
  AtomicLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get chat => 'Chat';

  @override
  String get settings => 'Settings';

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
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get contact => 'Contacts';

  @override
  String get messageRevokedDefault => 'A user recalled a message';

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
  String get weekdaySunday => 'Sun';

  @override
  String get weekdayMonday => 'Mon';

  @override
  String get weekdayTuesday => 'Tue';

  @override
  String get weekdayWednesday => 'Wed';

  @override
  String get weekdayThursday => 'Thu';

  @override
  String get weekdayFriday => 'Fri';

  @override
  String get weekdaySaturday => 'Sat';

  @override
  String get userID => 'User ID';

  @override
  String get album => 'Album';

  @override
  String get file => 'File';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get recordAVideo => 'Record a video';

  @override
  String get send => 'Send';

  @override
  String get sendSoundTips => 'Press and hold to speak Release to send';

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
  String get startConversation => 'New Chat';

  @override
  String get createGroupChat => 'Create Group Chat';

  @override
  String get addFriend => 'Add friends';

  @override
  String get addGroup => 'Add Group';

  @override
  String get createGroupTips => 'Create Group';

  @override
  String get createCommunity => 'Create Community';

  @override
  String get groupIDInvalid =>
      'Invalid group ID. Check whether the group ID is correct.';

  @override
  String get communityIDEditFormatTips =>
      'Community ID prefix must be @TGS#_ !';

  @override
  String get groupIDEditFormatTips => 'Group ID prefix cannot be @TGS# !';

  @override
  String get groupIDEditExceedTips => 'Group ID up to 48 bytes!';

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
  String get privateGroup => 'Discussion Group';

  @override
  String get publicGroup => 'Public Group';

  @override
  String get chatRoom => 'Chatroom';

  @override
  String get communityGroup => 'Community';

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
  String get myAliasInGroup => 'My Alias in Group';

  @override
  String get doNotDisturb => 'Mute Notifications';

  @override
  String get groupMember => 'Group Members';

  @override
  String get profileRemark => 'Alias';

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
  String get includeGroupMembers => 'Include members:';

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
  String get addMembers => 'Add Members';

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
  String get reply => 'Reply';

  @override
  String get searchUserID => 'Please enter User ID to search for users';

  @override
  String get searchGroupID => 'Search Group ID';

  @override
  String get searchGroupIDHint => 'Please enter Group ID to search for groups';

  @override
  String get addFailed => 'Add failed';

  @override
  String get joinGroupFailed => 'Join group failed';

  @override
  String get alreadyInGroup => 'Already in group';

  @override
  String get alreadyFriend => 'Already friends';

  @override
  String get signature => 'Bio';

  @override
  String get searchError => 'Search error';

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
  String get groupNickname => 'My Alias in Group';

  @override
  String get modifyGroupNickname => 'Edit My Alias in Group';

  @override
  String get modifyGroupNoticeSuccess => 'Edited';

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
  String get on => 'ON';

  @override
  String get off => 'OFF';

  @override
  String get chooseAvatar => 'Choose Avatar';

  @override
  String get inputGroupName => 'Please enter a group name';

  @override
  String get error => 'Error';

  @override
  String get permissionNeeded => 'Required permissions';

  @override
  String get permissionDeniedContent =>
      'Please go to Settings and enable the Photos permission.';

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
  String get mergeMessage => 'Merge Messages';

  @override
  String get upgradeLatestVersion => 'Please upgrade to the latest version';

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
  String get haveBeFriend => 'You two are already contacts of each other.';

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
  String get sendMessageFail => 'Send Failed';

  @override
  String get resendTips => 'Are you sure you want to resend?';

  @override
  String get callRejectCaller => 'Call declined by user';

  @override
  String get callRejectCallee => 'Declined';

  @override
  String get callCancelCaller => 'Canceled';

  @override
  String get callCancelCallee => 'Call canceled by caller';

  @override
  String get stopCallTip => 'Duration';

  @override
  String get callTimeoutCaller => 'Call was not answered';

  @override
  String get callTimeoutCallee => 'Call timeout';

  @override
  String get callLineBusyCaller => 'Line busy';

  @override
  String get callLineBusyCallee => 'Line busy';

  @override
  String get startCall => 'Start Call';

  @override
  String get acceptCall => 'Answered';

  @override
  String get callingSwitchToAudio => 'Switch to voice call';

  @override
  String get callingSwitchToAudioAccept => 'Confirm video to voice';

  @override
  String get invalidCommand => 'invalid command';

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
}
