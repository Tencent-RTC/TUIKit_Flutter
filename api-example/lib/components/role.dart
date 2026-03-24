import 'package:atomic_x_core_example/l10n/app_localizations.dart';

 /// Shared role enum definition
 /// Used to pass the user identity between feature pages
enum Role {
  anchor,
  audience;

  String titleKey(AppLocalizations l10n) {
    switch (this) {
      case Role.anchor:
        return l10n.roleSelectAnchor;
      case Role.audience:
        return l10n.roleSelectAudience;
    }
  }
}
