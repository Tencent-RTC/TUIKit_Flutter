import '../index.dart';

class ErrorLocalized {
  static String convertToErrorMessage(int code, String? message) {
    final roomError = RoomError.fromInt(code);
    if (roomError != null) {
      return roomError.description ?? "code: $code, message: $message";
    }
    return "code: $code, message: $message";
  }
}

enum RoomError {
  success(0),
  freqLimit(-2),
  repeatOperation(-3),
  roomMismatch(-4),
  sdkAppIDNotFound(-1000),
  invalidParameter(-1001),
  sdkNotInitialized(-1002),
  permissionDenied(-1003),
  requirePayment(-1004),
  cameraStartFail(-1100),
  cameraNotAuthorized(-1101),
  cameraOccupied(-1102),
  cameraDeviceEmpty(-1103),
  microphoneStartFail(-1104),
  microphoneNotAuthorized(-1105),
  microphoneOccupied(-1106),
  microphoneDeviceEmpty(-1107),
  getScreenSharingTargetFailed(-1108),
  startScreenSharingFailed(-1109),
  operationInvalidBeforeEnterRoom(-2101),
  exitNotSupportedForRoomOwner(-2102),
  operationNotSupportedInCurrentRoomType(-2103),
  roomIdInvalid(-2105),
  roomNameInvalid(-2107),
  alreadyInOtherRoom(-2108),
  userNotExist(-2200),
  userNeedOwnerPermission(-2300),
  userNeedAdminPermission(-2301),
  requestNoPermission(-2310),
  requestIdInvalid(-2311),
  requestIdRepeat(-2312),
  maxSeatCountLimit(-2340),
  seatIndexNotExist(-2344),
  openMicrophoneNeedSeatUnlock(-2360),
  openMicrophoneNeedPermissionFromAdmin(-2361),
  openCameraNeedSeatUnlock(-2370),
  openCameraNeedPermissionFromAdmin(-2371),
  openScreenShareNeedSeatUnlock(-2372),
  openScreenShareNeedPermissionFromAdmin(-2373),
  sendMessageDisabledForAll(-2380),
  sendMessageDisabledForCurrent(-2381),
  roomNotSupportPreloading(-4001),
  invalidUserId(7002),
  hasBeenMuted(10017),
  systemInternalError(100001),
  paramIllegal(100002),
  roomIdOccupied(100003),
  roomIdNotExist(100004),
  userNotEntered(100005),
  insufficientOperationPermissions(100006),
  noPaymentInformation(100007),
  roomIsFull(100008),
  tagQuantityExceedsUpperLimit(100009),
  roomIdHasBeenUsed(100010),
  roomIdHasBeenOccupiedByChat(100011),
  creatingRoomsExceedsTheFrequencyLimit(100012),
  exceedsTheUpperLimit(100013),
  invalidRoomType(100015),
  memberHasBeenBanned(100016),
  memberHasBeenMuted(100017),
  requiresPassword(100018),
  roomEntryPasswordError(100019),
  roomAdminQuantityExceedsTheUpperLimit(100020),
  requestIdConflict(100102),
  seatLocked(100200),
  seatOccupied(100201),
  alreadyOnTheSeatQueue(100202),
  alreadyInSeat(100203),
  notOnTheSeatQueue(100204),
  allSeatOccupied(100205),
  userNotInSeat(100206),
  userAlreadyOnSeat(100210),
  seatNotSupportLinkMic(100211),
  emptySeatList(100251),
  connectionNotExist(100400),
  roomInConnection(100401),
  pendingConnectionRequest(100402),
  roomConnectedInOther(100403),
  connectionOrBattleLimitExceeded(100404),
  creatingConnectionTooFrequent(100405),
  battleNotExistOrEnded(100411),
  noRoomsInBattleIsValid(100412),
  creatingBattleTooFrequently(100413),
  roomNotInBattle(100414),
  inOtherBattle(100415),
  pendingBattleRequest(100416),
  notAllowedCancelBattleForRoomInBattle(100419),
  battleNotStart(100420),
  battleHasEnded(100421),
  metadataKeyExceedsLimit(100500),
  metadataValueSizeExceedsByteLimit(100501),
  metadataTotalValueSizeExceedsByteLimit(100502),
  metadataNoValidKey(100503),
  metadataKeySizeExceedsByteLimit(100504);

  final int code;

  const RoomError(this.code);

  static RoomError? fromInt(int code) {
    for (var enumValue in RoomError.values) {
      if (enumValue.code == code) return enumValue;
    }
    return null;
  }
}

extension RoomErrorWithLocalization on RoomError {
  String? get description {
    switch (this) {
      case RoomError.success: // 0
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_0_success;
      case RoomError.freqLimit: // -2
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2_request_rate_limited;
      case RoomError.repeatOperation: // -3
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n3_repeat_operation;
      case RoomError.roomMismatch: // -4
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n4_roomID_not_match;
      case RoomError.sdkAppIDNotFound: // -1000
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1000_sdk_appid_not_found;
      case RoomError.invalidParameter: // -1001
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1001_invalid_parameter;
      case RoomError.sdkNotInitialized: // -1002
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1002_not_logged_in;
      case RoomError.permissionDenied: // -1003
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1003_permission_denied;
      case RoomError.requirePayment: // -1004
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1004_package_required;
      case RoomError.cameraStartFail: // -1100
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1100_camera_open_failed;
      case RoomError.cameraNotAuthorized: // -1101
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1101_camera_no_permission;
      case RoomError.cameraOccupied: // -1102
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1102_camera_occupied;
      case RoomError.cameraDeviceEmpty: // -1103
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1103_camera_not_found;
      case RoomError.microphoneStartFail: // -1104
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1104_mic_open_failed;
      case RoomError.microphoneNotAuthorized: // -1105
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1105_mic_no_permission;
      case RoomError.microphoneOccupied: // -1106
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1106_mic_occupied;
      case RoomError.microphoneDeviceEmpty: // -1107
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1107_mic_not_found;
      case RoomError.getScreenSharingTargetFailed: // -1108
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1108_screen_share_get_source_failed;
      case RoomError.startScreenSharingFailed: // -1109
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n1109_screen_share_start_failed;
      case RoomError.operationInvalidBeforeEnterRoom: // -2101
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2101_not_in_room;
      case RoomError.exitNotSupportedForRoomOwner: // -2102
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2102_owner_cannot_leave;
      case RoomError.operationNotSupportedInCurrentRoomType: // -2103
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2103_unsupported_in_room_type;
      case RoomError.roomIdInvalid: // -2105
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2105_invalid_room_id;
      case RoomError.roomNameInvalid: // -2107
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2107_invalid_room_name;
      case RoomError.alreadyInOtherRoom: // -2108
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2108_user_already_in_other_room;
      case RoomError.userNotExist: // -2200
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2200_user_not_exist;
      case RoomError.userNeedOwnerPermission: // -2300
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2300_need_owner_permission;
      case RoomError.userNeedAdminPermission: // -2301
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2301_need_admin_permission;
      case RoomError.requestNoPermission: // -2310
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2310_signal_no_permission;
      case RoomError.requestIdInvalid: // -2311
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2311_signal_invalid_request_id;
      case RoomError.requestIdRepeat: // -2312
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2312_signal_request_duplicated;
      case RoomError.maxSeatCountLimit: // -2340
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2340_seat_count_limit_exceeded;
      case RoomError.seatIndexNotExist: // -2344
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2344_seat_not_exist;
      case RoomError.openMicrophoneNeedSeatUnlock: // -2360
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2360_seat_audio_locked;
      case RoomError.openMicrophoneNeedPermissionFromAdmin: // -2361
        return RoomLocalizations.of(Global.appContext())?.roomkit_tip_all_muted_cannot_unmute;
      case RoomError.openCameraNeedSeatUnlock: // -2370
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2370_seat_video_locked;
      case RoomError.openCameraNeedPermissionFromAdmin: // -2371
        return RoomLocalizations.of(Global.appContext())?.roomkit_tip_all_video_off_cannot_start;
      case RoomError.openScreenShareNeedSeatUnlock: // -2372
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2372_screen_share_seat_locked;
      case RoomError.openScreenShareNeedPermissionFromAdmin: // -2373
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2373_screen_share_need_permission;
      case RoomError.sendMessageDisabledForAll: // -2380
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n2380_all_members_muted;
      case RoomError.sendMessageDisabledForCurrent: // -2381
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_10017_muted_in_room;
      case RoomError.roomNotSupportPreloading: // -4001
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_n4001_room_not_support_preload;
      case RoomError.invalidUserId: // 7002
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_7002_invalid_user_id;
      case RoomError.hasBeenMuted: // 10017
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_10017_muted_in_room;
      case RoomError.systemInternalError: // 100001
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100001_server_internal_error;
      case RoomError.paramIllegal: // 100002
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100002_server_invalid_parameter;
      case RoomError.roomIdOccupied: // 100003
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100003_room_id_already_exists;
      case RoomError.roomIdNotExist: // 100004
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100004_room_not_exist;
      case RoomError.userNotEntered: // 100005
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100005_not_room_member;
      case RoomError.insufficientOperationPermissions: // 100006
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100006_operation_not_allowed;
      case RoomError.noPaymentInformation: // 100007
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100007_no_payment_info;
      case RoomError.roomIsFull: // 100008
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100008_room_is_full;
      case RoomError.tagQuantityExceedsUpperLimit: // 100009
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100009_room_tag_limit_exceeded;
      case RoomError.roomIdHasBeenUsed: // 100010
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100010_room_id_reusable_by_owner;
      case RoomError.roomIdHasBeenOccupiedByChat: // 100011
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100011_room_id_occupied_by_im;
      case RoomError.creatingRoomsExceedsTheFrequencyLimit: // 100012
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100012_create_room_frequency_limit;
      case RoomError.exceedsTheUpperLimit: // 100013
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100013_payment_limit_exceeded;
      case RoomError.invalidRoomType: // 100015
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100015_invalid_room_type;
      case RoomError.memberHasBeenBanned: // 100016
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100016_member_already_banned;
      case RoomError.memberHasBeenMuted: // 100017
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100017_member_already_muted;
      case RoomError.requiresPassword: // 100018
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100018_room_password_required;
      case RoomError.roomEntryPasswordError: // 100019
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100019_room_password_incorrect;
      case RoomError.roomAdminQuantityExceedsTheUpperLimit: // 100020
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100020_admin_limit_exceeded;
      case RoomError.requestIdConflict: // 100102
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100102_signal_request_conflict;
      case RoomError.seatLocked: // 100200
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100200_seat_is_locked;
      case RoomError.seatOccupied: // 100201
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100201_seat_is_occupied;
      case RoomError.alreadyOnTheSeatQueue: // 100202
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100202_already_in_seat_queue;
      case RoomError.alreadyInSeat: // 100203
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100203_already_on_seat;
      case RoomError.notOnTheSeatQueue: // 100204
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100204_not_in_seat_queue;
      case RoomError.allSeatOccupied: // 100205
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100205_all_seats_are_full;
      case RoomError.userNotInSeat: // 100206
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100206_not_on_seat;
      case RoomError.userAlreadyOnSeat: // 100210
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100210_user_already_on_seat;
      case RoomError.seatNotSupportLinkMic: // 100211
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100211_seat_not_supported;
      case RoomError.emptySeatList: // 100251
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100251_seat_list_is_empty;
      case RoomError.metadataKeyExceedsLimit: // 100500
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100500_room_metadata_key_limit;
      case RoomError.metadataValueSizeExceedsByteLimit: // 100501
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100501_room_metadata_value_limit;
      case RoomError.metadataTotalValueSizeExceedsByteLimit: // 100502
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100502_room_metadata_total_limit;
      case RoomError.metadataNoValidKey: // 100503
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100503_room_metadata_no_valid_keys;
      case RoomError.metadataKeySizeExceedsByteLimit: // 100504
        return RoomLocalizations.of(Global.appContext())?.roomkit_err_100504_room_metadata_key_size_limit;
      default:
        return '${RoomLocalizations.of(Global.appContext())?.roomkit_err_general}, code: $code';
    }
  }
}
