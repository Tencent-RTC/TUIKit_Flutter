import 'package:flutter/material.dart';

class ProfileImage extends StatelessWidget {
  const ProfileImage({super.key, required this.url, required this.size, this.radius});
  final String url;
  final double size;
  final double? radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius ?? size / 2),
    child: SizedBox.square(
      dimension: size,
      child: url.isEmpty
          ? Image.asset('assets/default_avatar.png', fit: BoxFit.cover)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => Image.asset('assets/default_avatar.png', fit: BoxFit.cover),
            ),
    ),
  );
}
