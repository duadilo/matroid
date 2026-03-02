import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:highlight/languages/markdown.dart' as md_lang;
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;

import '../l10n/app_localizations.dart';
import '../utils/save_file.dart';

// ---------------------------------------------------------------------------
// Showcase content
// ---------------------------------------------------------------------------

const _kDefaultSource = '''# Markdown Showcase

Welcome to the **Markdown** editor. Edit on the left; preview updates live on the right.

---

## Text Formatting

You can use *italic*, **bold**, ~~strikethrough~~, and `inline code`.

> "Markdown is intended to be as easy-to-read and easy-to-write as is feasible."
> — John Gruber

## Lists

### Unordered
- Apples
- Bananas
  - Cavendish
  - Plantain
- Cherries

### Ordered
1. Clone the repository
2. Run `flutter pub get`
3. Launch with `flutter run`

## Code Block

```python
def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a

print(fibonacci(10))  # 55
```

## Table

| Feature        | Supported |
|----------------|-----------|
| Headers        | ✓         |
| Bold / Italic  | ✓         |
| Code blocks    | ✓         |
| Tables         | ✓         |
| Links          | ✓         |

## Link

[Flutter documentation](https://docs.flutter.dev)

---

*End of showcase.*
''';

// ---------------------------------------------------------------------------
// MarkdownContent (body-only — no Scaffold)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Testable helpers (no platform calls)
// ---------------------------------------------------------------------------

@visibleForTesting
Future<Uint8List> buildMarkdownPdfBytes(
  String source,
  pw.Font font, [
  PdfPageFormat format = PdfPageFormat.a4,
]) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: format,
      theme: pw.ThemeData.withFont(base: font),
      build: (ctx) => [pw.Text(source, style: pw.TextStyle(font: font, fontSize: 11))],
    ),
  );
  return pdf.save();
}

@visibleForTesting
String buildMarkdownHtml(String source) {
  final body = md.markdownToHtml(source);
  return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Markdown Export</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
           max-width: 800px; margin: 40px auto; padding: 0 20px;
           line-height: 1.6; color: #333; }
    code { background: #f4f4f4; padding: 2px 5px; border-radius: 3px; }
    pre  { background: #f4f4f4; padding: 12px; border-radius: 6px; overflow-x: auto; }
    blockquote { border-left: 4px solid #ccc; margin: 0; padding-left: 16px; color: #666; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
    th { background: #f0f0f0; }
  </style>
</head>
<body>
$body
</body>
</html>''';
}

// ---------------------------------------------------------------------------

class MarkdownContent extends StatefulWidget {
  const MarkdownContent({super.key});

  @override
  State<MarkdownContent> createState() => _MarkdownContentState();
}

class _MarkdownContentState extends State<MarkdownContent> {
  late final CodeController _controller;
  late final FocusNode _focusNode;
  String _source = _kDefaultSource;
  pw.Font _pdfFont = pw.Font.helvetica();

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: _kDefaultSource,
      language: md_lang.markdown,
    );
    _focusNode = FocusNode();
    _controller.addListener(() {
      if (_controller.text != _source) {
        setState(() => _source = _controller.text);
      }
    });
    // Pre-load font in background so Export PDF is instant when clicked.
    PdfGoogleFonts.notoSansRegular().then((f) => _pdfFont = f);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---- Export helpers ------------------------------------------------------

  Future<void> _exportPdf(BuildContext context) async {
    final bytes = await buildMarkdownPdfBytes(_source, _pdfFont);
    await saveBytesFile(bytes, 'document.pdf');
  }

  Future<void> _exportHtml(BuildContext context) async {
    await saveTextFile(buildMarkdownHtml(_source), 'document.html');
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    return Column(
      children: [
        _buildToolbar(context),
        Expanded(
          child: isWide ? _buildWideLayout(context) : _buildNarrowLayout(context),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Chip(label: Text('Markdown')),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _exportPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(l10n.buttonExportPdf),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _exportHtml(context),
            icon: const Icon(Icons.code),
            label: Text(l10n.buttonExportHtml),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 1, child: _buildEditor(context)),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(flex: 1, child: _buildPreview(context)),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 1, child: _buildEditor(context)),
        const Divider(height: 1),
        Expanded(flex: 1, child: _buildPreview(context)),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styles = isDark ? monokaiSublimeTheme : atomOneLightTheme;
    return CodeTheme(
      data: CodeThemeData(styles: styles),
      child: CodeField(
        controller: _controller,
        focusNode: _focusNode,
        expands: true,
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styleSheet = isDark
        ? MarkdownStyleSheet.fromTheme(Theme.of(context))
        : MarkdownStyleSheet.fromTheme(Theme.of(context));
    return Markdown(
      data: _source,
      styleSheet: styleSheet,
    );
  }
}
