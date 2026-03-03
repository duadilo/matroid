import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'l10n/app_localizations.dart';
import 'screens/server_console.dart';
import 'server/platform/server_platform.dart';

const double _kMobileBreak = 600;
const double _kWideBreak = 1200;

// ---------------------------------------------------------------------------
// Adaptive navigation shell
// ---------------------------------------------------------------------------
//
// Breakpoints:
//   < 600 px  — modal drawer (mobile)
//   600–1199  — collapsed icon rail (tablet)
//   ≥ 1200 px — auto-extended rail (desktop)
//
// [pages] must have exactly five entries:
//   [HomeContent, SettingsContent, EditorContent, ShowcaseContent, ChatContent].
// Tests inject stub widgets so no server or asset dependencies are needed.

class AdaptiveNav extends StatefulWidget {
  const AdaptiveNav({super.key, required this.pages});

  final List<Widget> pages;

  @override
  State<AdaptiveNav> createState() => _AdaptiveNavState();
}

class _AdaptiveNavState extends State<AdaptiveNav> {
  int _selectedIndex = 0;
  bool _railExtended = false;
  bool _didInitRail = false;
  Offset _panelPosition = const Offset(40, 80);

  @override
  void initState() {
    super.initState();
    AppSettings.instance.consoleVisible.addListener(_rebuildForPanel);
  }

  @override
  void dispose() {
    AppSettings.instance.consoleVisible.removeListener(_rebuildForPanel);
    super.dispose();
  }

  void _rebuildForPanel() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialise the rail extended-state once, based on the initial screen
    // width.  Subsequent calls (e.g. from a MediaQuery rebuild on window
    // resize) are ignored so the user's manual toggle is preserved.
    if (!_didInitRail) {
      _didInitRail = true;
      final width = MediaQuery.of(context).size.width;
      _railExtended = width >= _kWideBreak;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _kMobileBreak;

    final title = switch (_selectedIndex) {
      0 => l10n.appTitle,
      1 => l10n.settingsTitle,
      2 => l10n.editorTitle,
      3 => l10n.showcaseTitle,
      _ => l10n.chatTitle,
    };

    if (isMobile) {
      return _buildMobile(context, l10n, title);
    }
    return _buildWide(context, l10n, title);
  }

  // ---- Floating console panel overlay -------------------------------------

  /// Wraps [child] in a [Stack] with the draggable console panel on top.
  /// On non-desktop platforms or when the panel is hidden, returns [child]
  /// unchanged.
  Widget _wrapWithPanel(Widget child) {
    if (!isDesktop || !AppSettings.instance.consoleVisible.value) return child;
    return LayoutBuilder(
      builder: (_, constraints) => Stack(
        children: [
          child,
          Positioned(
            left: _panelPosition.dx,
            top: _panelPosition.dy,
            child: ServerConsolePanel(
              onDragDelta: (delta) => setState(() {
                _panelPosition = Offset(
                  (_panelPosition.dx + delta.dx)
                      .clamp(0, constraints.maxWidth - ServerConsolePanel.defaultWidth),
                  (_panelPosition.dy + delta.dy)
                      .clamp(0, constraints.maxHeight - ServerConsolePanel.defaultHeight),
                );
              }),
              onClose: () =>
                  AppSettings.instance.consoleVisible.value = false,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Mobile layout (drawer) ----------------------------------------------

  Widget _buildMobile(
      BuildContext context, AppLocalizations l10n, String title) {
    return _wrapWithPanel(Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          Navigator.pop(context);
        },
        children: [
          NavigationDrawerDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: Text(l10n.navHome),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Text(l10n.settingsTitle),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.code_outlined),
            selectedIcon: const Icon(Icons.code),
            label: Text(l10n.editorTitle),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: Text(l10n.showcaseTitle),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.chat_outlined),
            selectedIcon: const Icon(Icons.chat),
            label: Text(l10n.chatTitle),
          ),
        ],
      ),
      body: widget.pages[_selectedIndex],
    ));
  }

  // ---- Wide layout (rail) --------------------------------------------------

  Widget _buildWide(
      BuildContext context, AppLocalizations l10n, String title) {
    return _wrapWithPanel(Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Row(
        children: [
          NavigationRail(
            extended: _railExtended,
            leading: IconButton(
              icon: Icon(_railExtended ? Icons.menu_open : Icons.menu),
              tooltip: _railExtended
                  ? MaterialLocalizations.of(context).closeButtonTooltip
                  : MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: () =>
                  setState(() => _railExtended = !_railExtended),
            ),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) =>
                setState(() => _selectedIndex = i),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: Text(l10n.navHome),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(l10n.settingsTitle),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.code_outlined),
                selectedIcon: const Icon(Icons.code),
                label: Text(l10n.editorTitle),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: Text(l10n.showcaseTitle),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.chat_outlined),
                selectedIcon: const Icon(Icons.chat),
                label: Text(l10n.chatTitle),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.pages[_selectedIndex]),
        ],
      ),
    ));
  }
}
