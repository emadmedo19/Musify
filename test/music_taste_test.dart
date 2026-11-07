import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/models/music_taste.dart';
import 'package:musify/utilities/regional_discovery.dart';

void main() {
  test('first install needs onboarding but a saved skip does not', () {
    expect(MusicTaste.fromStorage(null).completed, isFalse);
    final skipped = MusicTaste(completed: true);
    expect(MusicTaste.fromStorage(skipped.toStorage()).completed, isTrue);
    expect(MusicTaste.fromStorage(skipped.toStorage()).artists, isEmpty);
  });
  test(
    'preferences round trip without losing selected artists or nineties',
    () {
      final taste = MusicTaste(
        artists: ['عمرو دياب', 'فيروز'],
        includeNineties: false,
        completed: true,
      );
      final restored = MusicTaste.fromStorage(taste.toStorage());
      expect(restored.artists, ['عمرو دياب', 'فيروز']);
      expect(restored.includeNineties, isFalse);
      expect(restored.completed, isTrue);
    },
  );
  test('Arabic spelling variants and diacritics do not duplicate artists', () {
    expect(
      cleanSingerNames([
        '  أحمد   سعد ',
        'احمد سعد',
        'أَحْمَد سعد',
        null,
        5,
        '',
      ]),
      ['أحمد سعد'],
    );
  });
  test('invalid saved data safely returns editable defaults', () {
    final taste = MusicTaste.fromStorage({
      'artists': 5,
      'includeNineties': 'bad',
      'completed': 'yes',
    });
    expect(taste.artists, isEmpty);
    expect(taste.includeNineties, isTrue);
    expect(taste.completed, isFalse);
  });
  test('catalog is broad and supports names beyond its built-in list', () {
    expect(
      cleanSingerNames([...egyptianSingers, ...arabSingers]).length,
      greaterThan(140),
    );
    expect(MusicTaste(artists: ['فنان جديد مستقل']).artists, [
      'فنان جديد مستقل',
    ]);
  });
  test(
    'personal songs never silently substitute unselected default artists',
    () {
      final artists = ['شيرين عبد الوهاب', 'فيروز'];
      final queries = personalizedArtistQueries(artists, random: Random(1));
      expect(queries.toSet(), {
        'شيرين عبد الوهاب official audio',
        'فيروز official audio',
      });
      expect(queries.any((q) => q.contains('عمرو دياب')), isFalse);
    },
  );
  test('personal playlist requests respect the optional nineties shelf', () {
    final artists = ['شيرين عبد الوهاب', 'فيروز'];
    final noNineties = personalizedPlaylistQueries(
      artists,
      includeNineties: false,
    );
    expect(noNineties.toSet(), {'شيرين عبد الوهاب أغاني', 'فيروز أغاني'});
    expect(personalizedPlaylistQueries(artists).last, contains('التسعينات'));
  });
  test('changing preferences changes the cache identity immediately', () {
    final first = MusicTaste(artists: ['عمرو دياب']);
    expect(first.cacheKey, isNot(MusicTaste(artists: ['فيروز']).cacheKey));
    expect(
      first.cacheKey,
      isNot(
        MusicTaste(artists: ['عمرو دياب'], includeNineties: false).cacheKey,
      ),
    );
  });
  test(
    'names containing delimiters do not collide in recommendation caches',
    () {
      expect(
        MusicTaste(artists: ['a|b', 'c']).cacheKey,
        isNot(MusicTaste(artists: ['a', 'b|c']).cacheKey),
      );
    },
  );
}
