import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';

extension LiveInfoExtension on LiveInfo {
  LiveInfo copyWith(
      {String? liveID,
      String? liveName,
      String? notice,
      bool? isMessageDisable,
      bool? isPublicVisible,
      bool? isSeatEnabled,
      bool? keepOwnerOnSeat,
      int? maxSeatCount,
      TakeSeatMode? seatMode,
      SeatLayoutTemplate? seatTemplate,
      int? seatLayoutTemplateID,
      String? coverURL,
      String? backgroundURL,
      List<int>? categoryList,
      int? activityStatus,
      LiveUserInfo? liveOwner,
      int? createTime,
      int? totalViewerCount,
      bool? isGiftEnabled,
      Map<String, String>? metaData}) {
    return LiveInfo(
        liveID: liveID ?? this.liveID,
        liveName: liveName ?? this.liveName,
        notice: notice ?? this.notice,
        isMessageDisable: isMessageDisable ?? this.isMessageDisable,
        isPublicVisible: isPublicVisible ?? this.isPublicVisible,
        isSeatEnabled: isSeatEnabled ?? this.isSeatEnabled,
        keepOwnerOnSeat: keepOwnerOnSeat ?? this.keepOwnerOnSeat,
        maxSeatCount: maxSeatCount ?? this.maxSeatCount,
        seatMode: seatMode ?? this.seatMode,
        seatTemplate: seatTemplate ?? this.seatTemplate,
        seatLayoutTemplateID: seatLayoutTemplateID ?? this.seatLayoutTemplateID,
        coverURL: coverURL ?? this.coverURL,
        backgroundURL: backgroundURL ?? this.backgroundURL,
        categoryList: categoryList ?? this.categoryList,
        activityStatus: activityStatus ?? this.activityStatus,
        liveOwner: liveOwner ?? this.liveOwner,
        createTime: createTime ?? this.createTime,
        totalViewerCount: totalViewerCount ?? this.totalViewerCount,
        isGiftEnabled: isGiftEnabled ?? this.isGiftEnabled,
        metaData: metaData ?? this.metaData);
  }

  bool isVoiceRoom() {
    int templateID = (getSeatConfiguration(seatTemplate)).seatLayoutTemplateID;
    templateID = seatLayoutTemplateID == 600 ? templateID : seatLayoutTemplateID;
    return templateID == 70 || templateID == 50;
  }

  static ({bool isSeatEnabled, int? maxSeatCount, int seatLayoutTemplateID, bool? keepOwnerOnSeat})
      getSeatConfiguration(SeatLayoutTemplate seatTemplate) {
    return switch (seatTemplate) {
      VideoDynamicGrid9Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 600,
          keepOwnerOnSeat: true
        ),
      VideoDynamicFloat7Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 601,
          keepOwnerOnSeat: true
        ),
      VideoLeftFocus9Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 602,
          keepOwnerOnSeat: true
        ),
      VideoUniformGrid9Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 603,
          keepOwnerOnSeat: true
        ),
      VideoFixedGrid9Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 800,
          keepOwnerOnSeat: true
        ),
      VideoFixedFloat7Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 801,
          keepOwnerOnSeat: true
        ),
      VideoLandscape4Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 200,
          keepOwnerOnSeat: true
        ),
      VideoLandscape10Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 201,
          keepOwnerOnSeat: true
        ),
      VideoPortrait10Seats() => (
          isSeatEnabled: true,
          maxSeatCount: null,
          seatLayoutTemplateID: 604,
          keepOwnerOnSeat: true
        ),
      Karaoke(seatCount: final seatCount) => (
          isSeatEnabled: true,
          maxSeatCount: seatCount,
          seatLayoutTemplateID: 50,
          keepOwnerOnSeat: null
        ),
      AudioSalon(seatCount: final seatCount) => (
          isSeatEnabled: true,
          maxSeatCount: seatCount,
          seatLayoutTemplateID: 70,
          keepOwnerOnSeat: null
        ),
    };
  }
}
