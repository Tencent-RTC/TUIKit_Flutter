import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

/// How fast the typewriter reveals text, in graphemes per second.
class TypewriterPacing {
  const TypewriterPacing({
    this.baseRate = 25,
    this.catchUpGain = 0.4,
    this.maxRate = 60,
  })  : assert(baseRate > 0),
        assert(catchUpGain >= 0),
        assert(maxRate >= baseRate);

  /// Floor of the display rate, in characters per second.
  ///
  /// 显示速率下限，单位：字数/秒。没有积压时按这个速度打字。
  final double baseRate;

  /// Characters per second added to the rate for each character still pending.
  ///
  /// 追赶增益：每积压 1 个字，速率增加的字数/秒。积压越多打得越快。
  final double catchUpGain;

  /// Ceiling of the display rate, in characters per second.
  ///
  /// 显示速率上限，单位：字数/秒。追赶再快也不会超过这个值。
  final double maxRate;
}

/// Where a stream message sits between "still arriving" and "fully shown".
///
/// The stream ending and the reveal finishing are two different moments: when
/// the last chunk lands there is usually still a backlog to reveal, and
/// dumping it all at once undoes the effect. [draining] is that gap.
enum TypewriterPhase { streaming, draining, done }

/// Paces the reveal of a stream message's text.
///
/// `StreamMessagePayload.markdown` carries the whole text received so far, not
/// a delta — the IM SDK accumulates chunks internally before notifying. So the
/// reveal is a cursor chasing a growing target rather than an append log,
/// which keeps network jitter out of the animation.
///
/// Time comes in through [advance] instead of an internal timer, so tests can
/// feed deterministic slices without a ticker or a widget tree.
class TypewriterController extends ChangeNotifier {
  TypewriterController({TypewriterPacing? pacing})
      : _pacing = pacing ?? const TypewriterPacing();

  final TypewriterPacing _pacing;

  String _targetText = '';

  /// Target split into grapheme clusters. Revealing by UTF-16 code unit would
  /// cut surrogate pairs and combining sequences — skin-tone modifiers, flags,
  /// family emoji — in half, and the fragment renders as a replacement box.
  List<String> _graphemes = const [];

  int _revealed = 0;

  /// Fractional graphemes carried between frames.
  ///
  /// Not an optimisation: at 45 graphemes/s a 16ms frame earns 0.72 of a
  /// grapheme, which floors to zero. Without carrying the remainder the reveal
  /// would never advance past the first character.
  double _carry = 0;

  bool _streamEnded = false;

  String? _visibleCache;

  String get visibleText => _visibleCache ??= _graphemes.take(_revealed).join();

  int get revealedCount => _revealed;

  int get targetCount => _graphemes.length;

  int get pendingCount => _graphemes.length - _revealed;

  /// Derived rather than stored, so no transition can be missed or applied
  /// twice — including a late chunk arriving after the stream was marked
  /// ended, which simply reads as [streaming] again.
  TypewriterPhase get phase {
    if (!_streamEnded) return TypewriterPhase.streaming;
    return pendingCount > 0 ? TypewriterPhase.draining : TypewriterPhase.done;
  }

  /// Feeds in the text received so far. Idempotent.
  void sync({required String fullText, required bool isStreamEnded}) {
    var changed = false;

    if (fullText != _targetText) {
      _targetText = fullText;
      _graphemes = fullText.characters.toList();
      _visibleCache = null;
      // A shorter target shouldn't happen, but clamping here keeps the reveal
      // index in range instead of throwing on the next `take`.
      if (_revealed > _graphemes.length) {
        _revealed = _graphemes.length;
        _carry = 0;
      }
      changed = true;
    }

    if (isStreamEnded != _streamEnded) {
      _streamEnded = isStreamEnded;
      changed = true;
    }

    if (changed) notifyListeners();
  }

  /// Advances the reveal by the time elapsed since the last call.
  void advance(Duration delta) {
    if (delta <= Duration.zero || pendingCount == 0) return;

    final rate = (_pacing.baseRate + pendingCount * _pacing.catchUpGain)
        .clamp(_pacing.baseRate, _pacing.maxRate);
    final step = rate * delta.inMicroseconds / Duration.microsecondsPerSecond + _carry;
    final whole = step.floor();
    _carry = step - whole;

    if (whole <= 0) return;

    _revealed = (_revealed + whole).clamp(0, _graphemes.length);
    _visibleCache = null;
    notifyListeners();
  }

  /// Reveals everything immediately, skipping the animation.
  void snapToEnd() {
    _carry = 0;
    if (_revealed == _graphemes.length) return;
    _revealed = _graphemes.length;
    _visibleCache = null;
    notifyListeners();
  }
}
