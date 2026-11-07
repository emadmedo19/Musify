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

## Egyptian and Arabic home discovery (10.6.1)

Home suggestions now use live regional searches instead of randomly selecting the built-in global/Western playlist catalog. Playlist categories cover Egyptian music, Arabic music, Egyptian classics and Egyptian shaabi. Cards retain real provider playlist IDs, titles and artwork and open with the existing playlist screen.

Song discovery searches four artists per refresh: Amr Diab, two rotating Egyptian artists, and one rotating artist from the wider Arab region. The pools include Tamer Hosny, Sherine, Mohamed Hamaki, Angham, Ahmed Saad, Mohamed Mounir, Umm Kulthum, Abdel Halim Hafez, Fairuz, Elissa, Nancy Ajram and others. Results are interleaved and deduplicated so one artist does not fill the shelf. These are discovery queries, not verified popularity charts or a guarantee that every returned track is Arabic.

When enough regional results are available, at least 10 of 15 home song slots are regional discovery, with up to 5 personal recommendations. Existing favorites/history/custom playlists remain available; global search is unchanged. If regional providers fail, personal recommendations can fill the shelf. The old Top 50 Global seed is no longer used for home recommendations.

Successful discovery searches are cached for six hours; requests are bounded and fail independently. Offline mode uses available cached results without starting new provider searches. A new install without connectivity or cache can have no discovery results; it does not silently substitute the global catalog.

## Choose your artists (10.6.2)

On first opening this version, a local artist picker appears before discovery requests start. It includes a broad, searchable Egyptian/Arab directory with filters for Egyptian, Arab, nineties-era, and selected names. It is not an exhaustive list of all singers: users can add any missing artist name. Selections and the optional nineties shelf are saved in the user database and restored on subsequent launches. Skipping is explicit and remembered; editing is available from **اختار نجومك** on Home.

After saving, Home immediately refreshes artist shortcuts, songs, playlists, and albums using the selected names. Songs/playlists rotate through a bounded subset of favorites; every selected artist remains accessible through a Home shortcut. Album cards come from the existing YouTube Music artist release metadata, not invented album IDs or search thumbnails. The nineties shelf favors selected artists with known nineties catalogs and also includes period discovery queries. The period labels describe search intent; provider results can include later uploads or compilations.

Preferences participate in the song-cache identity, and requests capture their preference snapshot so a previous selection cannot replace a newer selection's in-memory cache. Successful source results are cached; the picker itself works without network access. Individual online sources can fail independently, and an unavailable artist/album does not prevent saving preferences or browsing other shelves.

Verification includes widget tests for selection/search/custom additions, save errors, changing or clearing choices, small screens, landscape and keyboard layouts, plus a real Hive close/reopen persistence test. Live provider content remains dependent on the external service and has not been verified from this workspace's restricted YouTube connection.
