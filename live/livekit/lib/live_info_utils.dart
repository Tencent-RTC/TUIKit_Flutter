import 'package:atomic_x_core/api/live/live_list_store.dart';

class LiveInfoUtils {
  static SeatLayoutTemplate convertToSeatLayoutTemplateByID(int templateByID) {
    switch(templateByID) {
      case 600:
        return const VideoDynamicGrid9Seats();
      case 601:
        return const VideoDynamicFloat7Seats();
      case 800:
        return const VideoFixedGrid9Seats();
      case 801:
        return const VideoFixedFloat7Seats();
      case 200:
        return const VideoLandscape4Seats();
      default:
        return const VideoDynamicGrid9Seats();
    }
  }
}