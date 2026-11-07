import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:musify/models/discovery_feedback.dart';

const discoveryFeedbackStorageKey = 'discoveryFeedbackV1';
final discoveryFeedback = ValueNotifier<DiscoveryFeedback>(
  DiscoveryFeedback.fromStorage(
    Hive.box('user').get(discoveryFeedbackStorageKey),
  ),
);
Future<void> saveDiscoveryFeedback(DiscoveryFeedback value) async {
  await Hive.box('user').put(discoveryFeedbackStorageKey, value.toStorage());
  discoveryFeedback.value = value;
}

void reloadDiscoveryFeedback() {
  discoveryFeedback.value = DiscoveryFeedback.fromStorage(
    Hive.box('user').get(discoveryFeedbackStorageKey),
  );
}
