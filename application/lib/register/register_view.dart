import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/app_strings.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    if (_saving || _name.text.trim().isEmpty) return;
    final profile = LoginStore.shared.loginState.loginUserInfo;
    if (profile == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await LoginStore.shared.setSelfInfo(
      userInfo: UserProfile(
        userID: profile.userID,
        nickname: _name.text.trim(),
        avatarURL: profile.avatarURL?.isNotEmpty == true
            ? profile.avatarURL
            : 'https://im.sdk.qcloud.com/download/tuikit-resource/avatar/avatar_1.png',
      ),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        if (!result.isSuccess) _error = result.errorMessage;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: Text(AppStrings.of(context, 'register'))),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            Center(
              child: ClipOval(
                child: Image.network(
                  'https://im.sdk.qcloud.com/download/tuikit-resource/avatar/avatar_1.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 100, height: 100),
                ),
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _name,
              maxLength: 20,
              enabled: !_saving,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\u4e00-\u9fa5a-zA-Z0-9_]'))],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: AppStrings.of(context, 'nickname')),
            ),
            Text(AppStrings.of(context, 'nicknameRule')),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving || _name.text.trim().isEmpty ? null : _save,
                child: Text(AppStrings.of(context, 'register')),
              ),
            ),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
    ),
  );
}
