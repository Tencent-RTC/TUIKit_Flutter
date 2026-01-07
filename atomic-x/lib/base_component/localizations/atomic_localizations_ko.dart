// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'atomic_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AtomicLocalizationsKo extends AtomicLocalizations {
  AtomicLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get login => '로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get chat => '채팅';

  @override
  String get settings => '설정';

  @override
  String get theme => '테마';

  @override
  String get themeLight => '밝음';

  @override
  String get themeDark => '어둠';

  @override
  String get followSystem => '시스템을 따르세요';

  @override
  String get color => '색상';

  @override
  String get language => '언어';

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
  String get confirm => '확인';

  @override
  String get cancel => '취소';

  @override
  String get contact => '연락처';

  @override
  String get messageRevokedDefault => '사용자가 메시지를 철회했습니다';

  @override
  String get messageRevokedBySelf => '메시지를 철회했습니다';

  @override
  String get messageRevokedByOther => '상대방이 메시지를 철회했습니다';

  @override
  String messageRevokedByUser(Object user) {
    return '$user님이 메시지를 철회했습니다';
  }

  @override
  String groupMemberJoined(Object user) {
    return '$user님이 그룹에 참여했습니다';
  }

  @override
  String groupMemberInvited(Object operator, Object users) {
    return '$operator님이 $users님을 그룹에 초대했습니다';
  }

  @override
  String groupMemberQuit(Object user) {
    return '$user님이 그룹을 나갔습니다';
  }

  @override
  String groupMemberKicked(Object operator, Object users) {
    return '$operator님이 $users님을 그룹에서 내보냈습니다';
  }

  @override
  String groupAdminSet(Object users) {
    return '$users님이 관리자로 설정되었습니다';
  }

  @override
  String groupAdminCancelled(Object users) {
    return '$users님의 관리자 권한이 취소되었습니다';
  }

  @override
  String groupMessagePinned(Object user) {
    return '$user님이 메시지를 고정했습니다';
  }

  @override
  String groupMessageUnpinned(Object user) {
    return '$user님이 메시지 고정을 해제했습니다';
  }

  @override
  String get you => '당신';

  @override
  String get muted => '음소거됨';

  @override
  String get unmuted => '음소거 해제됨';

  @override
  String get day => '일';

  @override
  String get hour => '시간';

  @override
  String get min => '분';

  @override
  String get second => '초';

  @override
  String get messageTypeImage => '[이미지]';

  @override
  String get messageTypeVoice => '[음성]';

  @override
  String get messageTypeFile => '[파일]';

  @override
  String get messageTypeVideo => '[비디오]';

  @override
  String get messageTypeSticker => '[스티커]';

  @override
  String get messageTypeCustom => '[사용자 정의 메시지]';

  @override
  String get groupNameChangedTo => '그룹 이름을 변경했습니다:';

  @override
  String get groupIntroChangedTo => '그룹 소개를 변경했습니다:';

  @override
  String get groupNoticeChangedTo => '그룹 공지를 변경했습니다:';

  @override
  String get groupNoticeDeleted => '그룹 공지를 삭제했습니다';

  @override
  String get groupAvatarChanged => '그룹 아바타를 변경했습니다';

  @override
  String get groupOwnerTransferredTo => '그룹 소유권을 이전했습니다:';

  @override
  String get groupMuteAllEnabled => '전체 음소거를 활성화했습니다';

  @override
  String get groupMuteAllDisabled => '전체 음소거를 비활성화했습니다';

  @override
  String get unknown => '알 수 없음';

  @override
  String get groupJoinMethodChangedTo => '참여 방법을 변경했습니다:';

  @override
  String get groupInviteMethodChangedTo => '초대 방법을 변경했습니다:';

  @override
  String get weekdaySunday => '일';

  @override
  String get weekdayMonday => '월';

  @override
  String get weekdayTuesday => '화';

  @override
  String get weekdayWednesday => '수';

  @override
  String get weekdayThursday => '목';

  @override
  String get weekdayFriday => '금';

  @override
  String get weekdaySaturday => '토';

  @override
  String get userID => '사용자 ID';

  @override
  String get album => '앨범';

  @override
  String get file => '파일';

  @override
  String get takeAPhoto => '사진';

  @override
  String get recordAVideo => '동영상';

  @override
  String get send => '보내다';

  @override
  String get sendSoundTips => '길게 눌러 말하기, 놓으면 보내기';

  @override
  String get more => '더보기';

  @override
  String get delete => '삭제';

  @override
  String get clearMessage => '채팅 기록 삭제';

  @override
  String get pin => '채팅 고정';

  @override
  String get unpin => '고정 해제';

  @override
  String get startConversation => '세션 시작';

  @override
  String get createGroupChat => '그룹 채팅 만들기';

  @override
  String get addFriend => '친구 추가';

  @override
  String get addGroup => '그룹 추가';

  @override
  String get createGroupTips => '그룹 만들기';

  @override
  String get createCommunity => '커뮤니티 만들기';

  @override
  String get groupIDInvalid => '그룹 ID가 잘못되었습니다. 그룹 ID를 올바르게 입력했는지 확인하세요.';

  @override
  String get communityIDEditFormatTips => '커뮤니티 ID 앞에는 @TGS#_가 붙어야 합니다!';

  @override
  String get groupIDEditFormatTips => '그룹 ID 접두사는 @TGS#일 수 없습니다!';

  @override
  String get groupIDEditExceedTips => '그룹 ID는 최대 48바이트까지 가능합니다!';

  @override
  String get productDocumentation => '제품 설명서 보기';

  @override
  String get create => '만들다';

  @override
  String get groupName => '그룹 이름';

  @override
  String get groupIDOption => '그룹 ID(선택사항)';

  @override
  String get groupFaceUrl => '그룹 아바타';

  @override
  String get groupMemberSelected => '선택된 그룹 구성원';

  @override
  String get groupWorkType => '좋은 직업 그룹 (일)';

  @override
  String get groupPublicType => '낯선 소셜 그룹(공개)';

  @override
  String get groupMeetingType => '임시 회의 그룹 (회의)';

  @override
  String get groupCommunityType => '지역 사회';

  @override
  String get groupWorkDesc =>
      '친구 작업 그룹(Work) : 일반 위챗 그룹과 유사하게 생성 후, 이미 그룹에 속한 친구만 그룹에 초대할 수 있으며, 초대한 당사자의 동의나 그룹의 승인이 필요하지 않습니다. 소유자.';

  @override
  String get groupPublicDesc =>
      '낯선 소셜 그룹(공개): QQ 그룹과 마찬가지로 그룹 생성 후 그룹 소유자가 그룹 관리자를 지정할 수 있습니다. 사용자가 그룹 ID를 검색하고 그룹 가입 신청을 시작한 후 그룹에 가입하기 전에 그룹 소유자 또는 관리자의 승인이 필요합니다. .';

  @override
  String get groupMeetingDesc =>
      '임시 회의 그룹(Meeting): 생성 후 마음대로 입장 및 퇴장할 수 있으며, 그룹에 참여하기 전 메시지 보기를 지원합니다. 음성 및 영상 회의 시나리오, 온라인 교육 시나리오 및 실시간 오디오와 결합된 기타 시나리오에 적합합니다. 그리고 비디오 제품.';

  @override
  String get groupCommunityDesc =>
      '커뮤니티: 생성 후 자유롭게 입장 및 탈퇴가 가능하며, 기록 메시지 저장을 지원하며, 사용자가 그룹 ID를 검색하고 그룹 신청을 한 후 관리자 승인 없이 그룹에 가입할 수 있습니다.';

  @override
  String get groupDetail => '그룹 채팅 세부정보';

  @override
  String get transferGroupOwner => '그룹 소유자 이전';

  @override
  String get privateGroup => '토론 그룹';

  @override
  String get publicGroup => '공개 그룹';

  @override
  String get chatRoom => '대화방';

  @override
  String get communityGroup => '지역 사회';

  @override
  String get groupOfAnnouncement => '그룹 공지';

  @override
  String get groupManagement => '그룹 관리';

  @override
  String get groupType => '그룹 유형';

  @override
  String get addGroupWay => '그룹에 참여하는 적극적인 방법';

  @override
  String get inviteGroupType => '그룹에 초대하는 방법';

  @override
  String get myAliasInGroup => '그룹에서의 별칭';

  @override
  String get doNotDisturb => '방해 금지 메시지';

  @override
  String get groupMember => '그룹 구성원';

  @override
  String get profileRemark => '비고';

  @override
  String get groupEdit => '편집하다';

  @override
  String get blackList => '블랙리스트';

  @override
  String get profileBlack => '블랙리스트에 추가';

  @override
  String get deleteFriend => '친구 삭제하기';

  @override
  String get search => '검색';

  @override
  String get chatHistory => '채팅 기록';

  @override
  String get groups => '그룹';

  @override
  String get newFriend => '새로운 연락처';

  @override
  String get myGroups => '내 그룹 채팅';

  @override
  String get contactInfo => '세부';

  @override
  String get includeGroupMembers => '포함된 멤버:';

  @override
  String get tuiEmojiSmile => '[미소]';

  @override
  String get tuiEmojiExpect => '[기대]';

  @override
  String get tuiEmojiBlink => '[눈짓]';

  @override
  String get tuiEmojiGuffaw => '[큰 웃음]';

  @override
  String get tuiEmojiKindSmile => '[이모티콘 웃음]';

  @override
  String get tuiEmojiHaha => '[하하하]';

  @override
  String get tuiEmojiCheerful => '[즐거움]';

  @override
  String get tuiEmojiSpeechless => '[말문이 막혀]';

  @override
  String get tuiEmojiAmazed => '[놀라움]';

  @override
  String get tuiEmojiSorrow => '[슬픔]';

  @override
  String get tuiEmojiComplacent => '[만족]';

  @override
  String get tuiEmojiSilly => '[바보 같음]';

  @override
  String get tuiEmojiLustful => '[음란]';

  @override
  String get tuiEmojiGiggle => '[어린아이처럼 웃음]';

  @override
  String get tuiEmojiKiss => '[키스]';

  @override
  String get tuiEmojiWail => '[비명]';

  @override
  String get tuiEmojiTearsLaugh => '[울면서 웃음]';

  @override
  String get tuiEmojiTrapped => '[곤란함]';

  @override
  String get tuiEmojiMask => '[마스크]';

  @override
  String get tuiEmojiFear => '[공포]';

  @override
  String get tuiEmojiBareTeeth => '[이를 드러냄]';

  @override
  String get tuiEmojiFlareUp => '[분노]';

  @override
  String get tuiEmojiYawn => '[잠옷]';

  @override
  String get tuiEmojiTact => '[기지]';

  @override
  String get tuiEmojiStareyes => '[별눈]';

  @override
  String get tuiEmojiShutUp => '[입 다물기]';

  @override
  String get tuiEmojiSigh => '[한숨]';

  @override
  String get tuiEmojiHehe => '[헤헤]';

  @override
  String get tuiEmojiSilent => '[조용]';

  @override
  String get tuiEmojiSurprised => '[놀라움]';

  @override
  String get tuiEmojiAskance => '[불만의 눈길]';

  @override
  String get tuiEmojiOk => '[확인]';

  @override
  String get tuiEmojiShit => '[똥]';

  @override
  String get tuiEmojiMonster => '[몬스터]';

  @override
  String get tuiEmojiDaemon => '[악마]';

  @override
  String get tuiEmojiRage => '[악마의 분노]';

  @override
  String get tuiEmojiFool => '[바보]';

  @override
  String get tuiEmojiPig => '[돼지]';

  @override
  String get tuiEmojiCow => '[소]';

  @override
  String get tuiEmojiAi => '[AI]';

  @override
  String get tuiEmojiSkull => '[해골]';

  @override
  String get tuiEmojiBombs => '[폭탄]';

  @override
  String get tuiEmojiCoffee => '[커피]';

  @override
  String get tuiEmojiCake => '[케이크]';

  @override
  String get tuiEmojiBeer => '[맥주]';

  @override
  String get tuiEmojiFlower => '[꽃]';

  @override
  String get tuiEmojiWatermelon => '[수박]';

  @override
  String get tuiEmojiRich => '[부자]';

  @override
  String get tuiEmojiHeart => '[하트]';

  @override
  String get tuiEmojiMoon => '[달]';

  @override
  String get tuiEmojiSun => '[태양]';

  @override
  String get tuiEmojiStar => '[별]';

  @override
  String get tuiEmojiRedPacket => '[빨간 봉투]';

  @override
  String get tuiEmojiCelebrate => '[축하]';

  @override
  String get tuiEmojiBless => '[복]';

  @override
  String get tuiEmojiFortune => '[행운]';

  @override
  String get tuiEmojiConvinced => '[동의]';

  @override
  String get tuiEmojiProhibit => '[금지]';

  @override
  String get tuiEmoji666 => '[666]';

  @override
  String get tuiEmoji857 => '[857]';

  @override
  String get tuiEmojiKnife => '[칼]';

  @override
  String get tuiEmojiLike => '[좋아요]';

  @override
  String get sendMessage => '메시지 보내기';

  @override
  String get addMembers => '멤버 추가';

  @override
  String get quitGroup => '그룹 채팅 종료';

  @override
  String get dismissGroup => '그룹을 해체하다';

  @override
  String get groupNoticeEmpty => '아직 그룹 공지가 없습니다';

  @override
  String get next => '다음';

  @override
  String get agree => '수락';

  @override
  String get accept => '수락';

  @override
  String get refuse => '거절';

  @override
  String get noFriendApplicationList => '새로운 연락처 요청이 없습니다';

  @override
  String get noBlackList => '블랙리스트에 등록된 사용자가 없습니다';

  @override
  String get noGroupList => '그룹 채팅 금지';

  @override
  String get noGroupApplicationList => '아직 단체 신청이 없습니다';

  @override
  String get groupChatNotifications => '그룹 채팅 알림';

  @override
  String get invite => '초대하다';

  @override
  String get groupApplicationAllReadyBeenProcessed =>
      '이 초대 또는 신청 요청은 이미 처리되었습니다.';

  @override
  String get accepted => '동의함';

  @override
  String get refused => '거부됨';

  @override
  String get copy => '복사';

  @override
  String get recall => '회수';

  @override
  String get forward => '전달';

  @override
  String get quote => '인용';

  @override
  String get reply => '답장';

  @override
  String get searchUserID => '사용자 ID를 입력하여 사용자를 검색하세요';

  @override
  String get searchGroupID => '그룹 ID 검색';

  @override
  String get searchGroupIDHint => '그룹 ID를 입력하여 그룹을 검색하세요';

  @override
  String get addFailed => '친구 추가 실패';

  @override
  String get joinGroupFailed => '그룹 참가 실패';

  @override
  String get alreadyInGroup => '이미 그룹에 있습니다';

  @override
  String get alreadyFriend => '이미 친구';

  @override
  String get signature => '자기소개';

  @override
  String get searchError => '검색 오류';

  @override
  String get fillInTheVerificationInformation => '인증정보를 입력하세요';

  @override
  String get joinedGroupSuccessfully => '성공';

  @override
  String get contactAddedSuccessfully => '연락처가 성공적으로 추가되었습니다';

  @override
  String get message => '정보';

  @override
  String get groupWork => '작업 그룹';

  @override
  String get groupPublic => '공개 그룹';

  @override
  String get groupMeeting => '회의 그룹';

  @override
  String get groupCommunity => '지역 사회';

  @override
  String get groupAVChatRoom => '생방송 그룹';

  @override
  String get groupAddAny => '자동 승인';

  @override
  String get groupAddAuth => '관리자 승인';

  @override
  String get groupAddForbid => '그룹 가입이 금지되어 있습니다.';

  @override
  String get groupInviteForbid => '초대장 없음';

  @override
  String get groupOwner => '그룹 소유자';

  @override
  String get member => '회원';

  @override
  String get admin => '관리자';

  @override
  String get modifyGroupName => '그룹 이름 수정';

  @override
  String get groupNickname => '내 그룹 별명';

  @override
  String get modifyGroupNickname => '내 그룹 닉네임 변경';

  @override
  String get modifyGroupNoticeSuccess => '그룹 공지사항 수정이 성공적으로 완료되었습니다.';

  @override
  String get quitGroupTip => '정말로 이 그룹을 떠나시겠습니까?';

  @override
  String get dismissGroupTip => '이 그룹을 해체하시겠습니까?';

  @override
  String get clearMsgTip => '채팅 기록을 지우시겠습니까?';

  @override
  String get muteAll => '모두 음소거 상태입니다';

  @override
  String get addMuteMemberTip => '음소거할 그룹 구성원 추가';

  @override
  String get groupMuteTip => '음소거 기능이 활성화되면 그룹 소유자와 관리자만 말할 수 있습니다.';

  @override
  String get deleteFriendTip => '연락처 삭제를 확인하시겠습니까?';

  @override
  String get remarkEdit => '수정 사항';

  @override
  String get detail => '세부';

  @override
  String get setAdmin => '관리자로 설정';

  @override
  String get cancelAdmin => '관리자 취소';

  @override
  String get deleteGroupMemberTip => '그룹 구성원을 삭제하시겠습니까?';

  @override
  String get settingSuccess => '설치가 성공했습니다!';

  @override
  String get settingFail => '설치에 실패했습니다!';

  @override
  String get noMore => '더 이상은 없다';

  @override
  String get sayTimeShort => '말하는 시간이 너무 짧습니다';

  @override
  String get recordLimitTips => '최대 음성 길이에 도달했습니다.';

  @override
  String get on => '열려 있는';

  @override
  String get off => '닫다';

  @override
  String get chooseAvatar => '아바타를 선택하세요';

  @override
  String get inputGroupName => '그룹 이름을 입력하세요';

  @override
  String get error => '실수';

  @override
  String get permissionNeeded => '필수 권한';

  @override
  String get permissionDeniedContent => '설정으로 가서 사진 권한을 허용해 주세요.';

  @override
  String maxCountFile(Object maxCount) {
    return '최대 $maxCount개의 파일만 선택할 수 있습니다.';
  }

  @override
  String get groupIntroDeleted => '삭제된 그룹 프로필';

  @override
  String get groupJoinForbidden => '참여 금지';

  @override
  String get groupJoinApproval => '관리자 승인 필요';

  @override
  String get groupJoinFree => '자유 참여';

  @override
  String get groupInviteForbidden => '초대 금지';

  @override
  String get groupInviteApproval => '관리자 승인 필요';

  @override
  String get groupInviteFree => '자유 초대';

  @override
  String get mergeMessage => '메시지 병합';

  @override
  String get upgradeLatestVersion => '최신 버전으로 업그레이드해주세요';

  @override
  String get friendLimit => '귀하의 친구 수가 시스템 한도에 도달했습니다.';

  @override
  String get otherFriendLimit => '상대방의 친구 수가 시스템 한도에 도달했습니다.';

  @override
  String get inBlacklist => '블랙리스트에 친구로 추가됨';

  @override
  String get setInBlacklist => '상대방에 의해 블랙리스트에 등록되었습니다.';

  @override
  String get forbidAddFriend => '상대방이 친구를 추가할 수 없도록 차단되었습니다.';

  @override
  String get waitAgreeFriend => '친구들의 검토와 승인을 기다리는 중';

  @override
  String get haveBeFriend => '그 사람은 이미 당신의 친구입니다.';

  @override
  String get addGroupPermissionDeny => '그룹 가입이 금지되어 있습니다.';

  @override
  String get addGroupAlreadyMember => '이미 그룹 회원입니다.';

  @override
  String get addGroupNotFound => '그룹이 존재하지 않습니다';

  @override
  String get addGroupFullMember => '그룹이 가득 찼습니다.';

  @override
  String chatRecords(Object count) {
    return '$count 관련 레코드';
  }

  @override
  String get addRule => '연락 요청';

  @override
  String get allowAny => '누구나 허용';

  @override
  String get denyAny => '누구나 거부';

  @override
  String get needConfirm => '확인 필요';

  @override
  String get noSignature => '아직 서명 없음';

  @override
  String get gender => '성별';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get birthday => '생일';

  @override
  String get setNickname => '닉네임 수정';

  @override
  String get setSignature => '서명 수정';

  @override
  String get messageNum => '조각';

  @override
  String get draft => '[임시저장]';

  @override
  String get sendMessageFail => '보내기 실패';

  @override
  String get resendTips => '다시 보내시겠습니까?';

  @override
  String get callRejectCaller => '상대방이 거부함';

  @override
  String get callRejectCallee => '거부됨';

  @override
  String get callCancelCaller => '취소';

  @override
  String get callCancelCallee => '상대방이 취소했습니다.';

  @override
  String get stopCallTip => '통화 시간';

  @override
  String get callTimeoutCaller => '상대방의 응답이 없습니다.';

  @override
  String get callTimeoutCallee => '응답 없이 시간 초과.';

  @override
  String get callLineBusyCaller => '상대방이 바빠요';

  @override
  String get callLineBusyCallee => '통화중 회선에 응답이 없습니다.';

  @override
  String get startCall => '통화 시작';

  @override
  String get acceptCall => '답변됨';

  @override
  String get callingSwitchToAudio => '영상에서 연설로';

  @override
  String get callingSwitchToAudioAccept => '음성으로 영상 확인';

  @override
  String get invalidCommand => '인식할 수 없는 호출 명령';

  @override
  String get groupCallSend => '그룹통화가 시작되었습니다';

  @override
  String get groupCallEnd => '통화가 종료되었습니다';

  @override
  String get groupCallNoAnswer => '답변 없음';

  @override
  String get groupCallReject => '그룹 통화 거부';

  @override
  String get groupCallAccept => '답변';

  @override
  String get groupCallConfirmSwitchToAudio => '영상을 음성으로 변환하는 데 동의합니다.';

  @override
  String get unknownCall => '알 수 없는 전화';

  @override
  String get join => '참여하다';

  @override
  String peopleOnCall(Object number) {
    return '$number님은 현재 통화 중입니다.';
  }

  @override
  String get messageReadDetail => '메시지 읽음 상세';

  @override
  String get groupReadBy => '읽음';

  @override
  String get groupDeliveredTo => '읽지 않음';

  @override
  String get loadingMore => '더 불러오기...';

  @override
  String get unknownFile => '알 수 없는 파일';

  @override
  String get messageReadReceipt => '메시지 읽음 상태';

  @override
  String get messageReadReceiptEnabledDesc =>
      '끄면 보내고 받는 메시지에 메시지 읽음 상태가 표시되지 않으며, 상대방이 메시지를 읽었는지 확인할 수 없고 상대방도 당신이 메시지를 읽었는지 확인할 수 없습니다.';

  @override
  String get messageReadReceiptDisabledDesc =>
      '켜면 그룹 채팅에서 보내고 받는 메시지에 메시지 읽음 상태가 표시되며, 상대방이 메시지를 읽었는지 확인할 수 있습니다. 개인 채팅 친구도 메시지 읽음 상태를 켜면, 해당 친구와의 개인 채팅에서 보내고 받는 메시지에도 메시지 읽음 상태가 표시됩니다.';

  @override
  String get appearance => '외관';

  @override
  String get markAsRead => '읽음으로 표시';

  @override
  String get markAsUnread => '읽지 않음으로 표시';

  @override
  String get multiSelect => '다중 선택';

  @override
  String get selectChat => '채팅 선택';

  @override
  String sendCount(int count) {
    return '보내기 ($count)';
  }

  @override
  String selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get forwardIndividually => '개별 전달';

  @override
  String get forwardMerged => '병합 전달';

  @override
  String get groupChatHistory => '그룹 채팅 기록';

  @override
  String c2cChatHistoryFormat(String name) {
    return '$name의 채팅 기록';
  }

  @override
  String chatHistoryForSomebodyFormat(String name1, String name2) {
    return '$name1와 $name2의 채팅 기록';
  }

  @override
  String get recentChats => '최근 채팅';

  @override
  String get forwardCompatibleText => '채팅 기록을 보려면 업그레이드하세요';

  @override
  String get forwardFailedMessageTip => '전송 실패 메시지는 전달할 수 없습니다!';

  @override
  String get forwardSeparateLimitTip => '선택한 메시지가 너무 많아 개별 전달이 지원되지 않습니다';

  @override
  String get deleteMessagesConfirmTip => '선택한 메시지를 삭제하시겠습니까?';

  @override
  String get conversationListAtAll => '[@전체]';

  @override
  String get conversationListAtMe => '[@나]';

  @override
  String get messageInputAllMembers => '전체';

  @override
  String get selectMentionMember => '멤버 선택';

  @override
  String get tapToRemove => '탭하여 제거';

  @override
  String get messageTypeSecurityStrike => '민감한 콘텐츠가 포함되어 있습니다';

  @override
  String get convertToText => '텍스트로 변환';

  @override
  String get convertToTextFailed => '변환할 수 없습니다';

  @override
  String get hide => '숨기기';

  @override
  String get copied => '복사됨';

  @override
  String get translate => '번역';

  @override
  String get translateFailed => '번역할 수 없습니다';

  @override
  String get translateDefaultTips => 'Tencent Cloud IM 번역 제공';

  @override
  String get translating => '번역 중...';

  @override
  String get translateTargetLanguage => '번역 대상 언어';

  @override
  String get translateLanguageZh => '简体中文';

  @override
  String get translateLanguageZhTW => '繁體中文';

  @override
  String get translateLanguageEn => 'English';

  @override
  String get translateLanguageJa => '日本語';

  @override
  String get translateLanguageKo => '한국어';

  @override
  String get translateLanguageFr => 'Français';

  @override
  String get translateLanguageEs => 'Español';

  @override
  String get translateLanguageIt => 'Italiano';

  @override
  String get translateLanguageDe => 'Deutsch';

  @override
  String get translateLanguageTr => 'Türkçe';

  @override
  String get translateLanguageRu => 'Русский';

  @override
  String get translateLanguagePt => 'Português';

  @override
  String get translateLanguageVi => 'Tiếng Việt';

  @override
  String get translateLanguageId => 'Bahasa Indonesia';

  @override
  String get translateLanguageTh => 'ภาษาไทย';

  @override
  String get translateLanguageMs => 'Bahasa Melayu';

  @override
  String get translateLanguageHi => 'हिन्दी';
}
