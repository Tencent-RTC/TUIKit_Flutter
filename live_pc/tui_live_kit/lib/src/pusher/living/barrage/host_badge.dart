import 'package:flutter/material.dart';

import '../../../l10n/live_kit_localizations.dart';

class HostBadgeView extends StatelessWidget {
  const HostBadgeView({super.key});

  static const double height = 14;
  static const double width = 27;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF3266A4),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: const Color(0x7D9CEDFF), width: 0.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x420052D9),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          LiveKitLocalizations.of(context).barrageHostTag,
          textAlign: TextAlign.center,
          style: const TextStyle(
            inherit: false,
            color: Color(0xFFFFFFFF),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
