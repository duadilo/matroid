import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_settings.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';

// Terminal colour palette
const _kBg = Color(0xFF0D1117);
const _kHeader = Color(0xFF161B22);
const _kStdout = Color(0xFF7EE787);
const _kStderr = Color(0xFFFF7B72);
const _kDim = Color(0xFF8B949E);

// ---------------------------------------------------------------------------
// Shared scrollable log body
// ---------------------------------------------------------------------------

class _ConsoleBody extends StatefulWidget {
  const _ConsoleBody();

  @override
  State<_ConsoleBody> createState() => _ConsoleBodyState();
}

class _ConsoleBodyState extends State<_ConsoleBody> {
  final _scroll = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    pythonServer?.logLines.addListener(_onLines);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    pythonServer?.logLines.removeListener(_onLines);
    _scroll.dispose();
    super.dispose();
  }

  void _onLines() {
    if (!mounted) return;
    setState(() {});
    if (_autoScroll) _jumpToBottom();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final atBottom =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 60;
    if (atBottom != _autoScroll) setState(() => _autoScroll = atBottom);
  }

  void _jumpToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final server = pythonServer;
    final lines = server?.logLines.value ?? const [];
    final mono = AppSettings.instance.monoFontFamily ?? 'monospace';

    if (server == null) {
      return const ColoredBox(
        color: _kBg,
        child: Center(
          child: Text('No server instance.', style: TextStyle(color: _kDim)),
        ),
      );
    }

    if (lines.isEmpty) {
      return ColoredBox(
        color: _kBg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.terminal, size: 48, color: _kDim),
              const SizedBox(height: 12),
              Text(
                server.isRunning ? 'No output yet.' : 'Server is not running.',
                style: const TextStyle(color: _kDim, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: _kBg,
      child: Stack(
        children: [
          SelectionArea(
            child: ListView.builder(
              controller: _scroll,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: lines.length,
              itemBuilder: (_, i) {
                final line = lines[i];
                return Text(
                  line.text,
                  style: TextStyle(
                    fontFamily: mono,
                    fontSize: 12,
                    height: 1.5,
                    color: line.isError ? _kStderr : _kStdout,
                  ),
                );
              },
            ),
          ),
          if (!_autoScroll)
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: const Color(0xFF21262D),
                foregroundColor: Colors.white70,
                tooltip: 'Scroll to bottom',
                onPressed: () {
                  setState(() => _autoScroll = true);
                  _jumpToBottom();
                },
                child: const Icon(Icons.vertical_align_bottom),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen page (used when pushed as a route, e.g. mobile fallback)
// ---------------------------------------------------------------------------

class ServerConsolePage extends StatelessWidget {
  const ServerConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: _kHeader,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.serverConsoleTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear',
              onPressed: () => pythonServer?.logLines.value = [],
            ),
          ],
        ),
        body: const _ConsoleBody(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating panel (draggable overlay inside a Stack)
// ---------------------------------------------------------------------------

class ServerConsolePanel extends StatelessWidget {
  static const defaultWidth = 560.0;
  static const defaultHeight = 380.0;

  const ServerConsolePanel({
    super.key,
    required this.onDragDelta,
    required this.onClose,
  });

  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBg,
      elevation: 16,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: defaultWidth,
        height: defaultHeight,
        child: Column(
          children: [
            _PanelTitleBar(onDragDelta: onDragDelta, onClose: onClose),
            const Expanded(child: _ConsoleBody()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel title bar — drag handle + clear + close
// ---------------------------------------------------------------------------

class _PanelTitleBar extends StatelessWidget {
  const _PanelTitleBar({required this.onDragDelta, required this.onClose});

  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => onDragDelta(d.delta),
      child: Container(
        height: 36,
        color: _kHeader,
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Row(
          children: [
            const Icon(Icons.terminal, size: 14, color: _kDim),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Server Console',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _TitleBarButton(
              icon: Icons.delete_sweep_outlined,
              tooltip: 'Clear',
              onPressed: () => pythonServer?.logLines.value = [],
            ),
            _TitleBarButton(
              icon: Icons.close,
              tooltip: 'Close',
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatelessWidget {
  const _TitleBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 14),
      color: _kDim,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
