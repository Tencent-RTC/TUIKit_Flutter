// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'atomic_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AtomicLocalizationsJa extends AtomicLocalizations {
  AtomicLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get login => 'ログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get chat => 'チャット';

  @override
  String get settings => '設定';

  @override
  String get theme => 'テーマ';

  @override
  String get themeLight => '明るい';

  @override
  String get themeDark => '暗い';

  @override
  String get followSystem => 'システムに従う';

  @override
  String get color => '色';

  @override
  String get language => '言語';

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
  String get confirm => '確認';

  @override
  String get cancel => 'キャンセル';

  @override
  String get contact => '連絡先';

  @override
  String get messageRevokedDefault => 'ユーザーがメッセージを取り消しました';

  @override
  String get messageRevokedBySelf => 'あなたがメッセージを取り消しました';

  @override
  String get messageRevokedByOther => '相手がメッセージを取り消しました';

  @override
  String messageRevokedByUser(Object user) {
    return '$user がメッセージを取り消しました';
  }

  @override
  String groupMemberJoined(Object user) {
    return '$user がグループに参加しました';
  }

  @override
  String groupMemberInvited(Object operator, Object users) {
    return '$operator が $users をグループに招待しました';
  }

  @override
  String groupMemberQuit(Object user) {
    return '$user がグループを退出しました';
  }

  @override
  String groupMemberKicked(Object operator, Object users) {
    return '$operator が $users をグループから削除しました';
  }

  @override
  String groupAdminSet(Object users) {
    return '$users が管理者に設定されました';
  }

  @override
  String groupAdminCancelled(Object users) {
    return '$users の管理者権限が取り消されました';
  }

  @override
  String groupMessagePinned(Object user) {
    return '$user がメッセージをピン留めしました';
  }

  @override
  String groupMessageUnpinned(Object user) {
    return '$user がメッセージのピン留めを解除しました';
  }

  @override
  String get you => 'あなた';

  @override
  String get muted => 'ミュートされました';

  @override
  String get unmuted => 'ミュートが解除されました';

  @override
  String get day => '日';

  @override
  String get hour => '時間';

  @override
  String get min => '分';

  @override
  String get second => '秒';

  @override
  String get messageTypeImage => '[画像]';

  @override
  String get messageTypeVoice => '[音声]';

  @override
  String get messageTypeFile => '[ファイル]';

  @override
  String get messageTypeVideo => '[動画]';

  @override
  String get messageTypeSticker => '[スタンプ]';

  @override
  String get messageTypeCustom => '[カスタムメッセージ]';

  @override
  String get groupNameChangedTo => 'グループ名を変更しました：';

  @override
  String get groupIntroChangedTo => 'グループ紹介を変更しました：';

  @override
  String get groupNoticeChangedTo => 'グループ通知を変更しました：';

  @override
  String get groupNoticeDeleted => 'グループ通知を削除しました';

  @override
  String get groupAvatarChanged => 'グループアバターを変更しました';

  @override
  String get groupOwnerTransferredTo => 'グループオーナーを譲渡しました：';

  @override
  String get groupMuteAllEnabled => '全員ミュートを有効にしました';

  @override
  String get groupMuteAllDisabled => '全員ミュートを無効にしました';

  @override
  String get unknown => '不明';

  @override
  String get groupJoinMethodChangedTo => '参加方法を変更しました：';

  @override
  String get groupInviteMethodChangedTo => '招待方法を変更しました：';

  @override
  String get weekdaySunday => '日';

  @override
  String get weekdayMonday => '月';

  @override
  String get weekdayTuesday => '火';

  @override
  String get weekdayWednesday => '水';

  @override
  String get weekdayThursday => '木';

  @override
  String get weekdayFriday => '金';

  @override
  String get weekdaySaturday => '土';

  @override
  String get userID => 'ユーザーID';

  @override
  String get album => 'アルバム';

  @override
  String get file => 'ファイル';

  @override
  String get takeAPhoto => '写真';

  @override
  String get recordAVideo => 'ビデオ';

  @override
  String get send => '送信';

  @override
  String get sendSoundTips => '長押しすると話します。離すと送信します。';

  @override
  String get more => 'もっと';

  @override
  String get delete => '削除';

  @override
  String get clearMessage => 'チャット履歴を消去';

  @override
  String get pin => 'チャットをピン留め';

  @override
  String get unpin => 'ピン留めを解除';

  @override
  String get startConversation => 'セッションを開始する';

  @override
  String get createGroupChat => 'グループチャットを作成する';

  @override
  String get addFriend => '友達を追加';

  @override
  String get addGroup => 'グループを追加';

  @override
  String get createGroupTips => 'グループの作成';

  @override
  String get createCommunity => 'コミュニティを作成する';

  @override
  String get groupIDInvalid => 'グループIDが無効です。グループIDが正しく入力されているか確認してください。';

  @override
  String get communityIDEditFormatTips =>
      'コミュニティ ID には接頭辞として @TGS#_ を付ける必要があります。';

  @override
  String get groupIDEditFormatTips => 'グループ ID プレフィックスを @TGS# にすることはできません。';

  @override
  String get groupIDEditExceedTips => 'グループ ID は最大 48 バイトです。';

  @override
  String get productDocumentation => '製品ドキュメントを表示する';

  @override
  String get create => '作成する';

  @override
  String get groupName => 'グループ名';

  @override
  String get groupIDOption => 'グループID (オプション)';

  @override
  String get groupFaceUrl => 'グループアバター';

  @override
  String get groupMemberSelected => '選択されたグループメンバー';

  @override
  String get groupWorkType => 'お疲れ様グループ（仕事）';

  @override
  String get groupPublicType => 'ストレンジャー ソーシャル グループ (パブリック)';

  @override
  String get groupMeetingType => '臨時会議グループ（会議）';

  @override
  String get groupCommunityType => 'コミュニティ';

  @override
  String get groupWorkDesc =>
      '友達ワークグループ（Work）：通常のWeChatグループと同様に、作成後はすでにグループに参加している友達のみをグループに招待でき、招待された側の同意やグループの承認は必要ありません。所有者。';

  @override
  String get groupPublicDesc =>
      '見知らぬソーシャル グループ (パブリック): QQ グループと同様に、グループ所有者は作成後にグループ管理者を指定できます。ユーザーがグループ ID を検索してグループへの参加申請を開始した後、グループに参加する前にグループ所有者または管理者の承認が必要です。 。';

  @override
  String get groupMeetingDesc =>
      '一時的な会議グループ (会議): 作成後は自由に出入りでき、グループに参加する前にメッセージの表示をサポートするため、音声会議やビデオ会議のシナリオ、オンライン教育のシナリオ、およびリアルタイム音声と組み合わせたその他のシナリオに適しています。そしてビデオ製品。';

  @override
  String get groupCommunityDesc =>
      'コミュニティ: 作成後は自由に参加および退出でき、最大 100,000 人のユーザーがグループ ID を検索してグループ アプリケーションを開始すると、管理者の承認なしでグループに参加できます。';

  @override
  String get groupDetail => 'グループチャットの詳細';

  @override
  String get transferGroupOwner => 'グループ所有者を転送する';

  @override
  String get privateGroup => 'ディスカッショングループ';

  @override
  String get publicGroup => 'パブリックグループ';

  @override
  String get chatRoom => 'チャットルーム';

  @override
  String get communityGroup => 'コミュニティ';

  @override
  String get groupOfAnnouncement => 'グループ通知';

  @override
  String get groupManagement => 'グループ管理';

  @override
  String get groupType => 'グループタイプ';

  @override
  String get addGroupWay => 'グループに参加するための積極的な方法';

  @override
  String get inviteGroupType => 'グループに招待する方法';

  @override
  String get myAliasInGroup => 'グループ内の私のエイリアス';

  @override
  String get doNotDisturb => 'メッセージを邪魔しないでください';

  @override
  String get groupMember => 'グループメンバー';

  @override
  String get profileRemark => '備考';

  @override
  String get groupEdit => '編集';

  @override
  String get blackList => 'ブラックリスト';

  @override
  String get profileBlack => 'ブラックリストに追加';

  @override
  String get deleteFriend => '友達を削除する';

  @override
  String get search => '検索';

  @override
  String get chatHistory => 'チャット履歴';

  @override
  String get groups => 'グループ';

  @override
  String get newFriend => '新しい連絡先';

  @override
  String get myGroups => '私のグループチャット';

  @override
  String get contactInfo => '詳細';

  @override
  String get includeGroupMembers => '含まれるメンバー:';

  @override
  String get tuiEmojiSmile => '[微笑]';

  @override
  String get tuiEmojiExpect => '[期待]';

  @override
  String get tuiEmojiBlink => '[ウィンク]';

  @override
  String get tuiEmojiGuffaw => '[大笑い]';

  @override
  String get tuiEmojiKindSmile => '[おばさん笑い]';

  @override
  String get tuiEmojiHaha => '[ははは]';

  @override
  String get tuiEmojiCheerful => '[楽しい]';

  @override
  String get tuiEmojiSpeechless => '[呆れ]';

  @override
  String get tuiEmojiAmazed => '[驚き]';

  @override
  String get tuiEmojiSorrow => '[悲しみ]';

  @override
  String get tuiEmojiComplacent => '[得意げ]';

  @override
  String get tuiEmojiSilly => '[バカ]';

  @override
  String get tuiEmojiLustful => '[色気]';

  @override
  String get tuiEmojiGiggle => '[にこにこ笑い]';

  @override
  String get tuiEmojiKiss => '[キス]';

  @override
  String get tuiEmojiWail => '[大泣き]';

  @override
  String get tuiEmojiTearsLaugh => '[泣き笑い]';

  @override
  String get tuiEmojiTrapped => '[困った]';

  @override
  String get tuiEmojiMask => '[マスク]';

  @override
  String get tuiEmojiFear => '[恐怖]';

  @override
  String get tuiEmojiBareTeeth => '[牙をむく]';

  @override
  String get tuiEmojiFlareUp => '[怒り]';

  @override
  String get tuiEmojiYawn => '[あくび]';

  @override
  String get tuiEmojiTact => '[機知]';

  @override
  String get tuiEmojiStareyes => '[星目]';

  @override
  String get tuiEmojiShutUp => '[黙れ]';

  @override
  String get tuiEmojiSigh => '[ため息]';

  @override
  String get tuiEmojiHehe => '[へへ]';

  @override
  String get tuiEmojiSilent => '[静か]';

  @override
  String get tuiEmojiSurprised => '[驚喜]';

  @override
  String get tuiEmojiAskance => '[白目]';

  @override
  String get tuiEmojiOk => '[OK]';

  @override
  String get tuiEmojiShit => '[うんち]';

  @override
  String get tuiEmojiMonster => '[モンスター]';

  @override
  String get tuiEmojiDaemon => '[悪魔]';

  @override
  String get tuiEmojiRage => '[悪魔の怒り]';

  @override
  String get tuiEmojiFool => '[ダメ]';

  @override
  String get tuiEmojiPig => '[豚]';

  @override
  String get tuiEmojiCow => '[牛]';

  @override
  String get tuiEmojiAi => '[AI]';

  @override
  String get tuiEmojiSkull => '[骸骨]';

  @override
  String get tuiEmojiBombs => '[爆弾]';

  @override
  String get tuiEmojiCoffee => '[コーヒー]';

  @override
  String get tuiEmojiCake => '[ケーキ]';

  @override
  String get tuiEmojiBeer => '[ビール]';

  @override
  String get tuiEmojiFlower => '[花]';

  @override
  String get tuiEmojiWatermelon => '[スイカ]';

  @override
  String get tuiEmojiRich => '[お金持ち]';

  @override
  String get tuiEmojiHeart => '[ハート]';

  @override
  String get tuiEmojiMoon => '[月]';

  @override
  String get tuiEmojiSun => '[太陽]';

  @override
  String get tuiEmojiStar => '[星]';

  @override
  String get tuiEmojiRedPacket => '[レッドパケット]';

  @override
  String get tuiEmojiCelebrate => '[祝賀]';

  @override
  String get tuiEmojiBless => '[福]';

  @override
  String get tuiEmojiFortune => '[発財]';

  @override
  String get tuiEmojiConvinced => '[納得]';

  @override
  String get tuiEmojiProhibit => '[禁止]';

  @override
  String get tuiEmoji666 => '[666]';

  @override
  String get tuiEmoji857 => '[857]';

  @override
  String get tuiEmojiKnife => '[ナイフ]';

  @override
  String get tuiEmojiLike => '[いいね]';

  @override
  String get sendMessage => 'メッセージを送信';

  @override
  String get addMembers => 'メンバー追加';

  @override
  String get quitGroup => 'グループチャットを終了する';

  @override
  String get dismissGroup => 'グループを解散する';

  @override
  String get groupNoticeEmpty => 'グループの発表はまだありません';

  @override
  String get next => '次へ';

  @override
  String get agree => '承認';

  @override
  String get accept => '承認';

  @override
  String get refuse => '拒否';

  @override
  String get noFriendApplicationList => '新しい連絡先リクエストはありません';

  @override
  String get noBlackList => 'ブラックリストに登録されたユーザーはいない';

  @override
  String get noGroupList => 'グループチャットなし';

  @override
  String get noGroupApplicationList => 'グループ申請はまだありません';

  @override
  String get groupChatNotifications => 'グループチャット通知';

  @override
  String get invite => '招待する';

  @override
  String get groupApplicationAllReadyBeenProcessed =>
      'この招待または申請リクエストはすでに処理されています。';

  @override
  String get accepted => '同意します';

  @override
  String get refused => '拒否';

  @override
  String get copy => 'コピー';

  @override
  String get recall => 'リコール';

  @override
  String get forward => '転送';

  @override
  String get quote => '引用';

  @override
  String get reply => '返信';

  @override
  String get searchUserID => 'ユーザーIDを入力してユーザーを検索してください';

  @override
  String get searchGroupID => 'グループIDを検索';

  @override
  String get searchGroupIDHint => 'グループIDを入力してグループを検索してください';

  @override
  String get addFailed => '友達の追加に失敗しました';

  @override
  String get joinGroupFailed => 'グループへの参加に失敗しました';

  @override
  String get alreadyInGroup => 'すでにグループに参加しています';

  @override
  String get alreadyFriend => 'すでに友達';

  @override
  String get signature => '自己紹介';

  @override
  String get searchError => '検索エラー';

  @override
  String get fillInTheVerificationInformation => '確認情報を入力してください';

  @override
  String get joinedGroupSuccessfully => '成功';

  @override
  String get contactAddedSuccessfully => '連絡先が正常に追加されました';

  @override
  String get message => 'メッセージ';

  @override
  String get groupWork => '作業グループ';

  @override
  String get groupPublic => '公開グループ';

  @override
  String get groupMeeting => 'ミーティンググループ';

  @override
  String get groupCommunity => 'コミュニティ';

  @override
  String get groupAVChatRoom => 'ライブ放送グループ';

  @override
  String get groupAddAny => '自動承認';

  @override
  String get groupAddAuth => '管理者の承認';

  @override
  String get groupAddForbid => 'グループへの参加は禁止です';

  @override
  String get groupInviteForbid => '招待なし';

  @override
  String get groupOwner => 'グループのオーナー';

  @override
  String get member => 'メンバー';

  @override
  String get admin => '管理者';

  @override
  String get modifyGroupName => 'グループ名を変更する';

  @override
  String get groupNickname => '私のグループのニックネーム';

  @override
  String get modifyGroupNickname => 'グループのニックネームを変更する';

  @override
  String get modifyGroupNoticeSuccess => 'グループのお知らせを変更しました';

  @override
  String get quitGroupTip => 'このグループを脱退してもよろしいですか?';

  @override
  String get dismissGroupTip => 'このグループを解散してもよろしいですか?';

  @override
  String get clearMsgTip => 'チャット履歴を消去しますか?';

  @override
  String get muteAll => '全員がミュートされている';

  @override
  String get addMuteMemberTip => 'ミュートするグループメンバーを追加する';

  @override
  String get groupMuteTip => 'ミュート機能を有効にすると、グループの所有者と管理者のみが発言できるようになります。';

  @override
  String get deleteFriendTip => '連絡先を削除しますか?';

  @override
  String get remarkEdit => '変更点';

  @override
  String get detail => '詳細';

  @override
  String get setAdmin => '管理者として設定';

  @override
  String get cancelAdmin => 'キャンセル管理者';

  @override
  String get deleteGroupMemberTip => 'グループメンバーを削除しますか?';

  @override
  String get settingSuccess => 'セットアップに成功しました!';

  @override
  String get settingFail => 'セットアップに失敗しました!';

  @override
  String get noMore => 'もうない';

  @override
  String get sayTimeShort => '話す時間が短すぎる';

  @override
  String get recordLimitTips => 'スピーチの最大長に達しました';

  @override
  String get on => '開ける';

  @override
  String get off => '近い';

  @override
  String get chooseAvatar => 'アバターを選択';

  @override
  String get inputGroupName => 'グループ名を入力してください';

  @override
  String get error => '間違い';

  @override
  String get permissionNeeded => '必要な権限';

  @override
  String get permissionDeniedContent => '「設定」に移動して写真の権限を有効にしてください。';

  @override
  String maxCountFile(Object maxCount) {
    return '選択できるファイルは最大 $maxCount 個までです';
  }

  @override
  String get groupIntroDeleted => 'グループプロフィールを削除しました';

  @override
  String get groupJoinForbidden => '参加禁止';

  @override
  String get groupJoinApproval => '管理者承認が必要';

  @override
  String get groupJoinFree => '自由参加';

  @override
  String get groupInviteForbidden => '招待禁止';

  @override
  String get groupInviteApproval => '管理者承認が必要';

  @override
  String get groupInviteFree => '自由招待';

  @override
  String get mergeMessage => 'メッセージを結合する';

  @override
  String get upgradeLatestVersion => '最新バージョンにアップグレードしてください';

  @override
  String get friendLimit => '友達の数がシステムの制限に達しました';

  @override
  String get otherFriendLimit => '相手の友達数がシステムの上限に達しています';

  @override
  String get inBlacklist => 'ブラックリストに友達として追加される';

  @override
  String get setInBlacklist => '相手からブラックリストに登録されている';

  @override
  String get forbidAddFriend => '相手が友達追加を禁止されている';

  @override
  String get waitAgreeFriend => '友達からのレビューと承認を待っています';

  @override
  String get haveBeFriend => '相手はすでにあなたの友達です';

  @override
  String get addGroupPermissionDeny => 'グループへの参加は禁止です';

  @override
  String get addGroupAlreadyMember => 'すでにグループメンバーです';

  @override
  String get addGroupNotFound => 'グループが存在しません';

  @override
  String get addGroupFullMember => 'グループは満員です';

  @override
  String chatRecords(Object count) {
    return '$count 件の関連レコード录';
  }

  @override
  String get addRule => 'お問い合わせリクエスト';

  @override
  String get allowAny => '誰でも許可';

  @override
  String get denyAny => '誰でも拒否';

  @override
  String get needConfirm => '確認が必要';

  @override
  String get noSignature => 'まだ署名なし';

  @override
  String get gender => '性別';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get birthday => '誕生日';

  @override
  String get setNickname => 'ニックネームを編集';

  @override
  String get setSignature => '署名を編集';

  @override
  String get messageNum => '件';

  @override
  String get sendMessageFail => '送信に失敗しました';

  @override
  String get resendTips => '再送信してもよろしいですか?';

  @override
  String get callRejectCaller => '相手が拒否しました';

  @override
  String get callRejectCallee => '拒否されました';

  @override
  String get callCancelCaller => 'キャンセル';

  @override
  String get callCancelCallee => '相手がキャンセルした';

  @override
  String get stopCallTip => '通話時間';

  @override
  String get callTimeoutCaller => '相手からの応答がありません';

  @override
  String get callTimeoutCallee => '応答なしでタイムアウトする';

  @override
  String get callLineBusyCaller => '相手は忙しいです';

  @override
  String get callLineBusyCallee => '話し中のため応答なし';

  @override
  String get startCall => '通話を開始する';

  @override
  String get acceptCall => '答えた';

  @override
  String get callingSwitchToAudio => 'ビデオから音声へ';

  @override
  String get callingSwitchToAudioAccept => 'ビデオから音声への変換を確認する';

  @override
  String get invalidCommand => '認識できない呼び出しコマンド';

  @override
  String get groupCallSend => 'グループ通話が始まりました';

  @override
  String get groupCallEnd => '通話が終了しました';

  @override
  String get groupCallNoAnswer => '答えはありません';

  @override
  String get groupCallReject => 'グループ通話を拒否する';

  @override
  String get groupCallAccept => '答え';

  @override
  String get groupCallConfirmSwitchToAudio => '動画を音声に変換することに同意する';

  @override
  String get unknownCall => '不明な電話';

  @override
  String get join => '参加する';

  @override
  String peopleOnCall(Object number) {
    return '$numberは現在通話中です。';
  }
}
