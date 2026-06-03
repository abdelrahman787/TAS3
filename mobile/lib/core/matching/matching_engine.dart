import 'dart:math';

import '../../features/quran/domain/entities/quran_word.dart';

enum DifficultyMode { easy, normal, strict }

enum ErrorType { forget, substitution, orderError, pronunciation, asrFailure }

class MatchResult {
  final bool isMatch;
  final double distance; // Levenshtein ratio 0.0–1.0
  final ErrorType? errorType;
  const MatchResult({
    required this.isMatch,
    required this.distance,
    this.errorType,
  });
}

class MultiMatchResult {
  final int matchedCount;
  final MatchResult? firstError;
  const MultiMatchResult({required this.matchedCount, this.firstError});
}

class MatchingEngine {
  // ── Normalization ─────────────────────────────────────────────
  static String normalize(String text, DifficultyMode mode) {
    // 1. Remove tashkeel (diacritics) + dagger alif U+0670
    text = text.replaceAll(RegExp(r'[ؐ-ًؚ-ٰٟ]'), '');
    // 2. Normalize Alif variants (incl. wasla ٱ U+0671)
    text = text.replaceAll(RegExp(r'[آأإٱ]'), 'ا');
    // 3. Normalize Ya Maqsura
    text = text.replaceAll('ى', 'ي');
    // 4. Remove tatweel
    text = text.replaceAll('ـ', '');
    // 5. Easy mode: normalize Ta Marbuta → Ha
    if (mode == DifficultyMode.easy) {
      text = text.replaceAll('ة', 'ه');
    }
    return text.trim();
  }

  // ── Levenshtein distance ───────────────────────────────────────
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final dp = List<List<int>>.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );
    for (int i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }
    return dp[a.length][b.length];
  }

  static double levenshteinRatio(String a, String b) {
    final dist = levenshtein(a, b);
    final maxLen = max(a.length, b.length);
    return maxLen == 0 ? 0.0 : dist / maxLen;
  }

  // ── Thresholds ─────────────────────────────────────────────────
  static double getThreshold(DifficultyMode mode) {
    switch (mode) {
      case DifficultyMode.easy:
        return 0.30;
      case DifficultyMode.normal:
        return 0.20;
      case DifficultyMode.strict:
        return 0.10;
    }
  }

  static double getConfidenceThreshold(DifficultyMode mode) {
    switch (mode) {
      case DifficultyMode.easy:
        return 0.60;
      case DifficultyMode.normal:
        return 0.75;
      case DifficultyMode.strict:
        return 0.85;
    }
  }

  // ── Core single-word match ─────────────────────────────────────
  static MatchResult match({
    required String asrToken,
    required String expectedWord,
    required double confidence,
    required DifficultyMode mode,
  }) {
    if (asrToken.trim().isEmpty) {
      return const MatchResult(
        isMatch: false,
        distance: 1.0,
        errorType: ErrorType.asrFailure,
      );
    }

    final normASR = normalize(asrToken, mode);
    final normExpected = normalize(expectedWord, mode);
    final ratio = levenshteinRatio(normASR, normExpected);
    final threshold = getThreshold(mode);
    final confThreshold = getConfidenceThreshold(mode);

    if (ratio <= threshold) {
      if (confidence < confThreshold) {
        return MatchResult(
          isMatch: false,
          distance: ratio,
          errorType: ErrorType.pronunciation,
        );
      }
      return MatchResult(isMatch: true, distance: ratio);
    }

    return MatchResult(
      isMatch: false,
      distance: ratio,
      errorType: ErrorType.substitution,
    );
  }

  // ── Multi-word sequence match ──────────────────────────────────
  ///
  /// On the first mismatch, looks ahead up to [orderLookahead] words to see if
  /// the user's token matches a *later* expected word. If so, classifies the
  /// error as [ErrorType.orderError] instead of [ErrorType.substitution].
  static MultiMatchResult matchSequence({
    required List<String> asrTokens,
    required List<QuranWord> expectedSequence,
    required double confidence,
    required DifficultyMode mode,
    int orderLookahead = 5,
  }) {
    int matched = 0;
    MatchResult? firstError;

    final limit = min(asrTokens.length, expectedSequence.length);
    for (int i = 0; i < limit; i++) {
      final r = match(
        asrToken: asrTokens[i],
        expectedWord: expectedSequence[i].uthmaniText,
        confidence: confidence,
        mode: mode,
      );
      if (r.isMatch) {
        matched++;
      } else {
        // Look ahead: would the token have matched a near-future expected word?
        if (r.errorType == ErrorType.substitution) {
          final end = min(i + 1 + orderLookahead, expectedSequence.length);
          for (int j = i + 1; j < end; j++) {
            final ahead = match(
              asrToken: asrTokens[i],
              expectedWord: expectedSequence[j].uthmaniText,
              confidence: confidence,
              mode: mode,
            );
            if (ahead.isMatch) {
              firstError = MatchResult(
                isMatch: false,
                distance: r.distance,
                errorType: ErrorType.orderError,
              );
              break;
            }
          }
          firstError ??= r;
        } else {
          firstError = r;
        }
        break;
      }
    }

    return MultiMatchResult(matchedCount: matched, firstError: firstError);
  }

  // ── Tokenize ASR output into Arabic words ──────────────────────
  static List<String> tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[،؛؟\.!,;?]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
