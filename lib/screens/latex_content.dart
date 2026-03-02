import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:highlight/languages/tex.dart' as tex_lang;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;

import '../l10n/app_localizations.dart';
import '../utils/save_file.dart';

// ---------------------------------------------------------------------------
// Showcase content
// ---------------------------------------------------------------------------

const _kDefaultSource = r'''Math / LaTeX Showcase

Euler's famous identity:

$$e^{i\pi} + 1 = 0$$

The quadratic formula for $ax^2 + bx + c = 0$ is:

$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$

A definite integral example:

$$\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}$$

A 2×2 matrix and its determinant:

$$A = \begin{pmatrix} a & b \\ c & d \end{pmatrix}, \quad \det(A) = ad - bc$$

Greek letters and operators inline: the gradient $\nabla f$ and Laplacian $\Delta f = \sum_{i=1}^n \frac{\partial^2 f}{\partial x_i^2}$ appear frequently in physics.

Summation formula:

$$S = \sum_{k=1}^{n} k = \frac{n(n+1)}{2}$$

Binomial coefficient: $\binom{n}{k} = \frac{n!}{k!(n-k)!}$
''';

// ---------------------------------------------------------------------------
// LatexContent (body-only — no Scaffold)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Testable helpers (no platform calls)
// ---------------------------------------------------------------------------

@visibleForTesting
Future<Uint8List> buildLatexPdfBytes(
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
String buildLatexHtml(String source) {
  final lines = source.split('\n');
  final buffer = StringBuffer();
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (line.trim().startsWith(r'$$')) {
      final mathLines = <String>[line];
      i++;
      while (i < lines.length && !lines[i].trim().endsWith(r'$$')) {
        mathLines.add(lines[i]);
        i++;
      }
      if (i < lines.length) {
        mathLines.add(lines[i]);
        i++;
      }
      buffer.writeln('<p>${mathLines.join('\n')}</p>');
    } else if (line.trim().isEmpty) {
      buffer.writeln('<br>');
      i++;
    } else {
      buffer.writeln('<p>$line</p>');
      i++;
    }
  }

  return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Math Export</title>
  <script>
    MathJax = {
      tex: { inlineMath: [['\$', '\$']], displayMath: [['\$\$', '\$\$']] },
      options: { skipHtmlTags: ['script','noscript','style','textarea','pre'] }
    };
  </script>
  <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
           max-width: 800px; margin: 40px auto; padding: 0 20px;
           line-height: 1.8; color: #333; }
    p { margin: 0.5em 0; }
  </style>
</head>
<body>
${buffer.toString()}
</body>
</html>''';
}

// ---------------------------------------------------------------------------

class LatexContent extends StatefulWidget {
  const LatexContent({super.key});

  @override
  State<LatexContent> createState() => _LatexContentState();
}

class _LatexContentState extends State<LatexContent> {
  late final CodeController _controller;
  late final FocusNode _focusNode;
  String _source = _kDefaultSource;
  pw.Font _pdfFont = pw.Font.helvetica();

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: _kDefaultSource,
      language: tex_lang.tex,
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
    final bytes = await buildLatexPdfBytes(_source, _pdfFont);
    await saveBytesFile(bytes, 'math.pdf');
  }

  Future<void> _exportHtml(BuildContext context) async {
    await saveTextFile(buildLatexHtml(_source), 'math.html');
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
          const Chip(label: Text('Math')),
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
    return _LatexPreview(source: _source);
  }
}

// ---------------------------------------------------------------------------
// LaTeX preview widget
// ---------------------------------------------------------------------------

class _LatexPreview extends StatelessWidget {
  const _LatexPreview({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final segments = _parseSegments(source);
    final textStyle = Theme.of(context).textTheme.bodyMedium!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((seg) => _buildSegment(seg, textStyle)).toList(),
      ),
    );
  }

  Widget _buildSegment(_Segment seg, TextStyle textStyle) {
    switch (seg.type) {
      case _SegmentType.text:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildInlineText(seg.content, textStyle),
        );
      case _SegmentType.block:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Math.tex(
              seg.content,
              mathStyle: MathStyle.display,
              textStyle: textStyle,
              onErrorFallback: (e) => Text(
                '⚠ ${e.message}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        );
    }
  }

  /// Renders a plain-text line that may contain inline \$...\$ math.
  Widget _buildInlineText(String text, TextStyle textStyle) {
    final parts = _splitInline(text);
    if (parts.length == 1 && parts.first.isText) {
      return Text(text, style: textStyle);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: parts.map((part) {
        if (part.isText) {
          return Text(part.content, style: textStyle);
        }
        return Math.tex(
          part.content,
          mathStyle: MathStyle.text,
          textStyle: textStyle,
          onErrorFallback: (e) => Text(
            '⚠ ${e.message}',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  // ---- Parsing helpers -----------------------------------------------------

  /// Splits source into block-math ($$…$$) and text segments.
  List<_Segment> _parseSegments(String source) {
    final segments = <_Segment>[];
    final blockRegex = RegExp(r'\$\$([\s\S]*?)\$\$');
    int cursor = 0;
    for (final match in blockRegex.allMatches(source)) {
      if (match.start > cursor) {
        final text = source.substring(cursor, match.start);
        for (final line in text.split('\n')) {
          segments.add(_Segment(_SegmentType.text, line));
        }
      }
      segments.add(_Segment(_SegmentType.block, match.group(1)!.trim()));
      cursor = match.end;
    }
    if (cursor < source.length) {
      final rest = source.substring(cursor);
      for (final line in rest.split('\n')) {
        segments.add(_Segment(_SegmentType.text, line));
      }
    }
    return segments;
  }

  /// Splits a text line into plain-text and inline-math (\$…\$) parts.
  List<_InlinePart> _splitInline(String text) {
    final parts = <_InlinePart>[];
    final inlineRegex = RegExp(r'\$((?:[^$\\]|\\.)+?)\$');
    int cursor = 0;
    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > cursor) {
        parts.add(_InlinePart(true, text.substring(cursor, match.start)));
      }
      parts.add(_InlinePart(false, match.group(1)!));
      cursor = match.end;
    }
    if (cursor < text.length) {
      parts.add(_InlinePart(true, text.substring(cursor)));
    }
    return parts.isEmpty ? [_InlinePart(true, text)] : parts;
  }
}

enum _SegmentType { text, block }

class _Segment {
  const _Segment(this.type, this.content);
  final _SegmentType type;
  final String content;
}

class _InlinePart {
  const _InlinePart(this.isText, this.content);
  final bool isText;
  final String content;
}
