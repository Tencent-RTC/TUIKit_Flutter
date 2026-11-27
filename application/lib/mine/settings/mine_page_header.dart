import 'package:flutter/material.dart';

// UIKit's navigation bar supplies the back control and safe top inset implicitly.
// The Flutter page owns both here; callers must not add a second top SafeArea.
class MinePageHeader extends StatelessWidget implements PreferredSizeWidget {
  const MinePageHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Size get preferredSize => const Size.fromHeight(44);
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 56,
                height: 44,
                child: Center(child: Image.asset('assets/mine_back.png', width: 20, height: 20, fit: BoxFit.contain)),
              ),
            ),
          ),
          if (action != null) Align(alignment: Alignment.centerRight, child: action!),
        ],
      ),
    ),
  );
}
