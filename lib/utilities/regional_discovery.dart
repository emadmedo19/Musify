import 'dart:math';

import 'package:musify/utilities/map_utils.dart';

const egyptianArtistQueries = <String>[
  'عمرو دياب official audio',
  'تامر حسني official audio',
  'شيرين عبد الوهاب official audio',
  'محمد حماقي official audio',
  'أنغام official audio',
  'أحمد سعد official audio',
  'محمد منير official audio',
  'أم كلثوم أغاني',
  'عبد الحليم حافظ أغاني',
];
const arabicArtistQueries = <String>[
  'فيروز أغاني',
  'إليسا official audio',
  'نانسي عجرم official audio',
  'فضل شاكر official audio',
  'حسين الجسمي official audio',
  'ماجد المهندس official audio',
];
const regionalPlaylistQueries = <String>[
  'أغاني مصرية',
  'أغاني عربية',
  'طرب مصري',
  'أغاني شعبي مصري',
];

/// Keep requests bounded and favor Egypt without excluding other Arab artists.
List<String> regionalSongQueries({Random? random}) {
  final sampler = random ?? Random();
  final egyptian = egyptianArtistQueries.skip(1).toList()..shuffle(sampler);
  final arabic = arabicArtistQueries.toList()..shuffle(sampler);
  return [egyptianArtistQueries.first, ...egyptian.take(2), arabic.first];
}

/// Round-robin prevents the first artist or category filling the whole shelf.
List<Map> interleaveDiscoveryResults(List<List<Map>> sources, int count) {
  if (count <= 0) return [];
  final result = <Map>[];
  final seen = <String>{};
  final longest = sources.fold<int>(0, (n, s) => max(n, s.length));
  for (var index = 0; index < longest; index++) {
    for (final source in sources) {
      if (index >= source.length) continue;
      final item = source[index];
      final id = songYtid(item)?.trim();
      if (id == null || id.isEmpty || !seen.add(id)) continue;
      result.add(item);
      if (result.length == count) return result;
    }
  }
  return result;
}

/// Regional discovery gets at least two thirds of a full home shelf when
/// available. Personal music remains eligible, regardless of title language.
List<Map> blendRegionalRecommendations(
  List<Map> regional,
  List<Map> personal, {
  int count = 15,
}) {
  if (count <= 0) return [];
  final regionalQuota = (count * 2 / 3).ceil();
  return interleaveDiscoveryResults([
    [
      ...regional.take(regionalQuota),
      ...personal,
      ...regional.skip(regionalQuota),
    ],
  ], count);
}

typedef DiscoverySearch = Future<List<Map>> Function(String query);

/// One failed provider query must not hide results from the other categories.
Future<List<Map>> loadRegionalDiscovery(
  List<String> queries,
  DiscoverySearch search, {
  required int perQuery,
  required int limit,
}) async {
  if (limit <= 0 || perQuery <= 0) return [];
  final results = await Future.wait(
    queries.map((query) async {
      try {
        return (await search(query).timeout(const Duration(seconds: 15)))
            .take(perQuery)
            .toList();
      } catch (_) {
        return <Map>[];
      }
    }),
  );
  return interleaveDiscoveryResults(results, limit);
}
