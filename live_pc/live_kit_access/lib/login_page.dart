import 'dart:io';

import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_kit_desktop/tencent_live_kit_desktop.dart';
import 'generate_test_user_sig.dart';
import 'title_bar.dart';
import 'window_controls_bar.dart';

const LinearGradient _pageGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [LiveKitStyle.bgBase1, LiveKitStyle.bgBase2, LiveKitStyle.bgBase3],
  stops: [0, 0.5, 1],
);

const LinearGradient _loginButtonGradient = LinearGradient(
  colors: [LiveKitStyle.brand, LiveKitStyle.brand2],
);

class _LoginStrings {
  const _LoginStrings(this.isZh);

  final bool isZh;

  String get tabUsername => isZh ? '用户名登录' : 'Username Login';
  String get usernameHint => isZh ? '请输入用户名' : 'Enter username';
  String get button => isZh ? '登录' : 'Login';
  String get brandTitle => isZh ? '直播推流助手' : 'Live Streaming Assistant';
  String get usernameEmpty => isZh ? '请先输入用户名' : 'Please enter your username first';
  String get sdkConfigMissing => isZh ? '未配置 SDKAppID 或 SecretKey' : 'SDKAppID or SecretKey is not configured';
  String exception(String error) => isZh ? '登录失败：$error' : 'Login failed: $error';
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  String? _loggedInUserId;
  bool _isLoggingIn = false;
  String? _errorText;

  _LoginStrings get _strings => _LoginStrings(Localizations.localeOf(context).languageCode == 'zh');

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _startLogin() async {
    if (_isLoggingIn) {
      return;
    }

    final strings = _strings;

    final String userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      setState(() => _errorText = strings.usernameEmpty);
      return;
    }

    final int sdkAppId = GenerateTestUserSig.sdkAppId;
    final String userSig = GenerateTestUserSig.genTestUserSig(userId);
    if (sdkAppId <= 0 || userSig.isEmpty) {
      setState(() => _errorText = strings.sdkConfigMissing);
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _errorText = null;
    });

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
      } else {
        final detail = handler.errorMessage?.isNotEmpty == true
            ? '${handler.errorMessage} (${handler.errorCode})'
            : '${handler.errorCode}';
        setState(() => _errorText = strings.exception(detail));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = strings.exception(e.toString()));
      }
    } finally {
      if (mounted && _loggedInUserId == null) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  void _onUserIdChanged(String _) {
    if (_errorText != null) {
      setState(() => _errorText = null);
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
          : Material(
              type: MaterialType.transparency,
              child: Stack(
                key: const ValueKey<String>('access-live'),
                children: [
                  Positioned.fill(
                    child: PusherView(
                      hostName: _loggedInUserId!,
                      liveID: 'live_$_loggedInUserId',
                      topInset: 44,
                    ),
                  ),
                  const Positioned(top: 0, left: 0, right: 0, child: AppTitleBar()),
                ],
              ),
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
                  colors: [LiveKitStyle.bgGlow1, Color(0x00FF4691)],
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
                  colors: [LiveKitStyle.bgGlow2, Color(0x0014EBC8)],
                ),
              ),
            ),
          ),
          // Frameless window: transparent top drag zone (with double-click
          // maximize) + control buttons at the top-right on Windows. The
          // centered login card doesn't overlap the 44px top zone, so no
          // interaction is affected.
          const WindowDragArea(height: 44),
          if (Platform.isWindows)
            const Positioned(
              top: 0,
              right: 0,
              child: WindowControlsBar(),
            ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(48),
                decoration: LiveKitStyle.glassPanel(radius: 24).copyWith(
                  boxShadow: const [
                    BoxShadow(
                      color: LiveKitStyle.shadowBlack,
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
                    SizedBox(
                      height: 40,
                      child: _errorText == null
                          ? null
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: LiveKitStyle.danger,
                                  ),
                                  children: [
                                    const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(
                                        Icons.error_outline,
                                        size: 14,
                                        color: LiveKitStyle.danger,
                                      ),
                                    ),
                                    const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: SizedBox(width: 4),
                                    ),
                                    TextSpan(text: _errorText!),
                                  ],
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                    ),
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
              color: LiveKitStyle.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.live_tv,
                color: LiveKitStyle.whitePure, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            _strings.brandTitle,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: LiveKitStyle.brand,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Single-tab heading (same layout as the original single-tab version).
  Widget _buildLoginTab() {
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _strings.tabUsername,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LiveKitStyle.whitePure,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 3, color: LiveKitStyle.brand),
        ],
      ),
    );
  }

  Widget _buildInputShell({required Widget child}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: LiveKitStyle.softPanel(radius: 10),
      child: child,
    );
  }

  Widget _buildUsernameInput() {
    return _buildInputShell(
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              size: 20, color: LiveKitStyle.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _userIdController,
              style: const TextStyle(color: LiveKitStyle.whitePure, fontSize: 15),
              cursorColor: LiveKitStyle.brand,
              decoration: InputDecoration.collapsed(
                hintText: _strings.usernameHint,
                hintStyle:
                    const TextStyle(color: LiveKitStyle.textHint, fontSize: 15),
              ),
              textInputAction: TextInputAction.go,
              onChanged: _onUserIdChanged,
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
                  color: LiveKitStyle.brand.withAlpha(89),
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
                    color: LiveKitStyle.whitePure,
                  ),
                )
              : Text(
                  _strings.button,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: LiveKitStyle.whitePure,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
