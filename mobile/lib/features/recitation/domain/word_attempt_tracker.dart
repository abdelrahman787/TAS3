/// Tracks attempt counts per word and decides when to log a confirmed error.
///
/// Spec:
/// - Attempt 1: no error logged
/// - Attempt 2: soft error (logged with `isSoft=true`)
/// - Attempt 3+: confirmed error
class WordAttemptTracker {
  final Map<int, int> _attempts = {};

  void recordAttempt(int wordId) {
    _attempts[wordId] = (_attempts[wordId] ?? 0) + 1;
  }

  int getAttempts(int wordId) => _attempts[wordId] ?? 0;

  /// True from attempt 2 onward.
  bool shouldLogError(int wordId) => getAttempts(wordId) >= 2;

  bool isSoftError(int wordId) => getAttempts(wordId) == 2;

  void reset() => _attempts.clear();
}
