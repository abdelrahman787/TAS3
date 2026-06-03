class ProgressStats {
  final int sessionCount;
  final int totalWords;
  final int correctWords;
  final int forgottenWords;
  final int substitutions;
  final int orderErrors;
  final int pronunciationErrors;
  final double accuracy;

  ProgressStats({
    required this.sessionCount,
    required this.totalWords,
    required this.correctWords,
    required this.forgottenWords,
    required this.substitutions,
    required this.orderErrors,
    required this.pronunciationErrors,
    required this.accuracy,
  });

  factory ProgressStats.fromJson(Map<String, dynamic> j) => ProgressStats(
        sessionCount: (j['sessionCount'] as num).toInt(),
        totalWords: (j['totalWords'] as num).toInt(),
        correctWords: (j['correctWords'] as num).toInt(),
        forgottenWords: (j['forgottenWords'] as num).toInt(),
        substitutions: (j['substitutions'] as num).toInt(),
        orderErrors: (j['orderErrors'] as num).toInt(),
        pronunciationErrors: (j['pronunciationErrors'] as num).toInt(),
        accuracy: (j['accuracy'] as num).toDouble(),
      );
}

class SessionSummary {
  final String id;
  final DateTime createdAt;
  final DateTime? endedAt;
  final int pageStart;
  final int pageEnd;
  final String difficulty;
  final int? totalWords;
  final int? correctWords;
  final int? forgottenWords;
  final double? accuracy;

  SessionSummary({
    required this.id,
    required this.createdAt,
    required this.endedAt,
    required this.pageStart,
    required this.pageEnd,
    required this.difficulty,
    required this.totalWords,
    required this.correctWords,
    required this.forgottenWords,
    required this.accuracy,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> j) => SessionSummary(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        endedAt: j['endedAt'] == null ? null : DateTime.parse(j['endedAt'] as String),
        pageStart: (j['pageStart'] as num).toInt(),
        pageEnd: (j['pageEnd'] as num).toInt(),
        difficulty: j['difficulty'] as String,
        totalWords: (j['totalWords'] as num?)?.toInt(),
        correctWords: (j['correctWords'] as num?)?.toInt(),
        forgottenWords: (j['forgottenWords'] as num?)?.toInt(),
        accuracy: (j['accuracy'] as num?)?.toDouble(),
      );
}

class DifficultWord {
  final int wordId;
  final String expectedWord;
  final int errorCount;
  final int forgetCount;
  final int substitutionCount;
  final int orderErrorCount;
  final int pronunciationCount;

  DifficultWord({
    required this.wordId,
    required this.expectedWord,
    required this.errorCount,
    required this.forgetCount,
    required this.substitutionCount,
    required this.orderErrorCount,
    required this.pronunciationCount,
  });

  factory DifficultWord.fromJson(Map<String, dynamic> j) => DifficultWord(
        wordId: (j['wordId'] as num).toInt(),
        expectedWord: j['expectedWord'] as String,
        errorCount: (j['errorCount'] as num).toInt(),
        forgetCount: (j['forgetCount'] as num).toInt(),
        substitutionCount: (j['substitutionCount'] as num).toInt(),
        orderErrorCount: (j['orderErrorCount'] as num).toInt(),
        pronunciationCount: (j['pronunciationCount'] as num).toInt(),
      );
}
