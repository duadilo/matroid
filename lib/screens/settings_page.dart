import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'settings_content.dart';

/// Thin wrapper that gives [SettingsContent] its own [Scaffold] + [AppBar]
/// for use as a standalone pushed route (kept for potential standalone use).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: const SettingsContent(),
    );
  }
}
