import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart' hide Role;
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/components/localized_manager.dart';
import 'package:atomic_x_core_example/components/role.dart';
import 'package:atomic_x_core_example/scenes/basic_streaming/basic_streaming_page.dart';
import 'package:atomic_x_core_example/scenes/interactive/interactive_page.dart';
import 'package:atomic_x_core_example/scenes/co_guest/co_guest_page.dart';
import 'package:atomic_x_core_example/scenes/live_pk/live_pk_page.dart';

/// Business scenario: feature list page
///
/// Displays entry cards for four progressive stages:
/// 1. BasicStreaming - basic live streaming
/// 2. Interactive - real-time interaction
/// 3. CoGuest - audience co-hosting
/// 4. LivePK - live PK battle
class FeatureListPage extends StatelessWidget {
  const FeatureListPage({super.key});

  // MARK: - Data Model

  static const List<_FeatureItem> _features = [
    _FeatureItem(
      titleKey: 'stageBasicStreaming',
      descriptionKey: 'stageBasicStreamingDesc',
      icon: Icons.videocam,
      stage: _FeatureStage.basicStreaming,
    ),
    _FeatureItem(
      titleKey: 'stageInteractive',
      descriptionKey: 'stageInteractiveDesc',
      icon: Icons.card_giftcard,
      stage: _FeatureStage.interactive,
    ),
    _FeatureItem(
      titleKey: 'stageCoGuest',
      descriptionKey: 'stageCoGuestDesc',
      icon: Icons.people,
      stage: _FeatureStage.coGuest,
    ),
    _FeatureItem(
      titleKey: 'stageLivePK',
      descriptionKey: 'stageLivePKDesc',
      icon: Icons.local_fire_department,
      stage: _FeatureStage.livePK,
    ),
  ];

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(l10n.featureListTitle),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          // Language switch button
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => LocalizedManager.shared.showLanguageSwitchAlert(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _features.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Section header
            return _SectionHeaderView(title: l10n.featureListSectionHeader);
          }
          final feature = _features[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _FeatureCell(
              title: _getLocalizedTitle(l10n, feature.titleKey),
              description: _getLocalizedDescription(l10n, feature.descriptionKey),
              icon: feature.icon,
              index: index - 1,
              onTap: () => _navigateToStage(context, feature.stage),
            ),
          );
        },
      ),
    );
  }

  // MARK: - Localization Helpers

  String _getLocalizedTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'stageBasicStreaming':
        return l10n.stageBasicStreaming;
      case 'stageInteractive':
        return l10n.stageInteractive;
      case 'stageCoGuest':
        return l10n.stageCoGuest;
      case 'stageLivePK':
        return l10n.stageLivePK;
      default:
        return key;
    }
  }

  String _getLocalizedDescription(AppLocalizations l10n, String key) {
    switch (key) {
      case 'stageBasicStreamingDesc':
        return l10n.stageBasicStreamingDesc;
      case 'stageInteractiveDesc':
        return l10n.stageInteractiveDesc;
      case 'stageCoGuestDesc':
        return l10n.stageCoGuestDesc;
      case 'stageLivePKDesc':
        return l10n.stageLivePKDesc;
      default:
        return key;
    }
  }

  // MARK: - Actions

  void _navigateToStage(BuildContext context, _FeatureStage stage) {
    final l10n = AppLocalizations.of(context)!;

    // Use an action sheet to select the role
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.roleSelectTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              Text(
                l10n.roleSelectSubtitle,
                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Anchor option: use `userID` directly as the room ID
              ListTile(
                title: Text(Role.anchor.titleKey(l10n)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final liveID = _generateAnchorLiveID();
                  _navigateToFunctionPage(context, role: Role.anchor, stage: stage, liveID: liveID);
                },
              ),
              // Audience option: show the live room ID input dialog
              ListTile(
                title: Text(Role.audience.titleKey(l10n)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showLiveIDInput(context, role: Role.audience, stage: stage);
                },
              ),
              // Cancel
              ListTile(
                title: Text(l10n.commonCancel, textAlign: TextAlign.center),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get the anchor's room ID by directly using the current logged-in `userID`
  String _generateAnchorLiveID() {
    return LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
  }

  /// Show the live room ID input dialog (audience only)
  void _showLiveIDInput(BuildContext context, {required Role role, required _FeatureStage stage}) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.liveIDInputTitleAudience),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.liveIDInputMessageAudience),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: l10n.liveIDInputPlaceholder, border: const OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.commonCancel)),
            TextButton(
              onPressed: () {
                final liveID = controller.text.trim();
                Navigator.pop(dialogContext);
                if (liveID.isEmpty) {
                  _showEmptyLiveIDAlert(context, role: role, stage: stage);
                  return;
                }
                _navigateToFunctionPage(context, role: role, stage: stage, liveID: liveID);
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }

  /// Prompt that the live room ID cannot be empty
  void _showEmptyLiveIDAlert(BuildContext context, {required Role role, required _FeatureStage stage}) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.commonWarning),
          content: Text(l10n.liveIDInputErrorEmpty),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showLiveIDInput(context, role: role, stage: stage);
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }

  void _navigateToFunctionPage(
    BuildContext context, {
    required Role role,
    required _FeatureStage stage,
    required String liveID,
  }) {
    Widget page;
    switch (stage) {
      case _FeatureStage.basicStreaming:
        page = BasicStreamingPage(role: role, liveID: liveID);
        break;
      case _FeatureStage.interactive:
        page = InteractivePage(role: role, liveID: liveID);
        break;
      case _FeatureStage.coGuest:
        page = CoGuestPage(role: role, liveID: liveID);
        break;
      case _FeatureStage.livePK:
        page = LivePKPage(role: role, liveID: liveID);
        break;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }
}

// MARK: - Data Model

enum _FeatureStage { basicStreaming, interactive, coGuest, livePK }

class _FeatureItem {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final _FeatureStage stage;

  const _FeatureItem({required this.titleKey, required this.descriptionKey, required this.icon, required this.stage});
}

// MARK: - FeatureCell

/// Feature card cell — rounded card + number badge + icon + title + description + arrow
class _FeatureCell extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final int index;
  final VoidCallback onTap;

  /// Different stages use different colors
  static const List<Color> _stageColors = [Colors.blue, Colors.green, Colors.orange, Colors.red];

  const _FeatureCell({
    required this.title,
    required this.description,
    required this.icon,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _stageColors[index % _stageColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 2), blurRadius: 4)],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}

// MARK: - SectionHeaderView

class _SectionHeaderView extends StatelessWidget {
  final String title;

  const _SectionHeaderView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}
