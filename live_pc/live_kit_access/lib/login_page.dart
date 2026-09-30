import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_kit_desktop/l10n/live_kit_localizations.dart';
import 'package:tencent_live_kit_desktop/pusher/pusher_style.dart';
import 'package:tencent_live_kit_desktop/tui_live_kit.dart';
import 'generate_test_user_sig.dart';

const LinearGradient _pageGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [PusherStyle.bgBase1, PusherStyle.bgBase2, PusherStyle.bgBase3],
  stops: [0, 0.5, 1],
);

const LinearGradient _loginButtonGradient = LinearGradient(
  colors: [PusherStyle.brand, PusherStyle.brand2],
);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  String? _loggedInUserId;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _startLogin() async {
    if (_isLoggingIn) {
      return;
    }

    final String userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      return;
    }

    final int sdkAppId = GenerateTestUserSig.sdkAppId;
    final String userSig = GenerateTestUserSig.genTestUserSig(userId);
    if (sdkAppId <= 0 || userSig.isEmpty) {
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final handler = await LoginStore.shared.login(
        sdkAppID: sdkAppId,
        userID: userId,
        userSig: userSig,
      );

      if (!mounted) {
        return;
      }

      if (handler.isSuccess) {
        setState(() => _loggedInUserId = userId);
      }
    } catch (_) {
      // 静默处理：失败仅复位按钮状态，不打断用户。
    } finally {
      if (mounted && _loggedInUserId == null) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _loggedInUserId == null
          ? KeyedSubtree(
              key: const ValueKey<String>('access-login'),
              child: _buildLoginForm(),
            )
          : PusherView(
              key: const ValueKey<String>('access-live'),
              hostName: _loggedInUserId!,
              liveID: 'live_$_loggedInUserId',
            ),
    );
  }

  Widget _buildLoginForm() {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _pageGradient),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -1.2),
                  radius: 1.2,
                  colors: [PusherStyle.bgGlow1, Color(0x00FF4691)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(1.1, 1.2),
                  radius: 1.2,
                  colors: [PusherStyle.bgGlow2, Color(0x0014EBC8)],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(48),
                decoration: PusherStyle.glassPanel(radius: 24).copyWith(
                  boxShadow: const [
                    BoxShadow(
                      color: PusherStyle.shadowBlack,
                      offset: Offset(0, 24),
                      blurRadius: 48,
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandHeader(),
                    const SizedBox(height: 24),
                    _buildLoginTab(),
                    const SizedBox(height: 24),
                    _buildUsernameInput(),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PusherStyle.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.live_tv,
                color: PusherStyle.whitePure, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            LiveKitLocalizations.of(context).loginBrandTitle,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: PusherStyle.brand,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  /// 单 tab 标题（与最初单 tab 版式一致）。
  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LiveKitLocalizations.of(context).loginTabUsername,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: PusherStyle.whitePure,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 22, height: 3, color: PusherStyle.brand),
      ],
    );
  }

  Widget _buildInputShell({required Widget child}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: PusherStyle.softPanel(radius: 10),
      child: child,
    );
  }

  Widget _buildUsernameInput() {
    return _buildInputShell(
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              size: 20, color: PusherStyle.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _userIdController,
              style: const TextStyle(color: PusherStyle.whitePure, fontSize: 15),
              cursorColor: PusherStyle.brand,
              decoration: InputDecoration.collapsed(
                hintText: LiveKitLocalizations.of(context).loginUsernameHint,
                hintStyle:
                    const TextStyle(color: PusherStyle.textHint, fontSize: 15),
              ),
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _startLogin(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final bool enabled = !_isLoggingIn;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? _startLogin : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            width: double.infinity,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _loginButtonGradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: PusherStyle.brand.withAlpha(89),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
          child: _isLoggingIn
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: PusherStyle.whitePure,
                  ),
                )
              : Text(
                  LiveKitLocalizations.of(context).loginButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: PusherStyle.whitePure,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
