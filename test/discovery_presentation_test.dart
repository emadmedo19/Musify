import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify/widgets/discovery_presentation.dart';

void main() {
  testWidgets(
    'compact Arabic discovery remains scrollable and artist actions work',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? chosen;
      var played = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    DiscoveryWelcome(onEdit: () {}),
                    ArtistDiscoveryStrip(
                      artists: const ['عمرو دياب', 'شيرين عبد الوهاب', 'فيروز'],
                      onArtist: (name) => chosen = name,
                    ),
                    NinetiesSpotlight(onPlay: () => played = true),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('عمرو دياب'));
      expect(chosen, 'عمرو دياب');
      await tester.ensureVisible(find.text('شغّل الذكريات'));
      await tester.tap(find.text('شغّل الذكريات'));
      expect(played, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('artist cover remains readable without a source image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [DiscoveryArtistCover(title: 'عمرو دياب', isChosen: true)],
          ),
        ),
      ),
    );
    expect(find.text('عمرو دياب'), findsOneWidget);
    expect(find.text('من اختياراتك'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('labeled player panels retain real lyrics and queue actions', (
    tester,
  ) async {
    var lyrics = false;
    var queue = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerQuickLinks(
            onLyrics: () => lyrics = true,
            onQueue: () => queue = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('كلمات الأغنية'));
    await tester.tap(find.text('التالي في القائمة'));
    expect(lyrics, isTrue);
    expect(queue, isTrue);
  });
}
