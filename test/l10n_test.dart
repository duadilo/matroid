import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Loads an ARB file and returns its decoded JSON.
/// flutter test runs with the package root as the working directory.
Map<String, dynamic> _loadArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Returns only the translatable keys (skips @@locale and @-prefixed metadata).
Set<String> _translationKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Map<String, dynamic> en;
  late Map<String, dynamic> es;

  setUpAll(() {
    en = _loadArb('lib/l10n/app_en.arb');
    es = _loadArb('lib/l10n/app_es.arb');
  });

  group('ARB parity', () {
    test('ES has all keys that EN has (no missing translations)', () {
      final missing = _translationKeys(en).difference(_translationKeys(es));
      expect(missing, isEmpty,
          reason: 'Keys present in app_en.arb but missing from app_es.arb: $missing');
    });

    test('ES has no extra keys that EN does not have (no orphaned strings)', () {
      final extra = _translationKeys(es).difference(_translationKeys(en));
      expect(extra, isEmpty,
          reason: 'Keys present in app_es.arb but not in app_en.arb: $extra');
    });

    test('no translation is an empty string', () {
      for (final arb in [en, es]) {
        final locale = arb['@@locale'] as String?;
        for (final key in _translationKeys(arb)) {
          final value = arb[key];
          if (value is String) {
            expect(value.trim(), isNotEmpty,
                reason: '[$locale] "$key" is empty');
          }
        }
      }
    });
  });
}
