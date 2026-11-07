import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/regional_discovery.dart';

Map song(String id) => {'ytid': id, 'title': id};

void main() {
  test('Egypt gets three query slots and another Arab artist gets one', () {
    for (var seed = 0; seed < 20; seed++) {
      final queries = regionalSongQueries(random: Random(seed));
      expect(queries, hasLength(4));
      expect(queries.first, egyptianArtistQueries.first);
      expect(queries.where(egyptianArtistQueries.contains), hasLength(3));
      expect(queries.where(arabicArtistQueries.contains), hasLength(1));
      expect(queries.toSet(), hasLength(4));
    }
  });

  test('different sessions explore more than a fixed set of artists', () {
    final queries = <String>{};
    for (var seed = 0; seed < 20; seed++) {
      queries.addAll(regionalSongQueries(random: Random(seed)));
    }
    expect(queries.length, greaterThan(8));
  });

  test('interleaves artists, removes duplicates and respects bounds', () {
    final sources = [
      [song('a'), song('shared'), song('c')],
      [song('b'), song('shared'), song('d')],
      [
        <String, dynamic>{'title': 'invalid'},
        song('e'),
      ],
    ];
    expect(interleaveDiscoveryResults(sources, 5).map((s) => s['ytid']), [
      'a',
      'b',
      'shared',
      'e',
      'c',
    ]);
    expect(interleaveDiscoveryResults(sources, 0), isEmpty);
  });

  test(
    'regional majority holds even with a large foreign personal history',
    () {
      final regional = List.generate(32, (i) => song('regional-$i'));
      final personal = List.generate(100, (i) => song('personal-$i'));
      final items = blendRegionalRecommendations(regional, personal);
      expect(items, hasLength(15));
      expect(
        items.where((s) => s['ytid'].startsWith('regional-')),
        hasLength(10),
      );
      expect(
        items.where((s) => s['ytid'].startsWith('personal-')),
        hasLength(5),
      );
    },
  );

  test('new installs have regional suggestions without listening history', () {
    final regional = List.generate(32, (i) => song('r-$i'));
    expect(blendRegionalRecommendations(regional, []), hasLength(15));
  });

  test(
    'failed regional provider falls back to personal music without data loss',
    () {
      final personal = List.generate(20, (i) => song('p-$i'));
      expect(blendRegionalRecommendations([], personal), personal.take(15));
    },
  );

  test(
    'overlap is deduplicated and remaining regional songs fill the shelf',
    () {
      final regional = List.generate(20, (i) => song('r-$i'));
      final items = blendRegionalRecommendations(
        regional,
        regional.take(5).toList(),
      );
      expect(items, hasLength(15));
      expect(items.map((s) => s['ytid']).toSet(), hasLength(15));
    },
  );

  test(
    'one failing category preserves playable results from the others',
    () async {
      final calls = <String>[];
      final results = await loadRegionalDiscovery(
        ['egypt', 'failed', 'arabic'],
        (query) async {
          calls.add(query);
          if (query == 'failed') throw StateError('provider unavailable');
          return List.generate(10, (i) => song('$query-$i'));
        },
        perQuery: 2,
        limit: 8,
      );
      expect(calls, containsAll(['egypt', 'failed', 'arabic']));
      expect(results.map((s) => s['ytid']), [
        'egypt-0',
        'arabic-0',
        'egypt-1',
        'arabic-1',
      ]);
    },
  );
}
