import 'package:flutter/material.dart';
import '../../common/app_strings.dart';

class ProfileUpdateInfoView extends StatefulWidget {
  const ProfileUpdateInfoView({super.key, required this.initial});
  final String initial;
  @override
  State<ProfileUpdateInfoView> createState() => _ProfileUpdateInfoViewState();
}

class _ProfileUpdateInfoViewState extends State<ProfileUpdateInfoView> {
  late final _text = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 60,
              child: Stack(
                children: [
                  Center(child: Text(AppStrings.of(context, 'nickname'), style: const TextStyle(fontSize: 16))),
                  Positioned(
                    right: 16,
                    top: 20,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox.square(dimension: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xffe7ecf6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 0),
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _text,
                  style: const TextStyle(fontSize: 16, height: 1.25),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xfff5f5f5),
                    counterText: '',
                    border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.of(context, 'editNicknameRule'),
                  style: const TextStyle(fontSize: 12, height: 17 / 12, color: Color(0xff888888)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff1c66e5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _text.text.isEmpty ? null : () => Navigator.pop(context, _text.text),
                  child: Text(AppStrings.of(context, 'ok')),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
