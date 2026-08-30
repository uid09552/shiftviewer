// The language preference is persisted like the rest of the settings, and maps
// to the locale MaterialApp renders in.

import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftviewer/services/app_settings.dart';

void main() {
  test('language preference survives a JSON round trip', () {
    const settings = AppSettings(languageCode: 'de');
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.languageCode, 'de');
    expect(restored.locale, const Locale('de'));
  });

  test('an unset or unknown language falls back to the device locale', () {
    expect(const AppSettings().locale, isNull);
    expect(const AppSettings(languageCode: 'fr').locale, isNull);
  });

  test('settings written before the language existed still load', () {
    final legacy = const AppSettings().toJson()..remove('languageCode');
    expect(AppSettings.fromJson(legacy).languageCode, '');
  });
}
