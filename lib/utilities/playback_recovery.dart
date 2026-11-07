/// Bounds duplicate native error events and invalidates pending work on pause,
/// stop or a user track change. It owns no audio engine or network connection.
class PlaybackRecoveryGate {
  PlaybackRecoveryGate({this.maxAttempts = 2});
  final int maxAttempts;
  String? _track;
  int _attempts = 0;
  int _revision = 0;
  bool _busy = false;
  int? begin(String track) {
    if (_track != track) {
      _track = track;
      _attempts = 0;
      _busy = false;
      _revision++;
    }
    if (_busy || _attempts >= maxAttempts) return null;
    _busy = true;
    _attempts++;
    return ++_revision;
  }

  bool isCurrent(int token) => _busy && token == _revision;
  void finish(int token) {
    if (isCurrent(token)) _busy = false;
  }

  void cancel() {
    _revision++;
    _busy = false;
  }

  void reset() {
    cancel();
    _track = null;
    _attempts = 0;
  }
}

bool shouldStartLoadedPlayback({
  required bool playWhenReady,
  required bool hasTransition,
  required bool currentPlaybackIntent,
}) => hasTransition ? currentPlaybackIntent : playWhenReady;

bool keepAudioOnTaskRemoval({
  required bool playbackIntended,
  required bool playing,
  required bool loading,
}) => playbackIntended && (playing || loading);
