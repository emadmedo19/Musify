import 'package:musify/models/music_taste.dart';

String? discoveryArtistKey(Map song) {
  final name = (song['artist'] ?? song['videoAuthor'])?.toString().trim() ?? '';
  if (name.isNotEmpty) return 'name:${normalizeSingerName(name)}';
  final id = song['artistId']?.toString().trim() ?? '';
  return id.isEmpty ? null : 'id:$id';
}

class DiscoveryFeedback {
  DiscoveryFeedback({
    Iterable<String> hiddenSongs = const [],
    Iterable<String> reducedArtists = const [],
  }) : hiddenSongs = Set.unmodifiable(hiddenSongs.take(2000)),
       reducedArtists = Set.unmodifiable(reducedArtists.take(500));
  factory DiscoveryFeedback.fromStorage(dynamic value) {
    if (value is! Map) return DiscoveryFeedback();
    Iterable<String> strings(dynamic list) => list is List
        ? list.whereType<String>().where((s) => s.isNotEmpty)
        : const [];
    return DiscoveryFeedback(
      hiddenSongs: strings(value['hiddenSongs']),
      reducedArtists: strings(value['reducedArtists']),
    );
  }
  final Set<String> hiddenSongs;
  final Set<String> reducedArtists;
  Map<String, dynamic> toStorage() => {
    'hiddenSongs': hiddenSongs.toList(),
    'reducedArtists': reducedArtists.toList(),
  };
  DiscoveryFeedback hide(String id) => DiscoveryFeedback(
    hiddenSongs: [id, ...hiddenSongs],
    reducedArtists: reducedArtists,
  );
  DiscoveryFeedback reduce(String key) => DiscoveryFeedback(
    hiddenSongs: hiddenSongs,
    reducedArtists: [key, ...reducedArtists],
  );
  DiscoveryFeedback restoreSong(String id) => DiscoveryFeedback(
    hiddenSongs: hiddenSongs.where((s) => s != id),
    reducedArtists: reducedArtists,
  );
  DiscoveryFeedback restoreArtist(String key) => DiscoveryFeedback(
    hiddenSongs: hiddenSongs,
    reducedArtists: reducedArtists.where((s) => s != key),
  );
}

List<Map> rankDiscoverySongs(
  Iterable<dynamic> source,
  DiscoveryFeedback feedback, {
  Set<String> recentlyPlayed = const {},
  int limit = 15,
}) {
  if (limit <= 0) return [];
  final seen = <String>{};
  final songs = source.whereType<Map>().where((s) {
    final id = s['ytid']?.toString().trim() ?? '';
    return id.isNotEmpty && !feedback.hiddenSongs.contains(id) && seen.add(id);
  }).toList();
  int score(Map song) =>
      (recentlyPlayed.contains(song['ytid']?.toString()) ? 1 : 0) +
      (feedback.reducedArtists.contains(discoveryArtistKey(song)) ? 4 : 0);
  final indexed = songs.asMap().entries.toList()
    ..sort((a, b) {
      final order = score(a.value).compareTo(score(b.value));
      return order == 0 ? a.key.compareTo(b.key) : order;
    });
  final reducedCounts = <String, int>{};
  return indexed
      .map((e) => e.value)
      .where((song) {
        final key = discoveryArtistKey(song);
        if (key == null || !feedback.reducedArtists.contains(key)) return true;
        final count = reducedCounts[key] ?? 0;
        reducedCounts[key] = count + 1;
        return count == 0;
      })
      .take(limit)
      .toList();
}
