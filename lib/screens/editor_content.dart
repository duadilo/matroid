import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';

import '../app_state.dart';
import '../server/excel_service.dart';

// ---------------------------------------------------------------------------
// Default starter code
// ---------------------------------------------------------------------------

const _kDefaultCodePython = '''# --- Available globals ---
# get_data()              → list of row dicts  ([] if no file loaded)
# get_sheet_names()       → list of sheet name strings
# get_headers()           → list of column header strings
# to_csv()                → loaded data as a CSV string
# summarize()             → {col: {count, unique, sample}} stats dict
# filter_rows(col, val)   → rows where col == val

data = get_data()
print(f"Rows: {len(data)}")
print(f"Columns: {get_headers()}")

# Uncomment to explore further:
# print(summarize())
# print(filter_rows("Name", "Alice"))
# print(to_csv())
''';

const _kDefaultCodeJs = '''// --- Available globals ---
// getData()              → array of row objects  ([] if no file loaded)
// getSheetNames()        → array of sheet name strings
// getHeaders()           → array of column header strings
// toCsv()                → loaded data as a CSV string
// summarize()            → {col: {count, unique, sample}} stats object
// filterRows(col, val)   → rows where col === val

const data = getData();
console.log(`Rows: \${data.length}`);
console.log(`Columns: \${getHeaders().join(", ")}`);

// Uncomment to explore further:
// console.log(summarize());
// console.log(filterRows("Name", "Alice"));
// console.log(toCsv());
''';

// ---------------------------------------------------------------------------
// Editor content (body-only — no Scaffold)
// ---------------------------------------------------------------------------

class EditorContent extends StatefulWidget {
  const EditorContent({super.key});

  @override
  State<EditorContent> createState() => _EditorContentState();
}

class _EditorContentState extends State<EditorContent> {
  static const _kPython = 'python';
  static const _kJavascript = 'javascript';

  String _lang = _kPython;
  String _currentDefault = _kDefaultCodePython;
  late final CodeController _controller;
  late final FocusNode _focusNode;

  bool _isRunning = false;
  ExecuteResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(text: _kDefaultCodePython, language: python);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _changeLanguage(String lang) {
    final newDefault = lang == _kPython ? _kDefaultCodePython : _kDefaultCodeJs;
    // Only swap the starter code if the user hasn't edited it yet.
    if (_controller.text == _currentDefault) {
      _controller.text = newDefault;
    }
    _controller.setLanguage(
      lang == _kPython ? python : javascript,
      analyzer: const DefaultLocalAnalyzer(),
    );
    setState(() {
      _lang = lang;
      _currentDefault = newDefault;
    });
    _focusNode.requestFocus();
  }

  Future<void> _runCode() async {
    final service = excelService;
    if (service == null) {
      setState(() {
        _lastResult = const ExecuteResult(
          stdout: '',
          stderr: '',
          error: 'Server not connected. Start the local server or enable remote mode.',
          executionTimeMs: 0,
        );
      });
      return;
    }

    setState(() => _isRunning = true);
    try {
      final result = await service.execute(
        language: _lang,
        code: _controller.text,
      );
      if (mounted) setState(() => _lastResult = result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastResult = ExecuteResult(
            stdout: '',
            stderr: '',
            error: e.toString(),
            executionTimeMs: 0,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styles = isDark ? monokaiSublimeTheme : atomOneLightTheme;

    return Column(
      children: [
        _buildToolbar(context),
        Expanded(
          flex: 3,
          child: CodeTheme(
            data: CodeThemeData(styles: styles),
            child: CodeField(
              controller: _controller,
              focusNode: _focusNode,
              expands: true,
            ),
          ),
        ),
        _buildOutputPanel(context, isDark),
      ],
    );
  }

  // ---- Toolbar -------------------------------------------------------------

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _kPython, label: Text('Python')),
              ButtonSegment(value: _kJavascript, label: Text('JavaScript')),
            ],
            selected: {_lang},
            onSelectionChanged: (sel) => _changeLanguage(sel.first),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _isRunning ? null : _runCode,
            icon: _isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isRunning ? 'Running…' : 'Run'),
          ),
        ],
      ),
    );
  }

  // ---- Output panel --------------------------------------------------------

  Widget _buildOutputPanel(BuildContext context, bool isDark) {
    final dividerColor = Theme.of(context).dividerColor;
    final panelBg = isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F5F5);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text('OUTPUT', style: labelStyle),
                if (_lastResult != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_lastResult!.executionTimeMs} ms',
                    style: labelStyle,
                  ),
                ],
                const Spacer(),
                if (_lastResult != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Clear output',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _lastResult = null),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildOutputBody(context, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputBody(BuildContext context, bool isDark) {
    if (_lastResult == null) {
      return Text(
        'Output will appear here after you press Run.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final result = _lastResult!;
    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: isDark ? Colors.white70 : Colors.black87,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.stdout.isNotEmpty)
          SelectableText(result.stdout, style: codeStyle),
        if (result.stderr.isNotEmpty && result.error == null)
          SelectableText(
            result.stderr,
            style: codeStyle.copyWith(color: Colors.orange[isDark ? 300 : 700]),
          ),
        if (result.error != null)
          SelectableText(
            result.error!,
            style: codeStyle.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        if (result.stdout.isEmpty && result.stderr.isEmpty && result.error == null)
          Text(
            '(no output)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}
