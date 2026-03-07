import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../l10n/app_localizations.dart';
import '../server/platform/server_platform.dart';

// ---------------------------------------------------------------------------
// Settings content (body-only — no Scaffold)
// ---------------------------------------------------------------------------

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  final _settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _settings.themeMode.addListener(_rebuild);
    _settings.locale.addListener(_rebuild);
    _settings.fontFamily.addListener(_rebuild);
  }

  @override
  void dispose() {
    _settings.themeMode.removeListener(_rebuild);
    _settings.locale.removeListener(_rebuild);
    _settings.fontFamily.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: [
        _SectionHeader(l10n.sectionAppearance),
        _ThemeSetting(settings: _settings),
        const Divider(indent: 16, endIndent: 16),
        _FontSetting(settings: _settings),
        const Divider(indent: 16, endIndent: 16),
        _SectionHeader(l10n.sectionLanguage),
        _LanguageSetting(settings: _settings),
        const Divider(indent: 16, endIndent: 16),
        _SectionHeader(l10n.sectionApiKeys),
        _ApiKeySetting(
          label: l10n.apiKeyOpenai,
          provider: 'openai',
          notifier: _settings.openaiApiKey,
          settings: _settings,
        ),
        _ApiKeySetting(
          label: l10n.apiKeyAnthropic,
          provider: 'anthropic',
          notifier: _settings.anthropicApiKey,
          settings: _settings,
        ),
        _ApiKeySetting(
          label: l10n.apiKeyGoogle,
          provider: 'google',
          notifier: _settings.googleApiKey,
          settings: _settings,
        ),
        const Divider(indent: 16, endIndent: 16),
        if (isDesktop) ...[
          _SectionHeader(l10n.sectionServer),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.consoleVisible,
            builder: (context, visible, _) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const Icon(Icons.terminal_outlined),
              title: Text(l10n.serverConsoleTitle),
              subtitle: Text(l10n.serverConsoleSubtitle),
              trailing: Icon(
                visible ? Icons.picture_in_picture : Icons.open_in_new,
              ),
              onTap: () =>
                  _settings.consoleVisible.value = !_settings.consoleVisible.value,
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
        ],
        _SectionHeader(l10n.sectionAbout),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.aboutTitle),
          subtitle: Text(l10n.aboutSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: '0.1.0',
              applicationIcon: const Icon(Icons.apps, size: 48),
              applicationLegalese: '\u00a9 2026 Matroid contributors',
              children: [
                const SizedBox(height: 24),
                Text(
                  'Open-source licenses',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app uses the following open-source packages and fonts. '
                  'Tap "View Licenses" below for full license texts.',
                ),
                const SizedBox(height: 16),
                ..._attributionItems,
              ],
            );
          },
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.aboutViewLicenses),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: '0.1.0',
              applicationIcon: const Icon(Icons.apps, size: 48),
              applicationLegalese: '\u00a9 2026 Matroid contributors',
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Attribution summary shown in the About dialog
// ---------------------------------------------------------------------------

const _attributionItems = <Widget>[
  _Attribution('http', 'BSD-3-Clause', 'Dart project authors'),
  _Attribution('file_picker', 'MIT', 'Miguel Ruivo'),
  _Attribution('path_provider', 'BSD-3-Clause', 'Flutter authors'),
  _Attribution('crypto', 'BSD-3-Clause', 'Dart project authors'),
  _Attribution('shared_preferences', 'BSD-3-Clause', 'Flutter authors'),
  _Attribution('flutter_code_editor', 'Apache-2.0', 'akvelon'),
  _Attribution('flutter_highlight', 'MIT', 'git-sidd'),
  _Attribution('highlight', 'MIT', 'git-sidd'),
  _Attribution('flutter_markdown_plus', 'BSD-3-Clause', 'Taha Tesser'),
  _Attribution('flutter_math_fork', 'Apache-2.0', 'SimonWang'),
  _Attribution('printing', 'Apache-2.0', 'David MUSIC'),
  _Attribution('pdf', 'Apache-2.0', 'David MUSIC'),
  _Attribution('markdown', 'BSD-3-Clause', 'Dart project authors'),
  _Attribution('fl_chart', 'MIT', 'Iman Khoshabi'),
  _Attribution('image_picker', 'BSD-3-Clause', 'Flutter authors'),
  _Attribution('video_player', 'BSD-3-Clause', 'Flutter authors'),
  _Attribution('chewie', 'MIT', 'Brian Egan'),
  _Attribution('accessibility_tools', 'MIT', 'Rebelappstudio'),
  _Attribution('intl', 'BSD-3-Clause', 'Dart project authors'),
  _Attribution('OpenDyslexic (font)', 'SIL OFL 1.1', 'Abbie Gonzalez'),
  _Attribution('Lexend (font)', 'SIL OFL 1.1', 'Bonnie Shaver-Troup / Thomas Jockin'),
];

class _Attribution extends StatelessWidget {
  const _Attribution(this.name, this.license, this.author);

  final String name;
  final String license;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          SizedBox(
            width: 110,
            child: Text(license, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Text(author, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme setting row
// ---------------------------------------------------------------------------

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.themeLabel,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  l10n.themeDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(l10n.themeDark),
              ),
            ],
            selected: {settings.themeMode.value},
            onSelectionChanged: (sel) => settings.setThemeMode(sel.first),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Font setting row
// ---------------------------------------------------------------------------

class _FontSetting extends StatelessWidget {
  const _FontSetting({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.fontLabel,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  l10n.fontDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SegmentedButton<AppFont>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: AppFont.system,
                label: Text(l10n.fontDefault),
              ),
              ButtonSegment(
                value: AppFont.openDyslexic,
                label: Text(l10n.fontOpenDyslexic),
              ),
              ButtonSegment(
                value: AppFont.lexend,
                label: Text(l10n.fontLexend),
              ),
            ],
            selected: {settings.fontFamily.value},
            onSelectionChanged: (sel) => settings.setFontFamily(sel.first),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language setting row
// ---------------------------------------------------------------------------

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.languageLabel,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  l10n.languageDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SegmentedButton<Locale>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: const Locale('en'),
                label: Text(l10n.languageEnglish),
              ),
              ButtonSegment(
                value: const Locale('es'),
                label: Text(l10n.languageSpanish),
              ),
            ],
            selected: {settings.locale.value},
            onSelectionChanged: (sel) => settings.setLocale(sel.first),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// API key setting row
// ---------------------------------------------------------------------------

class _ApiKeySetting extends StatefulWidget {
  const _ApiKeySetting({
    required this.label,
    required this.provider,
    required this.notifier,
    required this.settings,
  });

  final String label;
  final String provider;
  final ValueNotifier<String> notifier;
  final AppSettings settings;

  @override
  State<_ApiKeySetting> createState() => _ApiKeySettingState();
}

class _ApiKeySettingState extends State<_ApiKeySetting> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notifier.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settings.setApiKey(widget.provider, _controller.text.trim());
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.apiKeySaved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: l10n.apiKeyHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _save,
            child: Text(l10n.apiKeySaved),
          ),
        ],
      ),
    );
  }
}
