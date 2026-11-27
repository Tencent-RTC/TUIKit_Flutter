import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' as chat;
import '../common/app_strings.dart';
import '../login/login_store.dart';
import 'settings/profile_image.dart';
import 'settings/mine_settings_view.dart';
import 'log/log_upload_view.dart';

class MineView extends StatelessWidget {
  const MineView({super.key, required this.auth, required this.locale});
  final AppLoginStore auth;
  final chat.LocaleProvider locale;
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(AppStrings.of(context, 'logoutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(AppStrings.of(context, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(dialog, true), child: Text(AppStrings.of(context, 'yes'))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) await auth.logout();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xffebedf5),
    body: AnimatedBuilder(
      animation: LoginStore.shared,
      builder: (context, child) {
        final profile = LoginStore.shared.loginState.loginUserInfo;
        final top = MediaQuery.paddingOf(context).top;
        final decorationHeight = MediaQuery.sizeOf(context).width * 112 / 375 + top + 44;
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: decorationHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: Image.asset('assets/mine_bg.png', fit: BoxFit.cover)),
                    Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: 44,
                      child: Center(
                        child: Text(
                          AppStrings.of(context, 'personalCenter'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ProfileImage(url: profile?.avatarURL ?? '', size: 72),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  profile?.nickname ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xff262b32), fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 2),
              Text('ID:${profile?.userID ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xff626e84))),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _entry(
                      context,
                      'settings',
                      'assets/mine_settings.png',
                      () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => MineSettingsView(locale: locale))),
                    ),
                    _entry(
                      context,
                      'logs',
                      'assets/mine_log.png',
                      () => showModalBottomSheet<void>(
                        context: context,
                        useRootNavigator: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        barrierColor: const Color(0x66000000),
                        shape: const RoundedRectangleBorder(),
                        builder: (_) => const LogUploadView(),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _logout(context),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      AppStrings.of(context, 'logout'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xfff33a50)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  Widget _entry(BuildContext context, String key, String image, VoidCallback tap) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: tap,
    child: SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Image.asset(image, width: 24, height: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                AppStrings.of(context, key),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Image.asset('assets/mine_detail.png', width: 18, height: 18),
          ],
        ),
      ),
    ),
  );
}
