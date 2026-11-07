import 'package:musify/main.dart' show logger;
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/playlists_manager.dart' show onlinePlaylists;
import 'package:musify/services/proxy_manager.dart' show ytClient;
import 'package:musify/services/settings_manager.dart' show offlineMode;
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/regional_discovery.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<List<Map>>? _songsInFlight;
List<Map>? _songCache;
DateTime? _songsLoadedAt;

Future<List<Map>> _cachedSearch(
  String kind,
  String query,
  DiscoverySearch search,
) async {
  final key = 'regional_discovery_v1_${kind}_$query';
  try {
    final cached = await getData(
      'cache',
      key,
      cachingDuration: const Duration(hours: 6),
    );
    if (cached is List && cached.isNotEmpty) {
      return cached.whereType<Map>().toList();
    }
  } catch (e, st) {
    logger.log(
      'Regional discovery cache read failed',
      error: e,
      stackTrace: st,
    );
  }
  if (offlineMode.value) return [];
  final items = await search(query).timeout(const Duration(seconds: 12));
  if (items.isNotEmpty) {
    try {
      await addOrUpdateData('cache', key, items);
    } catch (e, st) {
      logger.log(
        'Regional discovery cache write failed',
        error: e,
        stackTrace: st,
      );
    }
  }
  return items;
}

Future<List<Map>> getRegionalHomeSongs() async {
  if (_songCache != null &&
      _songsLoadedAt != null &&
      DateTime.now().difference(_songsLoadedAt!) < const Duration(hours: 6)) {
    return _songCache!;
  }
  return _songsInFlight ??= _loadRegionalHomeSongs().whenComplete(() {
    _songsInFlight = null;
  });
}

Future<List<Map>> _loadRegionalHomeSongs() async {
  final songs = await loadRegionalDiscovery(
    regionalSongQueries(),
    (query) => _cachedSearch('songs', query, (term) async {
      final results = await ytClient.search.search(term);
      return results.map((video) => returnSongLayout(0, video)).toList();
    }),
    perQuery: 8,
    limit: 32,
  );
  if (songs.isNotEmpty) {
    _songCache = songs;
    _songsLoadedAt = DateTime.now();
  }
  return songs;
}

Future<List<Map>> getRegionalHomePlaylists({int count = 8}) async {
  final items = await loadRegionalDiscovery(
    regionalPlaylistQueries,
    (query) => _cachedSearch('playlists', query, (term) async {
      final results = await ytClient.search.searchContent(
        term,
        filter: TypeFilters.playlist,
      );
      return results
          .whereType<SearchPlaylist>()
          .map(
            (playlist) => <String, dynamic>{
              'ytid': playlist.id.toString(),
              'title': playlist.title,
              'image': playlist.thumbnails.isEmpty
                  ? null
                  : playlist.thumbnails.first.url.toString(),
              'source': 'youtube',
              'list': <dynamic>[],
            },
          )
          .toList();
    }),
    perQuery: 4,
    limit: count,
  );
  // Home cards use real YouTube playlist IDs and the existing playlist route.
  final ids = onlinePlaylists.value.map((p) => p['ytid']).toSet();
  onlinePlaylists.value = [
    ...onlinePlaylists.value,
    ...items.where((p) => ids.add(p['ytid'])),
  ];
  return items;
}
