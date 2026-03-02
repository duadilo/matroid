import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:matroid/screens/markdown_content.dart';
import 'package:matroid/screens/latex_content.dart';

// Use Helvetica (built-in, no network) as the test font.
// Tests verify structure, not Unicode rendering.
pw.Font get _font => pw.Font.helvetica();

void main() {
  // =========================================================================
  // Markdown PDF
  // =========================================================================

  group('buildMarkdownPdfBytes', () {
    test('returns non-empty bytes', () async {
      final bytes = await buildMarkdownPdfBytes('# Hello\nWorld', _font);
      expect(bytes, isNotEmpty);
    });

    test('output starts with PDF magic bytes', () async {
      final bytes = await buildMarkdownPdfBytes('# Hello\nWorld', _font);
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, equals('%PDF'));
    });

    test('respects custom page format', () async {
      final bytes = await buildMarkdownPdfBytes(
        'Test',
        _font,
        PdfPageFormat.letter,
      );
      expect(bytes, isNotEmpty);
    });

    test('handles empty source', () async {
      final bytes = await buildMarkdownPdfBytes('', _font);
      expect(bytes, isNotEmpty);
    });
  });

  // =========================================================================
  // Markdown HTML
  // =========================================================================

  group('buildMarkdownHtml', () {
    test('returns valid HTML document', () {
      final html = buildMarkdownHtml('# Hello');
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('</html>'));
    });

    test('converts heading to <h1>', () {
      final html = buildMarkdownHtml('# Hello');
      expect(html, contains('<h1>'));
    });

    test('converts bold to <strong>', () {
      final html = buildMarkdownHtml('**bold**');
      expect(html, contains('<strong>'));
    });

    test('converts inline code', () {
      final html = buildMarkdownHtml('use `print()`');
      expect(html, contains('<code>'));
    });

    test('includes CSS stylesheet', () {
      final html = buildMarkdownHtml('hello');
      expect(html, contains('<style>'));
    });

    test('handles empty source', () {
      final html = buildMarkdownHtml('');
      expect(html, contains('<!DOCTYPE html>'));
    });
  });

  // =========================================================================
  // LaTeX PDF
  // =========================================================================

  group('buildLatexPdfBytes', () {
    test('returns non-empty bytes', () async {
      final bytes = await buildLatexPdfBytes(r'E = mc^2', _font);
      expect(bytes, isNotEmpty);
    });

    test('output starts with PDF magic bytes', () async {
      final bytes = await buildLatexPdfBytes(r'$$E = mc^2$$', _font);
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, equals('%PDF'));
    });

    test('handles empty source', () async {
      final bytes = await buildLatexPdfBytes('', _font);
      expect(bytes, isNotEmpty);
    });
  });

  // =========================================================================
  // LaTeX HTML
  // =========================================================================

  group('buildLatexHtml', () {
    test('returns valid HTML document', () {
      final html = buildLatexHtml(r'$$E = mc^2$$');
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('</html>'));
    });

    test('includes MathJax CDN script', () {
      final html = buildLatexHtml('hello');
      expect(html, contains('mathjax'));
    });

    test('wraps block math in paragraph tags', () {
      final html = buildLatexHtml(r'$$x = 1$$');
      expect(html, contains('<p>'));
      expect(html, contains(r'$$'));
    });

    test('wraps plain text in paragraph tags', () {
      final html = buildLatexHtml('plain text line');
      expect(html, contains('<p>plain text line</p>'));
    });

    test('empty lines become <br>', () {
      final html = buildLatexHtml('line1\n\nline2');
      expect(html, contains('<br>'));
    });

    test('handles empty source', () {
      final html = buildLatexHtml('');
      expect(html, contains('<!DOCTYPE html>'));
    });
  });
}
