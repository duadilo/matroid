import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../server/platform/server_platform.dart';
import '../server/server_mode.dart';

// ---------------------------------------------------------------------------
// Startup state
// ---------------------------------------------------------------------------

enum _StartupState { connecting, ready, failed }

// ---------------------------------------------------------------------------
// Home content (body-only — no Scaffold)
// ---------------------------------------------------------------------------

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  static const _maxAttempts = 3;
  static const _retryDelay = Duration(seconds: 2);

  _StartupState _startupState = _StartupState.connecting;
  int _attempt = 0;
  Object? _lastError;
  String? _statusMessage;
  Uint8List? _exportedBytes;

  @override
  void initState() {
    super.initState();
    excelService?.featuresEnabled.addListener(_onFeaturesChanged);
    if (!isDesktop) {
      _startupState = _StartupState.ready;
    } else if (pythonServer?.isRunning == true) {
      // Server already running (e.g. navigated away and back) — skip startup.
      _startupState = _StartupState.ready;
    } else if (serverStartupFuture != null) {
      // Another mount already started the startup sequence — join it.
      serverStartupFuture!.then((_) {
        if (!mounted) return;
        setState(() => _startupState = pythonServer?.isRunning == true
            ? _StartupState.ready
            : _StartupState.failed);
      });
    } else {
      _runStartup();
    }
  }

  @override
  void dispose() {
    excelService?.featuresEnabled.removeListener(_onFeaturesChanged);
    super.dispose();
  }

  void _onFeaturesChanged() => setState(() {});

  // ---- Server startup with auto-retry --------------------------------------

  Future<void> _runStartup() async {
    setState(() {
      _startupState = _StartupState.connecting;
      _lastError = null;
    });
    serverStartupFuture = _doStartup();
    await serverStartupFuture;
    serverStartupFuture = null;
  }

  Future<void> _doStartup() async {

    // Await the extraction future started in main() — on the first call it may
    // still be running; on retries we re-extract in case the cache was stale.
    final binaryPath = await (binaryPathFuture ?? extractServerBinary());

    for (_attempt = 1; _attempt <= _maxAttempts; _attempt++) {
      if (!mounted) return;
      setState(() {}); // refresh attempt counter in UI

      try {
        // Stop any previously failed instance before retrying.
        await pythonServer?.stop();
        pythonServer = PythonServer(binaryPath: binaryPath);
        excelService!.server = pythonServer;

        await pythonServer!.start();

        excelService!.mode = ServerMode.local;
        excelService!.featuresEnabled.value = true;
        chatService?.server = pythonServer;
        chatService?.mode = ServerMode.local;
        if (!mounted) return;
        setState(() => _startupState = _StartupState.ready);
        return;
      } catch (e) {
        _lastError = e;
        pythonServer = null;
        excelService!.server = null;

        if (_attempt < _maxAttempts) {
          // Wait before next attempt, updating the UI each second.
          for (var s = _retryDelay.inSeconds; s > 0; s--) {
            if (!mounted) return;
            setState(() {}); // repaints the countdown
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
    }

    // All attempts exhausted.
    if (!mounted) return;
    excelService!.mode = ServerMode.remote;
    setState(() => _startupState = _StartupState.failed);
  }

  // ---- Server controls -----------------------------------------------------

  void _switchToRemote() {
    excelService?.mode = ServerMode.remote;
    chatService?.mode = ServerMode.remote;
    setState(() => _startupState = _StartupState.ready);
  }

  // ---- Excel controls ------------------------------------------------------

  Future<void> _pickAndLoad(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (!mounted) return;
    setState(() => _statusMessage = l10n.statusLoadingFile(file.name));
    try {
      await excelService!.loadFile(
        filePath: file.path,
        bytes: file.bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      setState(() => _statusMessage = l10n.statusLoaded(file.name));
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = l10n.statusLoadError(e.toString()));
    }
  }

  Future<void> _process(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _statusMessage = l10n.statusProcessing);
    try {
      final result = await excelService!.process({'operation': 'summary'});
      if (!mounted) return;
      setState(() => _statusMessage = l10n.statusProcessResult(result.toString()));
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = l10n.statusProcessError(e.toString()));
    }
  }

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _statusMessage = l10n.statusExporting);
    try {
      _exportedBytes = await excelService!.export();
      if (!mounted) return;
      setState(() => _statusMessage = l10n.statusExported(_exportedBytes!.length));
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = l10n.statusExportError(e.toString()));
    }
  }

  void _unload(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    excelService?.unload();
    setState(() {
      _statusMessage = l10n.statusUnloadSent;
      _exportedBytes = null;
    });
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return switch (_startupState) {
      _StartupState.connecting => _buildConnecting(context),
      _StartupState.failed     => _buildFailed(context),
      _StartupState.ready      => _buildReady(context),
    };
  }

  // --- Loading overlay -------------------------------------------------------

  Widget _buildConnecting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFirstAttempt = _attempt <= 1;
    final label = isFirstAttempt
        ? l10n.statusStartingServer
        : l10n.statusRetrying(_attempt, _maxAttempts);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              label,
              key: ValueKey(label),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (!isFirstAttempt && _lastError != null) ...[
            const SizedBox(height: 8),
            Text(
              _lastError.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // --- Failure banner + controls --------------------------------------------

  Widget _buildFailed(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          content: Text(
            l10n.statusServerFailed(_maxAttempts, _lastError.toString()),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: _runStartup,
              child: Text(l10n.buttonRetry),
            ),
            TextButton(
              onPressed: _switchToRemote,
              child: Text(l10n.buttonUseRemote),
            ),
          ],
        ),
        Expanded(child: _buildControls(context)),
      ],
    );
  }

  // --- Main controls --------------------------------------------------------

  Widget _buildReady(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final featuresOn = excelService?.featuresEnabled.value ?? true;

    if (!featuresOn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MaterialBanner(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Text(
              l10n.featuresDisabledMessage,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            actions: [
              if (isDesktop)
                TextButton(
                  onPressed: _runStartup,
                  child: Text(l10n.buttonRetryLocal),
                ),
              TextButton(
                onPressed: _switchToRemote,
                child: Text(l10n.buttonUseRemote),
              ),
            ],
          ),
          Expanded(child: _buildControls(context)),
        ],
      );
    }

    return _buildControls(context);
  }

  Widget _buildControls(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final featuresOn = excelService?.featuresEnabled.value ?? true;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: featuresOn ? () => _pickAndLoad(context) : null,
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.buttonLoadFile),
              ),
              FilledButton.icon(
                onPressed: featuresOn ? () => _process(context) : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.buttonProcess),
              ),
              FilledButton.icon(
                onPressed: featuresOn ? () => _export(context) : null,
                icon: const Icon(Icons.download),
                label: Text(l10n.buttonExport),
              ),
              OutlinedButton.icon(
                onPressed: featuresOn ? () => _unload(context) : null,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.buttonUnload),
              ),
            ],
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 24),
            Text(
              _statusMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.modeLabel(excelService?.mode.name ?? '—'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
