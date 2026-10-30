import 'dart:collection';
import 'dart:typed_data';

/// 会话就绪前那段音频的缓冲：有界、溢出丢最旧。
///
/// 采集从按下第一帧就开始，而建会话要一个网络往返。这期间说的话不能丢，所以先把
/// Opus packet 攒在这里，会话一就绪就补推，实时音频接在后面。
class RealtimeAsrPacketBuffer {
  RealtimeAsrPacketBuffer(this.capacity) : assert(capacity > 0);

  final int capacity;
  final Queue<Uint8List> _packets = Queue<Uint8List>();

  int get size => _packets.length;

  void append(Uint8List packet) {
    while (_packets.length >= capacity) {
      _packets.removeFirst();
    }
    _packets.addLast(packet);
  }

  void clear() => _packets.clear();

  /// 取走全部内容并清空，保持先进先出的时间顺序。
  List<Uint8List> drain() {
    if (_packets.isEmpty) {
      return const [];
    }
    final drained = _packets.toList();
    _packets.clear();
    return drained;
  }
}
