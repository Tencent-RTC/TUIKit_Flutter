enum LiveStreamPrivacyStatus { public, privacy }

enum LiveStatus { none, previewing, pushing, playing, finished }

enum LiveTemplateMode {
  horizontalDynamic(id: 200),
  verticalDynamicGrid(id: 600),
  verticalDynamicFloat(id: 601),
  verticalStaticGrid(id: 800),
  verticalStaticFloat(id: 801);

  final int id;

  const LiveTemplateMode({required this.id});
}

enum VideoStreamSource {
  camera(id: 0),
  screenShare(id: 1);

  final int id;

  const VideoStreamSource({required this.id});
}