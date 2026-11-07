import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:musify/models/music_taste.dart';
import 'package:musify/services/music_taste_service.dart';

void main() {
  test(
    'saved onboarding survives closing and reopening the user database',
    () async {
      final temp = await Directory.systemTemp.createTemp('musify-taste-');
      try {
        Hive.init(temp.path);
        await Hive.openBox<dynamic>('user');
        expect(musicTaste.value.completed, isFalse);
        await saveMusicTaste(
          MusicTaste(artists: ['عمرو دياب', 'فيروز'], completed: true),
        );
        await Hive.close();
        await Hive.openBox<dynamic>('user');
        reloadMusicTaste();
        expect(musicTaste.value.artists, ['عمرو دياب', 'فيروز']);
        expect(musicTaste.value.completed, isTrue);
        expect(musicTaste.value.includeNineties, isTrue);
      } finally {
        await Hive.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
