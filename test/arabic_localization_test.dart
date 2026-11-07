import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/utilities/language_utils.dart';

void main() {
  test(
    'every base app message has an Arabic translation with its placeholders',
    () {
      final base = jsonDecode(
        File('lib/localization/app_en.arb').readAsStringSync(),
      ) as Map;
      final arabic = jsonDecode(
        File('lib/localization/app_ar.arb').readAsStringSync(),
      ) as Map;
      for (final key in base.keys.whereType<String>().where(
        (k) => !k.startsWith('@'),
      )) {
        expect(arabic[key], isA<String>(), reason: key);
        expect((arabic[key] as String).trim(), isNotEmpty, reason: key);
        final metadata = base['@$key'];
        if (metadata is Map && metadata['placeholders'] is Map) {
          for (final placeholder in (metadata['placeholders'] as Map).keys) {
            expect(arabic[key], contains('{$placeholder'), reason: key);
          }
        }
      }
    },
  );
  testWidgets('Arabic is selectable and renders RTL app navigation', (
    tester,
  ) async {
    expect(appLanguages, contains('ar'));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: appSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            return Text(AppLocalizations.of(context)!.home);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('الرئيسية'), findsOneWidget);
  });
}
