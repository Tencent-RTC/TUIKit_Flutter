import 'package:atomic_x_core_media_mixing/api/media_mixing_store.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../../common/style/live_kit_style.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/encoder_params_util.dart';
import '../../common/widget/hover_clickable.dart';

class StreamOrientationSwitch extends StatelessWidget {
  const StreamOrientationSwitch({super.key, this.enabled = true});

  final bool enabled;

  void _setOrientation(bool landscape) {
    EncoderParamsUtil.switchOrientation(landscape);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaMixingParams>(
      valueListenable: MediaMixingStore.shared.state.params,
      builder: (context, params, _) {
        final isLandscape =
            params.videoEncoderParams.resolutionMode ==
            VideoResolutionMode.landscape;
        return Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: LiveKitStyle.softPanel(radius: 6),
            child: Row(
              children: [
                _ModeChip(
                  icon: RemixIcons.tv_2_line,
                  label: LiveKitLocalizations.of(context).orientationLandscape,
                  active: isLandscape,
                  enabled: enabled,
                  onTap: () => _setOrientation(true),
                ),
                _ModeChip(
                  icon: RemixIcons.smartphone_line,
                  label: LiveKitLocalizations.of(context).orientationPortrait,
                  active: !isLandscape,
                  enabled: enabled,
                  onTap: () => _setOrientation(false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return HoverClickable(
      onTap: onTap,
      enabled: enabled && !active,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? LiveKitStyle.white15 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: active ? Colors.white : LiveKitStyle.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : LiveKitStyle.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
