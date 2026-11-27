import 'dart:async';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' as chat;
import '../common/app_strings.dart';
import '../login/login_store.dart';
import '../live/home/live_home_view.dart';
import 'home_tab_bar.dart';
import '../mine/mine_view.dart';
import '../chat/home_messages_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.auth, required this.locale});
  final AppLoginStore auth;
  final chat.LocaleProvider locale;
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _keys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _depth = List.filled(5, 1);
  late final _observers = List.generate(5, (index) => _BranchObserver((depth) => _updateDepth(index, depth)));
  void _updateDepth(int index, int depth) {
    if (!mounted || _depth[index] == depth) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateDepth(index, depth));
    } else {
      setState(() => _depth[index] = depth);
    }
  }

  Future<void> _back() async {
    if (_selected == 1 && !_liveEnabled) return;
    final handled = await _keys[_selected].currentState?.maybePop() ?? false;
    if (!handled && mounted && !_liveRoom && Theme.of(context).platform == TargetPlatform.android) {
      await SystemNavigator.pop();
    }
  }

  final _visited = <int>{1};
  final _conversations = ConversationListStore.create();
  final _liveActive = ValueNotifier(true);
  int _selected = 1;
  bool _liveRoom = false;
  bool _liveEnabled = true;
  @override
  void initState() {
    super.initState();
    unawaited(_conversations.loadConversations());
  }

  @override
  void dispose() {
    _liveActive.dispose();
    super.dispose();
  }

  void _select(int value) {
    if (_selected == value || _liveRoom || _selected == 1 && !_liveEnabled) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _liveActive.value = value == 1;
    setState(() {
      _selected = value;
      _visited.add(value);
    });
  }

  Widget _root(int index) {
    switch (index) {
      case 1:
        return ValueListenableBuilder<bool>(
          valueListenable: _liveActive,
          builder: (context, active, child) => LiveHomeView(
            active: active,
            auth: widget.auth,
            onRoomChanged: (value) {
              if (mounted && _liveRoom != value) setState(() => _liveRoom = value);
            },
            onInteractionChanged: (value) {
              if (mounted && _liveEnabled != value) setState(() => _liveEnabled = value);
            },
          ),
        );
      case 3:
        return const HomeMessagesView();
      case 4:
        return MineView(auth: widget.auth, locale: widget.locale);
      default:
        return Scaffold(
          backgroundColor: const Color(0xffebedf5),
          body: SafeArea(
            child: Center(
              child: Text(
                '${AppStrings.of(context, index == 0 ? 'meeting' : 'call')} · ${AppStrings.of(context, 'unavailable')}',
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = _selected == 1;
    final hideBar = dark && _liveRoom || _selected == 3 && _depth[3] > 1;
    final background = dark
        ? const Color(0xff101116)
        : _selected == 3
        ? chat.BaseThemeProvider.colorsOf(context).bgColorOperate
        : _selected == 4 && _depth[4] > 1
        ? Colors.white
        : const Color(0xffebedf5);
    final barHeight = 56 + MediaQuery.viewPaddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_back());
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: background,
          body: Stack(
            children: [
              for (final index in _visited)
                Positioned.fill(
                  key: ValueKey(index),
                  bottom: index == 1 || index == 3 && _depth[3] > 1 ? 0 : barHeight,
                  child: Offstage(
                    offstage: index != _selected,
                    child: TickerMode(
                      enabled: index == _selected,
                      child: Navigator(
                        key: _keys[index],
                        observers: [_observers[index]],
                        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _root(index)),
                      ),
                    ),
                  ),
                ),
              if (!hideBar)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ColoredBox(
                    color: background,
                    child: SafeArea(
                      top: false,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _conversations.state.totalUnreadCount,
                        builder: (context, count, child) => HomeTabBar(
                          selected: _selected,
                          onSelect: _select,
                          unread: count,
                          enabled: !dark || _liveEnabled,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchObserver extends NavigatorObserver {
  _BranchObserver(this.changed);
  final ValueChanged<int> changed;
  final _routes = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    changed(_routes.length);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    changed(_routes.length);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    changed(_routes.length);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0 && newRoute != null) _routes[index] = newRoute;
    changed(_routes.length);
  }
}
