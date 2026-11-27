import 'dart:math' as math;
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'live_home_item_view.dart';

class LiveHomeRoomTransition extends PageRouteBuilder<void> {
  LiveHomeRoomTransition({
    required Widget page,
    required LiveInfo info,
    required Rect source,
    required Rect visibleSource,
    bool reduceMotion = false,
  }) : super(
         opaque: false,
         barrierColor: Colors.transparent,
         transitionDuration: Duration(milliseconds: reduceMotion ? 160 : 220),
         reverseTransitionDuration: const Duration(milliseconds: 160),
         pageBuilder: (_, animation, secondary) => page,
         transitionsBuilder: (context, animation, secondary, child) => LayoutBuilder(
           builder: (context, bounds) {
             final reversing = animation.status == AnimationStatus.reverse;

             final value = Curves.easeInOutCubic.transform(animation.value);
             final target = Offset.zero & bounds.biggest;
             final viewport = Rect.lerp(visibleSource, target, value)!;
             final cover = Rect.lerp(source, target, value)!;
             return Stack(
               children: [
                 Positioned.fill(
                   child: ColoredBox(color: Colors.black.withValues(alpha: reversing ? 0 : value)),
                 ),
                 Positioned.fill(
                   child: Opacity(
                     opacity: reversing || reduceMotion ? animation.value : ((value - .75) / .25).clamp(0.0, 1.0),
                     child: child,
                   ),
                 ),
                 if (!reduceMotion && !reversing && value < 1)
                   Positioned.fromRect(
                     rect: viewport,
                     child: IgnorePointer(
                       child: ClipRect(
                         child: Stack(
                           clipBehavior: Clip.none,
                           children: [
                             Positioned(
                               left: cover.left - viewport.left,
                               top: cover.top - viewport.top,
                               width: cover.width,
                               height: cover.height,
                               child: ClipRRect(
                                 borderRadius: BorderRadius.circular(8 * (1 - value)),
                                 child: Stack(
                                   fit: StackFit.expand,
                                   children: [
                                     const ColoredBox(color: Color(0xff29364a)),
                                     if (Uri.tryParse(info.coverURL)?.hasScheme == true)
                                       Image.network(
                                         info.coverURL,
                                         fit: BoxFit.cover,
                                         errorBuilder: (_, error, stack) => const SizedBox.shrink(),
                                       ),
                                     // Keep the card's text at its original size while the cover expands beneath it.
                                     Positioned(
                                       top: 0,
                                       left: 0,
                                       width: source.width,
                                       height: source.height,
                                       child: Opacity(
                                         opacity: math.max(0, 1 - value / .3),
                                         child: LiveHomeItemView(info: info, hero: false),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                   ),
               ],
             );
           },
         ),
       );
}
