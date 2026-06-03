import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/asr/asr_manager.dart';
import '../../../../core/matching/matching_engine.dart';
import '../../../../core/network/api_client.dart';
import '../../../quran/domain/entities/quran_word.dart';
import '../../data/recitation_api.dart';
import '../../domain/recitation_state.dart';
import '../../domain/word_attempt_tracker.dart';

class RecitationParams {
  final int pageNumber;
  final List<QuranWord> words;
  final DifficultyMode difficulty;
  RecitationParams({
    required this.pageNumber,
    required this.words,
    this.difficulty = DifficultyMode.normal,
  });
}

class RecitationNotifier extends StateNotifier<RecitationState> {
  final RecitationParams params;
  final ASRManager asr;
  final RecitationApi api;

  final WordAttemptTracker _tracker = WordAttemptTracker();
  final List<PendingError> _pendingErrors = [];

  int _forgotten = 0;
  int _substitutions = 0;
  int _orderErrors = 0;
  int _pronunciationErrors = 0;

  Timer? _silenceTimer;
  bool _disposed = false;

  static const Duration _chunkDuration = Duration(seconds: 4);

  RecitationNotifier({
    required this.params,
    required this.asr,
    required this.api,
  }) : super(RecitationState(
          revealedWords: List<bool>.filled(params.words.length, false),
          totalWords: params.words.length,
        ));

  // ── Lifecycle ──────────────────────────────────────────────────
  Future<void> start({String? userId}) async {
    if (!await asr.hasPermission()) return;

    final sessionId = await api.createSession(
      userId: userId,
      pageStart: params.pageNumber,
      pageEnd: params.pageNumber,
      difficulty: params.difficulty,
    );

    state = state.copyWith(
      status: RecitationStatus.listening,
      currentWordIndex: 0,
      revealedWords: List<bool>.filled(params.words.length, false),
      silenceSeconds: 0,
      sessionId: sessionId,
    );

    _startSilenceTimer();
    await _beginListeningCycle();
  }

  Future<void> pause() async {
    // Mid-transcribe: just flip status. The while-loop in
    // _beginListeningCycle will see !isActive on its next iteration and exit
    // cleanly instead of racing with stop().
    if (state.status == RecitationStatus.processing) {
      state = state.copyWith(status: RecitationStatus.paused);
      return;
    }
    if (state.status != RecitationStatus.listening) return;
    _silenceTimer?.cancel();
    await asr.stop();
    state = state.copyWith(status: RecitationStatus.paused);
  }

  Future<void> resume() async {
    if (state.status != RecitationStatus.paused) return;
    state = state.copyWith(status: RecitationStatus.listening, silenceSeconds: 0);
    _startSilenceTimer();
    await _beginListeningCycle();
  }

  Future<void> end() async {
    _silenceTimer?.cancel();
    await asr.stop();

    final sessionId = state.sessionId;
    if (sessionId != null) {
      // Flush any pending errors.
      await _flushErrors();

      final stats = _computeStats();
      await api.complete(sessionId, stats);

      state = state.copyWith(
        status: RecitationStatus.complete,
        correctWords: stats.correctWords,
        forgottenWords: stats.forgottenWords,
        substitutions: stats.substitutions,
        orderErrors: stats.orderErrors,
        pronunciationErrors: stats.pronunciationErrors,
      );
    } else {
      state = state.copyWith(status: RecitationStatus.complete);
    }
  }

  // ── Silence handling ───────────────────────────────────────────
  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || state.status != RecitationStatus.listening) return;
      final next = state.silenceSeconds + 1;
      state = state.copyWith(silenceSeconds: next);
      if (next == 10) {
        _onSilenceTimeout();
      }
    });
  }

  void _resetSilenceTimer() {
    state = state.copyWith(silenceSeconds: 0);
  }

  void _onSilenceTimeout() {
    final idx = state.currentWordIndex;
    if (idx >= params.words.length) return;
    final word = params.words[idx];
    _tracker.recordAttempt(word.id);
    if (_tracker.shouldLogError(word.id)) {
      _pendingErrors.add(PendingError(
        wordId: word.id,
        expectedWord: word.uthmaniText,
        errorType: ErrorType.forget,
        attemptCount: _tracker.getAttempts(word.id),
      ));
      _forgotten++;
    }
    // Stay on the same word, surface manual reveal buttons (UI reads silenceSeconds).
  }

  // ── Recording / ASR cycle ──────────────────────────────────────
  Future<void> _beginListeningCycle() async {
    while (!_disposed && state.isActive) {
      await _transcribeAndProcess();
    }
  }

  Future<void> _transcribeAndProcess() async {
    if (_disposed || state.status != RecitationStatus.listening) return;
    final path = await asr.start();
    await Future<void>.delayed(_chunkDuration);
    if (_disposed) return;

    // If pause() flipped us mid-record, stop and let the loop exit.
    if (state.status == RecitationStatus.paused) {
      await asr.stop();
      return;
    }

    final filePath = await asr.stop() ?? path;
    state = state.copyWith(status: RecitationStatus.processing);
    final result = await asr.transcribe(filePath);
    if (_disposed) return;

    if (asr.shouldWarnAudioUnclear) {
      state = state.copyWith(audioUnclearWarning: true);
    }
    if (result != null && result.text.isNotEmpty) {
      _handleASRResult(result.text, result.confidence, result.tokens);
    }

    // Pause arriving during transcription: don't flip back to listening.
    if (state.status == RecitationStatus.paused) return;

    state = state.copyWith(
      status: RecitationStatus.listening,
      audioUnclearWarning: false,
    );
  }

  void _handleASRResult(String text, double confidence, List<String> apiTokens) {
    final tokens = apiTokens.isNotEmpty
        ? apiTokens
        : MatchingEngine.tokenize(text);
    if (tokens.isEmpty) return;

    final startIndex = state.currentWordIndex;
    final expected = params.words.sublist(startIndex);

    final result = MatchingEngine.matchSequence(
      asrTokens: tokens,
      expectedSequence: expected,
      confidence: confidence,
      mode: params.difficulty,
    );

    // Reveal matched words.
    if (result.matchedCount > 0) {
      final revealed = List<bool>.from(state.revealedWords);
      for (int i = 0; i < result.matchedCount; i++) {
        revealed[startIndex + i] = true;
      }
      final newIndex = startIndex + result.matchedCount;
      state = state.copyWith(
        revealedWords: revealed,
        currentWordIndex: newIndex,
        correctWords: state.correctWords + result.matchedCount,
      );
      _resetSilenceTimer();
    }

    // Log first error if applicable.
    final err = result.firstError;
    if (err != null && err.errorType != null) {
      final wordIdx = startIndex + result.matchedCount;
      if (wordIdx < params.words.length && err.errorType != ErrorType.asrFailure) {
        final word = params.words[wordIdx];
        _tracker.recordAttempt(word.id);
        if (_tracker.shouldLogError(word.id)) {
          _pendingErrors.add(PendingError(
            wordId: word.id,
            expectedWord: word.uthmaniText,
            recognizedText: tokens.length > result.matchedCount
                ? tokens[result.matchedCount]
                : null,
            errorType: err.errorType!,
            attemptCount: _tracker.getAttempts(word.id),
            confidence: confidence,
          ));
          switch (err.errorType!) {
            case ErrorType.substitution:
              _substitutions++;
              break;
            case ErrorType.orderError:
              _orderErrors++;
              break;
            case ErrorType.pronunciation:
              _pronunciationErrors++;
              break;
            case ErrorType.forget:
              _forgotten++;
              break;
            case ErrorType.asrFailure:
              break;
          }
        }
      }
    }
  }

  // ── Manual reveal ──────────────────────────────────────────────
  void revealNextWord() {
    final idx = state.currentWordIndex;
    if (idx >= params.words.length) return;
    final revealed = List<bool>.from(state.revealedWords);
    revealed[idx] = true;
    final word = params.words[idx];
    _pendingErrors.add(PendingError(
      wordId: word.id,
      expectedWord: word.uthmaniText,
      errorType: ErrorType.forget,
      attemptCount: _tracker.getAttempts(word.id) + 1,
    ));
    _forgotten++;
    state = state.copyWith(
      revealedWords: revealed,
      currentWordIndex: idx + 1,
      silenceSeconds: 0,
    );
  }

  void revealFullAyah() {
    final idx = state.currentWordIndex;
    if (idx >= params.words.length) return;
    final currentAyah = params.words[idx].ayah;
    final currentSurah = params.words[idx].surah;
    final revealed = List<bool>.from(state.revealedWords);
    int newIdx = idx;
    for (int i = idx; i < params.words.length; i++) {
      final w = params.words[i];
      if (w.surah != currentSurah || w.ayah != currentAyah) break;
      if (!revealed[i]) {
        revealed[i] = true;
        _pendingErrors.add(PendingError(
          wordId: w.id,
          expectedWord: w.uthmaniText,
          errorType: ErrorType.forget,
          attemptCount: _tracker.getAttempts(w.id) + 1,
        ));
        _forgotten++;
      }
      newIdx = i + 1;
    }
    state = state.copyWith(
      revealedWords: revealed,
      currentWordIndex: newIdx,
      silenceSeconds: 0,
    );
  }

  // ── Flush + stats ──────────────────────────────────────────────
  Future<void> _flushErrors() async {
    final sessionId = state.sessionId;
    if (sessionId == null || _pendingErrors.isEmpty) return;
    final toSend = List<PendingError>.from(_pendingErrors);
    _pendingErrors.clear();
    await api.logErrors(sessionId, toSend);
  }

  SessionStats _computeStats() {
    return SessionStats(
      totalWords: params.words.length,
      correctWords: state.correctWords,
      forgottenWords: _forgotten,
      substitutions: _substitutions,
      orderErrors: _orderErrors,
      pronunciationErrors: _pronunciationErrors,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _silenceTimer?.cancel();
    asr.stop();
    asr.dispose();
    super.dispose();
  }
}

// ── Providers ────────────────────────────────────────────────────
final asrManagerProvider = Provider<ASRManager>((ref) {
  // Reuse the global ApiClient's Dio so the Bearer token interceptor
  // attaches to /asr/transcribe automatically.
  final mgr = ASRManager(dio: ref.watch(apiClientProvider).dio);
  ref.onDispose(mgr.dispose);
  return mgr;
});

final recitationApiProvider = Provider<RecitationApi>(
  (ref) => RecitationApi(ref.watch(apiClientProvider)),
);

final recitationProvider = StateNotifierProvider.autoDispose
    .family<RecitationNotifier, RecitationState, RecitationParams>(
  (ref, params) => RecitationNotifier(
    params: params,
    asr: ref.watch(asrManagerProvider),
    api: ref.watch(recitationApiProvider),
  ),
);
