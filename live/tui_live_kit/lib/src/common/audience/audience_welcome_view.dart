import 'dart:async';

import 'package:flutter/widgets.dart';

import '../live_kit_resources.dart';
import '../theme/level_badge_view.dart';
import '../theme/live_theme.dart';

class AudienceWelcome {
  const AudienceWelcome({
    required this.userID,
    required this.userName,
    this.level,
  });

  final String userID;
  final String userName;
  final int? level;
}

/// 横幅的命令入口。
class AudienceWelcomeController extends ChangeNotifier {
  final List<AudienceWelcome> _queue = <AudienceWelcome>[];
  AudienceWelcome? _active;
  int _token = 0;

  AudienceWelcome? get active => _active;

  /// 当前这条的播放令牌，用于让横幅在换条时重置动画。
  int get token => _token;

  void enqueue(AudienceWelcome welcome) {
    _queue.add(welcome);
    _showNextIfNeeded();
  }

  void reset() {
    _queue.clear();
    if (_active == null) return;
    _active = null;
    _token += 1;
    notifyListeners();
  }

  void finishActive(int token) {
    if (_token != token || _active == null) return;
    _active = null;
    _token += 1;
    _showNextIfNeeded();
  }

  void _showNextIfNeeded() {
    if (_active != null || _queue.isEmpty) {
      notifyListeners();
      return;
    }
    _active = _queue.removeAt(0);
    _token += 1;
    notifyListeners();
  }
}

class AudienceWelcomeView extends StatefulWidget {
  const AudienceWelcomeView({super.key, required this.controller});

  final AudienceWelcomeController controller;

  static const Size bannerSize = Size(228, 28);
  static const Duration fadeInDuration = Duration(milliseconds: 420);
  static const Duration slideInDuration = Duration(milliseconds: 680);
  static const Duration displayDuration = Duration(milliseconds: 3200);
  static const Duration fadeOutDuration = Duration(milliseconds: 320);
  static const Duration cleanupDelay = Duration(milliseconds: 360);

  @override
  State<AudienceWelcomeView> createState() => _AudienceWelcomeViewState();
}

class _AudienceWelcomeViewState extends State<AudienceWelcomeView> {
  static const double _slideInOffset = -(228.0 + 24.0);
  static const double _slideOutOffset = -30;
  static const Curve _slideInCurve = Cubic(0.18, 0.78, 0.22, 1);

  int _renderedToken = 0;
  double _opacity = 0;
  double _translateX = _slideInOffset;
  Duration _opacityDuration = AudienceWelcomeView.fadeInDuration;
  Duration _translateDuration = AudienceWelcomeView.slideInDuration;
  Curve _translateCurve = _slideInCurve;
  Timer? _displayTimer;
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _syncWithController();
  }

  @override
  void didUpdateWidget(AudienceWelcomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _renderedToken = -1;
      _syncWithController();
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _cleanupTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _syncWithController();
  }

  void _syncWithController() {
    final int token = widget.controller.token;
    if (token == _renderedToken) return;
    _renderedToken = token;
    _displayTimer?.cancel();
    _cleanupTimer?.cancel();

    if (widget.controller.active == null) {
      setState(() {
        _opacity = 0;
        _translateX = _slideInOffset;
      });
      return;
    }

    // 起始态：完全透明并停在左侧屏外，随后同时淡入与滑入。
    setState(() {
      _opacityDuration = Duration.zero;
      _translateDuration = Duration.zero;
      _opacity = 0;
      _translateX = _slideInOffset;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _renderedToken != token) return;
      setState(() {
        _opacityDuration = AudienceWelcomeView.fadeInDuration;
        _translateDuration = AudienceWelcomeView.slideInDuration;
        _translateCurve = _slideInCurve;
        _opacity = 1;
        _translateX = 0;
      });
      _displayTimer = Timer(AudienceWelcomeView.displayDuration, () {
        if (!mounted || _renderedToken != token) return;
        setState(() {
          _opacityDuration = AudienceWelcomeView.fadeOutDuration;
          _translateDuration = AudienceWelcomeView.fadeOutDuration;
          _translateCurve = Curves.easeIn;
          _opacity = 0;
          _translateX = _slideOutOffset;
        });
        _cleanupTimer = Timer(AudienceWelcomeView.cleanupDelay, () {
          if (!mounted || _renderedToken != token) return;
          widget.controller.finishActive(token);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final AudienceWelcome? welcome = widget.controller.active;
    if (welcome == null) return const SizedBox.shrink();
    final _AudienceWelcomeTier tier = _AudienceWelcomeTier.fromLevel(welcome.level ?? 0);
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: _opacityDuration,
            curve: _opacity == 0 ? Curves.easeIn : Curves.easeOut,
            child: AnimatedSlide(
              offset: Offset(_translateX / AudienceWelcomeView.bannerSize.width, 0),
              duration: _translateDuration,
              curve: _translateCurve,
              child: _AudienceWelcomeBanner(welcome: welcome, tier: tier),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudienceWelcomeBanner extends StatelessWidget {
  const _AudienceWelcomeBanner({required this.welcome, required this.tier});

  final AudienceWelcome welcome;
  final _AudienceWelcomeTier tier;

  @override
  Widget build(BuildContext context) {
    final int? level = welcome.level;
    final String userName = welcome.userName.isEmpty ? welcome.userID : welcome.userName;
    return Container(
      width: AudienceWelcomeView.bannerSize.width,
      height: AudienceWelcomeView.bannerSize.height,
      decoration: BoxDecoration(
        color: tier.isBasic ? tier.backgroundColors.first : null,
        gradient: tier.isBasic
            ? null
            : LinearGradient(
                begin: const Alignment(-1, -0.26),
                end: const Alignment(1, 0.26),
                colors: tier.backgroundColors,
                stops: tier.backgroundStops,
              ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: tier.shadowRadius > 0
            ? <BoxShadow>[
                BoxShadow(
                  color: tier.shadowColor.withOpacity(tier.shadowOpacity),
                  blurRadius: tier.shadowRadius,
                ),
              ]
            : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: tier.borderWidth > 0 ? Border.all(color: tier.borderColor, width: tier.borderWidth) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: LayoutBuilder(builder: (context, constraints) {
        final action = LiveKitResources.localizedString('tuilivekit.pusher.living.audience_entered');
        final actionStyle = LiveTheme.textStyle(LiveTextRole.action).copyWith(color: tier.actionTextColor);
        final measurement = TextPainter(
          text: TextSpan(text: action, style: actionStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final badgeWidth = level == null ? 0.0 : LevelBadgeView.sizeForLevel(level).width + 5;
        final available = (constraints.maxWidth - badgeWidth - 6).clamp(0.0, double.infinity);
        final actionWidth = measurement.width.clamp(0.0, available);
        measurement.dispose();
        final nameWidth = (available - actionWidth).clamp(0.0, double.infinity);
        return Row(children: [
          if (level != null) ...[
            LevelBadgeView(level: level),
            const SizedBox(width: 5),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: nameWidth),
            child: Text(userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LiveTheme.textStyle(LiveTextRole.action).copyWith(color: LiveTheme.nickname)),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: actionWidth),
            child: Text(action, maxLines: 1, overflow: TextOverflow.ellipsis, style: actionStyle),
          ),
        ]);
      }),
    );
  }
}

class _AudienceWelcomeTier {
  const _AudienceWelcomeTier._({
    required this.backgroundColors,
    required this.backgroundStops,
    required this.borderWidth,
    required this.borderColor,
    required this.shadowColor,
    required this.shadowOpacity,
    required this.shadowRadius,
    required this.actionTextColor,
    required this.isBasic,
  });

  factory _AudienceWelcomeTier.fromLevel(int level) {
    if (level >= 40) return _elite;
    if (level >= 25) return _premium;
    return _basic;
  }

  final List<Color> backgroundColors;
  final List<double> backgroundStops;
  final double borderWidth;
  final Color borderColor;
  final Color shadowColor;
  final double shadowOpacity;
  final double shadowRadius;
  final Color actionTextColor;
  final bool isBasic;

  static const Color _defaultActionTextColor = Color(0xFFF2F5FA);

  static const _AudienceWelcomeTier _basic = _AudienceWelcomeTier._(
    backgroundColors: <Color>[Color(0x570A0A0F), Color(0x570A0A0F)],
    backgroundStops: <double>[0, 1],
    borderWidth: 0,
    borderColor: Color(0x00000000),
    shadowColor: Color(0x00000000),
    shadowOpacity: 0,
    shadowRadius: 0,
    actionTextColor: _defaultActionTextColor,
    isBasic: true,
  );

  static const _AudienceWelcomeTier _premium = _AudienceWelcomeTier._(
    backgroundColors: <Color>[Color(0xD14F38AB), Color(0xB38040B8), Color(0x8A1F153B)],
    backgroundStops: <double>[0, 0.58, 1],
    borderWidth: 1,
    borderColor: Color(0x33D4AEFF),
    shadowColor: Color(0x00000000),
    shadowOpacity: 0,
    shadowRadius: 0,
    actionTextColor: _defaultActionTextColor,
    isBasic: false,
  );

  static const _AudienceWelcomeTier _elite = _AudienceWelcomeTier._(
    backgroundColors: <Color>[Color(0xD1965C24), Color(0xB887479C), Color(0x8F261A45)],
    backgroundStops: <double>[0, 0.58, 1],
    borderWidth: 1,
    borderColor: Color(0x4DFFE69E),
    shadowColor: Color(0xFFDB9445),
    shadowOpacity: 0.18,
    shadowRadius: 8,
    actionTextColor: Color(0xFFFFF8DD),
    isBasic: false,
  );
}
