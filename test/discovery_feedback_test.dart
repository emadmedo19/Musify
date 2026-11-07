import 'package:flutter_test/flutter_test.dart';
import 'package:musify/models/discovery_feedback.dart';

Map song(String id, String artist) => {'ytid': id, 'artist': artist};
void main() {
  test(
    'not interested removes only that song from discovery, not the library',
    () {
      final source = [
        song('a', 'عمرو دياب'),
        song('b', 'عمرو دياب'),
        song('c', 'فيروز'),
      ];
      final feedback = DiscoveryFeedback().hide('a');
      expect(rankDiscoverySongs(source, feedback).map((s) => s['ytid']), [
        'b',
        'c',
      ]);
      expect(source, hasLength(3));
    },
  );
  test(
    'less of an artist demotes and caps them, with Arabic name normalization',
    () {
      final a = song('a', 'أحمد سعد');
      final source = [a, song('b', 'احمد سعد'), song('c', 'فيروز')];
      final feedback = DiscoveryFeedback().reduce(discoveryArtistKey(a)!);
      expect(rankDiscoverySongs(source, feedback).map((s) => s['ytid']), [
        'c',
        'a',
      ]);
    },
  );
  test(
    'recent repeats go behind new songs without removing all fallback options',
    () {
      final source = [song('old', 'a'), song('new', 'b'), song('old', 'a')];
      expect(
        rankDiscoverySongs(
          source,
          DiscoveryFeedback(),
          recentlyPlayed: {'old'},
        ).map((s) => s['ytid']),
        ['new', 'old'],
      );
    },
  );
  test(
    'feedback serializes and targeted undo does not erase newer feedback',
    () {
      final changed = DiscoveryFeedback()
          .hide('a')
          .hide('b')
          .reduce('name:artist');
      final restored = DiscoveryFeedback.fromStorage(changed.toStorage())
          .restoreSong('a');
      expect(restored.hiddenSongs, {'b'});
      expect(restored.reducedArtists, {'name:artist'});
    },
  );
}
