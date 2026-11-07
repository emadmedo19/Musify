# Musify عربي — signed fork

This fork retains Musify's GPL license, source providers and music library features. Version **10.7.0+189** adds Arabic defaults, personalized Egyptian/Arab discovery, a refreshed interface, persistent discovery feedback and playback recovery fixes.

## Download and migrate

Download **Musify-Arabic.apk** from [this fork's latest stable release](https://github.com/emadmedo19/Musify/releases/latest). It supports Android 7.0+ and uses the distinct application ID `com.emadmedo19.musify` and label **Musify عربي**.

If using an earlier debug APK:

1. Export a backup from its Settings.
2. Install the signed Arabic app beside it; do not remove the old app yet.
3. Skip or complete artist onboarding, then import your backup in the new app's Settings.
4. Check your music, artist choices and playlists before removing the old app.

The earlier debug key cannot be recovered from an APK. This is a one-time move to a persistent release key. Future releases with the same package and key update in place without uninstalling.

## Personalization and interface

- Artist onboarding includes a broad 165-name Egyptian/Arab directory, filters, Arabic search normalization and adding missing names. It is editable, not an exhaustive list of every singer. Explicit skipping is remembered.
- Saved choices refresh artist shortcuts, songs, real provider album releases and playlists. Home favors regional discovery; general search remains open to any artist. The nineties shelf can be disabled.
- New installs default to Arabic and a dark pistachio theme. Existing saved language/theme settings remain respected. All 349 base UI messages have Arabic translations and placeholder coverage checks.
- Home includes source-backed artist photos with fallback icons, a cassette-inspired nineties spotlight, recent listening, pull-to-refresh and useful empty/retry states. Artist pages use a source image cover. Larger player layouts expose labeled lyrics/queue shortcuts.
- **Not interested**, **less of this artist**, targeted undo and reset affect discovery without deleting library music. Feedback is saved locally and applied to home/nineties, related recommendations and automatic next-song selection. Recent repeats rank below fresh discoveries.
- Successful provider searches are cached for six hours; requests are bounded, deduplicated and fail independently. Preference snapshots participate in cache identity so older requests cannot replace a newer choice. Offline mode starts no new discovery requests.

## Playback changes

Pausing while a source is still loading is respected on Android as well as desktop. Delayed error handling checks both the track transition and current playback intent. Active foreground playback/loading can continue when dismissing the app UI; a paused session is not restarted.

Native runtime stream errors can refresh an expired URL and attempt to preserve position, using a bounded retry budget and duplicate-event suppression. Pause/stop invalidate pending recovery. User-facing failures expose an explicit retry action. The existing audio session handles interruptions and headset events; its physical-device behavior still needs validation.

## Stable private signing

Keep the private keystore and password in an independent private backup. Never commit them or upload the signing ZIP to public Releases.

GitHub Actions expects:

- Repository secret **MUSIFY_KEYSTORE_BASE64**: full Base64 contents of the private PKCS12 keystore.
- Repository secret **MUSIFY_KEYSTORE_PASSWORD**: its password.
- Fixed alias: **musify-fork**.

Both the keystore and built APK must match the public fingerprint in `android/fork-signing-certificate.sha256`. The workflow deletes temporary signing files after the build. The signing kit prepared in the private workspace is for its owner only.

The available GitHub connector cannot administer secrets (HTTP 403); repository owners must add them in Settings → Secrets and variables → Actions. Until configured, CI emits **Musify-UNSIGNED.apk** in an explicitly named unsigned artifact. This is not an installable release; it must be signed privately with the same backed-up key. The current release can be signed in the workspace without exposing that key to the repository.

## Build and publish

Use the exact Flutter version in `pubspec.yaml`, Java 21, Android SDK 36 and the project's configured NDK. CI resolves these requirements and enforces the dependency lockfile.

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze --no-pub
flutter build apk --release --flavor github --no-pub
```

For local signing, create ignored `android/key.properties` with `storeFile`, `keyAlias`, `storePassword` and `keyPassword` referring to the private keystore. Without signing properties, the release build is unsigned. Do not distribute it as installable until signature verification passes.

**Build fork APK** runs checks and builds a release. **Run workflow → publish_release** optionally publishes a stable GitHub Release only after private signing and certificate verification succeed. Publication is disabled by default. Pull requests cannot access signing secrets and produce unsigned build artifacts only.

The app updater checks only `emadmedo19/Musify` stable GitHub Releases for the universal **Musify-Arabic.apk** asset. Upstream, missing, draft, prerelease and unrelated-host assets are rejected. Network requests have a timeout, malformed versions cannot crash the app, and manual checks report a useful result.

## Verification and practical limits

CI covers static analysis, translation completeness/placeholders, Arabic RTL widgets, artist/feedback persistence through a real Hive close/reopen, update URL/version validation, recovery policy/state transitions, and compact discovery/artist/player presentation widgets. The private-signing preparation is exercised with the actual workflow script and expected certificate.

A physical Android pass is still needed for background playback under the device's battery policy, headset removal, phone interruptions and real provider behavior. These are not claimed to be verified by Dart policy tests or a web UI preview. The workspace has no connected Android/KVM, and the attempted YouTube connection was rejected by its outbound proxy. Content availability depends on the external providers; nineties labels express discovery intent and do not guarantee the original release year of each returned upload.

Favorites, preferences and feedback are stored on-device. Music/artwork/lyrics requests go to the configured external providers; artist onboarding itself needs no network. Existing backup/export and optional local-network sync features remain available.
