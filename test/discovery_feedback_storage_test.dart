import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:musify/models/discovery_feedback.dart';
import 'package:musify/services/discovery_feedback_service.dart';

void main() {
  test('discovery feedback survives reopening and can be reset without deleting songs', () async {
    final temp = await Directory.systemTemp.createTemp('musify-feedback-');
    try {
      Hive.init(temp.path);
      await Hive.openBox<dynamic>('user');
      await Hive.box('user').put('likedSongs', [
        {'ytid': 'a'},
      ]);
      await saveDiscoveryFeedback(
        DiscoveryFeedback().hide('a').reduce('name:artist'),
      );
      await Hive.close();
      await Hive.openBox<dynamic>('user');
      reloadDiscoveryFeedback();
      expect(discoveryFeedback.value.hiddenSongs, {'a'});
      expect(discoveryFeedback.value.reducedArtists, {'name:artist'});
      await saveDiscoveryFeedback(DiscoveryFeedback());
      expect(discoveryFeedback.value.hiddenSongs, isEmpty);
      expect(Hive.box('user').get('likedSongs'), [
        {'ytid': 'a'},
      ]);
    } finally {
      await Hive.close();
      await temp.delete(recursive: true);
    }
  });
}
