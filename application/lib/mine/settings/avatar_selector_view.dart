import 'package:flutter/material.dart';
import '../../common/app_strings.dart';
import 'mine_page_header.dart';
import 'profile_image.dart';

class AvatarSelectorView extends StatefulWidget {
  const AvatarSelectorView({super.key, required this.current});
  final String current;
  @override
  State<AvatarSelectorView> createState() => _AvatarSelectorViewState();
}

class _AvatarSelectorViewState extends State<AvatarSelectorView> {
  late String? _selected =
      List.generate(
        20,
        (index) => 'https://im.sdk.qcloud.com/download/tuikit-resource/avatar/avatar_${index + 1}.png',
      ).contains(widget.current)
      ? widget.current
      : null;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff2f2f7),
    appBar: MinePageHeader(
      title: AppStrings.of(context, 'selectAvatar'),
      action: TextButton(
        style: TextButton.styleFrom(foregroundColor: const Color(0xff007aff), textStyle: const TextStyle(fontSize: 14)),
        onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
        child: Text(AppStrings.of(context, 'save')),
      ),
    ),
    body: GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 24, 15, 24),
      itemCount: 20,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 13,
        mainAxisSpacing: 10,
        mainAxisExtent: 77,
      ),
      itemBuilder: (context, index) {
        final url = 'https://im.sdk.qcloud.com/download/tuikit-resource/avatar/avatar_${index + 1}.png';
        return GestureDetector(
          onTap: () => setState(() => _selected = _selected == url ? null : url),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 2, color: _selected == url ? const Color(0xff007aff) : Colors.transparent),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: LayoutBuilder(
                builder: (context, bounds) => ProfileImage(url: url, size: bounds.maxWidth, radius: 6),
              ),
            ),
          ),
        );
      },
    ),
  );
}
