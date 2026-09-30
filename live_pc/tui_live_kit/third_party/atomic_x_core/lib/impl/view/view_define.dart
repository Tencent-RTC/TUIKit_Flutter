enum VideoStreamTypeBridge {
  cameraStream(0),
  cameraStreamLow(1),
  screenStream(2);

  final int value;

  const VideoStreamTypeBridge(this.value);
}
