import 'package:flutter/foundation.dart';

enum RecitationStatus { idle, listening, processing, paused, complete }

@immutable
class RecitationState {
  final RecitationStatus status;
  final int currentWordIndex;
  final List<bool> revealedWords;
  final int silenceSeconds;
  final bool audioUnclearWarning;

  /// Only set when [status] == complete.
  final String? sessionId;
  final int totalWords;
  final int correctWords;

  const RecitationState({
    this.status = RecitationStatus.idle,
    this.currentWordIndex = 0,
    this.revealedWords = const [],
    this.silenceSeconds = 0,
    this.audioUnclearWarning = false,
    this.sessionId,
    this.totalWords = 0,
    this.correctWords = 0,
  });

  bool get isListening => status == RecitationStatus.listening;
  bool get isActive =>
      status == RecitationStatus.listening || status == RecitationStatus.processing;

  RecitationState copyWith({
    RecitationStatus? status,
    int? currentWordIndex,
    List<bool>? revealedWords,
    int? silenceSeconds,
    bool? audioUnclearWarning,
    String? sessionId,
    int? totalWords,
    int? correctWords,
  }) =>
      RecitationState(
        status: status ?? this.status,
        currentWordIndex: currentWordIndex ?? this.currentWordIndex,
        revealedWords: revealedWords ?? this.revealedWords,
        silenceSeconds: silenceSeconds ?? this.silenceSeconds,
        audioUnclearWarning: audioUnclearWarning ?? this.audioUnclearWarning,
        sessionId: sessionId ?? this.sessionId,
        totalWords: totalWords ?? this.totalWords,
        correctWords: correctWords ?? this.correctWords,
      );
}
