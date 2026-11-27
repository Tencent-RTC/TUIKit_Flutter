import 'package:flutter/material.dart';
import '../common/app_strings.dart';
import 'login_store.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.store});
  final AppLoginStore store;
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _user = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.store.ready.future.then((_) {
      if (mounted) _user.text = widget.store.cachedUser;
    });
  }

  @override
  void dispose() {
    _user.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final s = widget.store;
      String t(String key) => AppStrings.of(context, key);
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: bounds.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 90),
                      child: Row(
                        children: [
                          Image.asset('assets/tencent_cloud.png', width: 80, height: 80, fit: BoxFit.contain),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(t('title'), style: const TextStyle(fontSize: 32, color: Color(0xff333333))),
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: _user,
                      enabled: !s.busy,
                      onSubmitted: (_) => s.login(_user.text),
                      decoration: InputDecoration(
                        prefixText: '${t('userId')}  ',
                        hintText: 'userId',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff006EFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: s.busy ? null : () => s.login(_user.text),
                        child: s.busy
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(t('login'), style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('testEnvironment')),
                      value: false,
                      onChanged: null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('autoLogin')),
                      value: s.autoLogin,
                      onChanged: s.setAutomatic,
                    ),
                    if (s.error != null) Text(t(s.error!), style: const TextStyle(color: Color(0xffD44A4A))),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
