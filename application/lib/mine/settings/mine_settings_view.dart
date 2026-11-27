import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' as chat;
import '../../common/app_strings.dart';
import 'mine_page_header.dart';
import 'profile_image.dart';
import 'avatar_selector_view.dart';
import 'language_select_view.dart';
import 'profile_update_info_view.dart';

class MineSettingsView extends StatefulWidget {
  const MineSettingsView({super.key, required this.locale});
  final chat.LocaleProvider locale;
  @override
  State<MineSettingsView> createState() => _MineSettingsViewState();
}

class _MineSettingsViewState extends State<MineSettingsView> {
  bool _saving = false;
  Future<void> _update({String? nickname, String? avatar}) async {
    if (_saving) return;
    final current = LoginStore.shared.loginState.loginUserInfo;
    if (current == null) return;
    setState(() => _saving = true);
    try {
      final result = await LoginStore.shared.setSelfInfo(
        userInfo: UserProfile(
          userID: current.userID,
          nickname: nickname ?? current.nickname,
          avatarURL: avatar ?? current.avatarURL,
        ),
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.errorMessage ?? '${result.errorCode}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: MinePageHeader(title: AppStrings.of(context, 'settings')),
    body: AnimatedBuilder(
      animation: LoginStore.shared,
      builder: (context, child) {
        final user = LoginStore.shared.loginState.loginUserInfo;
        return IgnorePointer(
          ignoring: _saving,
          child: ListView(
            padding: const EdgeInsets.only(top: 20),
            children: [
              _row('avatar', ProfileImage(url: user?.avatarURL ?? '', size: 36, radius: 18), () async {
                final selected = await Navigator.of(
                  context,
                ).push<String>(MaterialPageRoute(builder: (_) => AvatarSelectorView(current: user?.avatarURL ?? '')));
                if (mounted && selected != null) await _update(avatar: selected);
              }),
              _row(
                'nickname',
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    user?.nickname ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Color(0xff333333)),
                  ),
                ),
                () async {
                  final name = await showModalBottomSheet<String>(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    barrierColor: const Color(0x80000000),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                    builder: (_) => ProfileUpdateInfoView(initial: user?.nickname ?? ''),
                  );
                  if (mounted && name != null) await _update(nickname: name);
                },
              ),
              _row(
                'language',
                const SizedBox.shrink(),
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => LanguageSelectView(locale: widget.locale))),
              ),
              if (_saving) const LinearProgressIndicator(),
            ],
          ),
        );
      },
    ),
  );
  Widget _row(String key, Widget value, VoidCallback tap) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: tap,
    child: Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(AppStrings.of(context, key), style: const TextStyle(fontSize: 16, color: Color(0xff333333))),
          ),
          value,
          const SizedBox(width: 10),
          Image.asset('assets/mine_detail.png', width: 16, height: 16),
        ],
      ),
    ),
  );
}
