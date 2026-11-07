import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/playback_recovery.dart';

void main() {
  test('duplicate native error events do not start duplicate recoveries', () {
    final gate = PlaybackRecoveryGate();
    final token = gate.begin('track-a')!;
    expect(gate.begin('track-a'), isNull);
    expect(gate.isCurrent(token), isTrue);
  });
  test('same track retries are bounded even when fresh URLs fail', () {
    final gate = PlaybackRecoveryGate();
    gate.finish(gate.begin('a')!);
    gate.finish(gate.begin('a')!);
    expect(gate.begin('a'), isNull);
    expect(gate.begin('b'), isNotNull);
  });
  test(
    'pause or stop invalidates delayed recovery before it can resume audio',
    () {
      final gate = PlaybackRecoveryGate();
      final token = gate.begin('a')!;
      gate.cancel();
      expect(gate.isCurrent(token), isFalse);
      expect(
        shouldStartLoadedPlayback(
          playWhenReady: true,
          hasTransition: true,
          currentPlaybackIntent: false,
        ),
        isFalse,
      );
    },
  );
  test('an older completion cannot cancel the new track recovery', () {
    final gate = PlaybackRecoveryGate();
    final old = gate.begin('a')!;
    final current = gate.begin('b')!;
    gate.finish(old);
    expect(gate.isCurrent(current), isTrue);
    expect(gate.isCurrent(old), isFalse);
  });
  test('explicit user retry opens a fresh bounded attempt budget', () {
    final gate = PlaybackRecoveryGate(maxAttempts: 1);
    gate.finish(gate.begin('a')!);
    expect(gate.begin('a'), isNull);
    gate.reset();
    expect(gate.begin('a'), isNotNull);
  });
  test(
    'dismissing the app keeps active audio but never restarts a paused session',
    () {
      expect(
        keepAudioOnTaskRemoval(
          playbackIntended: true,
          playing: true,
          loading: false,
        ),
        isTrue,
      );
      expect(
        keepAudioOnTaskRemoval(
          playbackIntended: true,
          playing: false,
          loading: true,
        ),
        isTrue,
      );
      expect(
        keepAudioOnTaskRemoval(
          playbackIntended: false,
          playing: false,
          loading: false,
        ),
        isFalse,
      );
      expect(
        keepAudioOnTaskRemoval(
          playbackIntended: false,
          playing: false,
          loading: true,
        ),
        isFalse,
      );
    },
  );
}
