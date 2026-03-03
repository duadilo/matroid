import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_settings.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../server/server_base.dart';

// ---------------------------------------------------------------------------
// Server Console Page
// ---------------------------------------------------------------------------

/// Full-screen terminal-style page that streams stdout and stderr from the
/// Python server subprocess in real time.
class ServerConsolePage extends StatefulWidget {
  const ServerConsolePage({super.key});

  @override
  State<ServerConsolePage> createState() => _ServerConsolePageState();
}

class _ServerConsolePageState extends State<ServerConsolePage> {
  static const _bgColor = Color(0xFF0D1117);
  static const _headerColor = Color(0xFF161B22);
  static const _stdoutColor = Color(0xFF7EE787);
  static const _stderrColor = Color(0xFFFF7B72);
  static const _dimColor = Color(0xFF8B949E);

  final _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    pythonServer?.logLines.addListener(_onLinesChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    pythonServer?.logLines.removeListener(_onLinesChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLinesChanged() {
    if (!mounted) return;
    setState(() {});
    if (_autoScroll) _scrollToBottom();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 60;
    if (atBottom != _autoScroll) setState(() => _autoScroll = atBottom);
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  void _clear() => pythonServer?.logLines.value = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final server = pythonServer;
    final lines = server?.logLines.value ?? const [];
    final monoFont = AppSettings.instance.monoFontFamily ?? 'monospace';

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bgColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: _headerColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.serverConsoleTitle,
            style: TextStyle(
              fontFamily: monoFont,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            if (!_autoScroll)
              IconButton(
                icon: const Icon(Icons.vertical_align_bottom),
                tooltip: 'Scroll to bottom',
                onPressed: () {
                  setState(() => _autoScroll = true);
                  _scrollToBottom();
                },
              ),
            if (lines.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear',
                onPressed: _clear,
              ),
          ],
        ),
        body: _buildBody(lines, monoFont, server),
      ),
    );
  }

  Widget _buildBody(
    List<LogLine> lines,
    String monoFont,
    dynamic server,
  ) {
    if (server == null) {
      return const Center(
        child: Text(
          'No server instance available.',
          style: TextStyle(color: _dimColor),
        ),
      );
    }

    if (lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.terminal, size: 48, color: _dimColor),
            const SizedBox(height: 12),
            Text(
              server.isRunning ? 'No output yet.' : 'Server is not running.',
              style: const TextStyle(color: _dimColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SelectionArea(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: lines.length,
        itemBuilder: (context, i) {
          final line = lines[i];
          return Text(
            line.text,
            style: TextStyle(
              fontFamily: monoFont,
              fontSize: 12,
              height: 1.5,
              color: line.isError ? _stderrColor : _stdoutColor,
            ),
          );
        },
      ),
    );
  }
}
