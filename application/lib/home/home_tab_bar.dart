import 'package:flutter/material.dart';
import '../common/app_strings.dart';

class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.unread,
    this.enabled = true,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  final int unread;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final dark = selected == 1;
    return SizedBox(
      height: 56,
      child: Row(
        children: List.generate(5, (index) {
          final active = selected == index;
          final color = dark
              ? (active ? Colors.white : const Color(0xff8c93a1))
              : (active ? const Color(0xff171822) : const Color(0xff67686f));
          return Expanded(
            child: Semantics(
              selected: active,
              button: true,
              label: index == 3 && unread > 0 ? '${AppStrings.of(context, 'messages')}, $unread' : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? () => onSelect(index) : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppStrings.of(context, ['meeting', 'live', 'call', 'messages', 'mine'][index]),
                          style: TextStyle(
                            color: color,
                            fontSize: active ? 17 : 16,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (index == 3 && unread > 0)
                      Positioned(
                        top: 6,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: const Alignment(.65, 0),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xfff33a50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
