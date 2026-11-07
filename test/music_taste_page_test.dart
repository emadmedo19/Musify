import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/models/music_taste.dart';
import 'package:musify/screens/music_taste_page.dart';

void main() {
  testWidgets('picker uses the production Arabic Material UI host and theme', (
    tester,
  ) async {
    final theme = ThemeData.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: MusicTastePage(initial: MusicTaste(), onSave: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TextField));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Localizations.localeOf(context), const Locale('ar'));
    expect(MaterialLocalizations.of(context), isNotNull);
    await tester.enterText(find.byType(TextField), 'عمرو دياب');
    await tester.pump();
    await tester.tap(find.widgetWithText(Card, 'عمرو دياب'));
    await tester.pump();
    expect(find.text('حفظ اختياراتي (1)'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'search, choose and save selected artists without a network request',
    (tester) async {
      MusicTaste? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MusicTastePage(
                      initial: MusicTaste(),
                      onSave: (taste) async {
                        saved = taste;
                      },
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'عمرو دياب');
      await tester.pump();
      await tester.tap(find.widgetWithText(Card, 'عمرو دياب'));
      await tester.pump();
      await tester.tap(find.text('حفظ اختياراتي (1)'));
      await tester.pumpAndSettle();
      expect(saved?.artists, ['عمرو دياب']);
      expect(saved?.completed, isTrue);
      expect(find.text('open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editing restores choices and permits removing or adding a custom singer',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MusicTastePage(
            initial: MusicTaste(artists: ['عمرو دياب'], completed: true),
            onSave: (_) async {},
          ),
        ),
      );
      expect(find.text('حفظ اختياراتي (1)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'فنان جديد');
      await tester.pump();
      await tester.tap(find.text('إضافة "فنان جديد" لاختياراتي'));
      await tester.pump();
      expect(find.text('حفظ اختياراتي (2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a failed save retains selection and shows a retryable error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MusicTastePage(
          initial: MusicTaste(artists: ['شيرين عبد الوهاب'], completed: true),
          onSave: (_) async => throw StateError('disk unavailable'),
        ),
      ),
    );
    await tester.tap(find.text('حفظ اختياراتي (1)'));
    await tester.pumpAndSettle();
    expect(find.text('تعذّر حفظ اختياراتك. حاول مرة أخرى.'), findsOneWidget);
    expect(find.text('حفظ اختياراتي (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('small screens keep picker controls accessible', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MusicTastePage(initial: MusicTaste(), onSave: (_) async {}),
      ),
    );
    expect(find.text('استكشف من غير اختيارات دلوقتي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('landscape and keyboard do not overflow the picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: MusicTastePage(initial: MusicTaste(), onSave: (_) async {}),
      ),
    );
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'existing preferences can be cleared without returning to onboarding',
    (tester) async {
      MusicTaste? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: MusicTastePage(
            initial: MusicTaste(artists: ['عمرو دياب'], completed: true),
            onSave: (taste) async {
              saved = taste;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'عمرو دياب');
      await tester.pump();
      await tester.tap(find.widgetWithText(Card, 'عمرو دياب'));
      await tester.pump();
      await tester.tap(find.text('حفظ اختياراتي (0)'));
      await tester.pumpAndSettle();
      expect(saved?.artists, isEmpty);
      expect(saved?.completed, isTrue);
    },
  );
}
