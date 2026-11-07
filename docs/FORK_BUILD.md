# Building this Musify fork

This fork retains Musify's existing music sources, playback, search, and GPL-3.0 license. This change adds an APK build for `emadmedo19/Musify`; it does not replace the catalog or guarantee availability of any particular song.

## Download

1. Open **Actions → Build fork APK** in this repository.
2. Open a successful run and download **Musify-fork-debug-APK** from **Artifacts** (GitHub login required).
3. Extract the ZIP and install `app-github-debug.apk` on Android 7.0 or newer.

This is a debug build signed by the build runner, not a Google Play release. Its application ID is `com.gokadzev.musify.debug`. No original developer signing secrets are required. Separate workflow runs can use different debug signing keys: if Android reports an incompatible signature when updating, export your data before uninstalling the older build.

## Local build

Use the Flutter version in `pubspec.yaml`, Java 21, and Android SDK 36. Flutter/Gradle will resolve the project's Android build tools and NDK dependencies.

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub test/map_utils_test.dart test/sort_utils_test.dart test/media_duration_test.dart
flutter build apk --debug --flavor github --no-pub
```

Output: `build/app/outputs/flutter-apk/app-github-debug.apk`.

The upstream release workflows remain separate and require upstream signing configuration. Use **Build fork APK** for this fork. Runtime search/playback depends on external providers and must also be verified on an Android device.
