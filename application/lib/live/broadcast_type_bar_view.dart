import 'package:flutter/material.dart';
import '../common/app_strings.dart';

enum BroadcastType { video, voice, game }

class BroadcastTypeBarView extends StatelessWidget {
  const BroadcastTypeBarView({super.key, required this.onSelect});
  final ValueChanged<BroadcastType> onSelect;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final width = bounds.maxWidth.clamp(0.0, 232.0);
      final gap = bounds.maxWidth >= 232 ? 20.0 : 8.0;
      return Center(
        child: SizedBox(
          width: width,
          height: 48,
          child: Row(
            children: [
              for (final type in BroadcastType.values) ...[
                if (type != BroadcastType.video) SizedBox(width: gap),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: type == BroadcastType.video,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(type),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.of(context, type.name),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: type == BroadcastType.video ? FontWeight.w600 : FontWeight.w500,
                                  color: type == BroadcastType.video ? Colors.white : const Color(0xff8b90a0),
                                ),
                              ),
                            ),
                          ),
                          if (type == BroadcastType.video)
                            Positioned(
                              top: 40,
                              child: Container(
                                width: 24,
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1.5),
                                  gradient: const LinearGradient(colors: [Color(0xff338cff), Color(0xff59e0ff)]),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
