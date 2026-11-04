/// 对应 iOS `LiveKitAccess/LoginViewController.swift`。
///
/// 只负责输入用户 ID 与触发登录，登录调度由 `LiveKitAccessCoordinator` 承担。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.initialUserID,
    required this.isLoading,
    required this.onLogin,
    this.toastMessage,
    this.toastToken = 0,
  });

  final String initialUserID;
  final bool isLoading;
  final void Function(String userID) onLogin;

  /// 由 Coordinator 下发的提示文案，对应 iOS `showToast(_:)`。
  final String? toastMessage;

  /// 同一段文案需要重复提示时递增，避免 `didUpdateWidget` 判等后不再展示。
  final int toastToken;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _backgroundColor = Color(0xFFEAF1FB);
  static const Color _decorationColor = Color(0xFFF5F9FE);
  static const Color _brandColor = Color(0xFF3370FF);
  static const Color _textColor = Color(0xFF1A1A1A);
  static const int _userIDMaxLength = 20;

  late final TextEditingController _userIDController =
      TextEditingController(text: widget.initialUserID);
  String? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    if (widget.toastMessage != null) {
      _showToast(widget.toastMessage!);
    }
  }

  @override
  void didUpdateWidget(LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? message = widget.toastMessage;
    if (message != null && widget.toastToken != oldWidget.toastToken) {
      _showToast(message);
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _userIDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: <Widget>[
            ..._buildBackgroundDecoration(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 100),
                    _buildBrand(),
                    const SizedBox(height: 40),
                    _buildUserIDInput(),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                  ],
                ),
              ),
            ),
            _buildToast(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundDecoration() {
    return <Widget>[
      _decoration(color: Colors.white, size: 120, left: -30, top: 20),
      _decoration(color: _decorationColor, size: 140, left: 80, top: -40),
      _decoration(color: Colors.white, size: 90, right: 20, top: 60),
      _decoration(color: _decorationColor, size: 80, right: -60, top: 140),
    ];
  }

  Widget _decoration({
    required Color color,
    required double size,
    required double top,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          'assets/app_ic_cloud_brand.png',
          width: 44,
          height: 44,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        const Text(
          '腾讯云音视频',
          style: TextStyle(
            color: _textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUserIDInput() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _brandColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Image.asset(
            'assets/app_ic_phone.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _userIDController,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(_userIDMaxLength),
              ],
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: const TextStyle(color: _textColor, fontSize: 16),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '请输入用户ID',
                hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: TextButton(
        onPressed: widget.isLoading ? null : _login,
        style: TextButton.styleFrom(
          backgroundColor: _brandColor,
          disabledBackgroundColor: _brandColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: const Text(
          'Debug 登录',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildToast() {
    final String? toast = _toast;
    if (toast == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 24,
      right: 24,
      bottom: 40 + MediaQuery.of(context).padding.bottom,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F).withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              toast,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    final String userID = _userIDController.text.trim();
    if (userID.isEmpty) {
      _showToast('请输入用户ID');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.onLogin(userID);
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toast = message;
    });
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _toast = null;
      });
    });
  }
}
