import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:musify/models/music_taste.dart';

const musicTasteStorageKey = 'regionalMusicTasteV1';
final musicTaste = ValueNotifier<MusicTaste>(
  MusicTaste.fromStorage(Hive.box('user').get(musicTasteStorageKey)),
);

Future<void> saveMusicTaste(MusicTaste taste) async {
  // Publish only after persistence succeeds; failed saves keep the picker open.
  await Hive.box('user').put(musicTasteStorageKey, taste.toStorage());
  musicTaste.value = taste;
}

void reloadMusicTaste() {
  musicTaste.value = MusicTaste.fromStorage(
    Hive.box('user').get(musicTasteStorageKey),
  );
}
