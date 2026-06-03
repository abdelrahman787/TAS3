import '../../../core/matching/matching_engine.dart';
import '../../../core/network/api_client.dart';

class PendingError {
  final int wordId;
  final String expectedWord;
  final String? recognizedText;
  final ErrorType errorType;
  final int attemptCount;
  final double? confidence;

  PendingError({
    required this.wordId,
    required this.expectedWord,
    required this.errorType,
    required this.attemptCount,
    this.recognizedText,
    this.confidence,
  });

  String get errorTypeWire {
    switch (errorType) {
      case ErrorType.forget:
        return 'forget';
      case ErrorType.substitution:
        return 'substitution';
      case ErrorType.orderError:
        return 'order_error';
      case ErrorType.pronunciation:
        return 'pronunciation';
      case ErrorType.asrFailure:
        return 'asr_failure';
    }
  }

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'expectedWord': expectedWord,
        'recognizedText': recognizedText,
        'errorType': errorTypeWire,
        'attemptCount': attemptCount,
        'confidence': confidence,
      };
}

class SessionStats {
  final int totalWords;
  final int correctWords;
  final int forgottenWords;
  final int substitutions;
  final int orderErrors;
  final int pronunciationErrors;

  SessionStats({
    required this.totalWords,
    required this.correctWords,
    required this.forgottenWords,
    required this.substitutions,
    required this.orderErrors,
    required this.pronunciationErrors,
  });

  Map<String, dynamic> toJson() => {
        'totalWords': totalWords,
        'correctWords': correctWords,
        'forgottenWords': forgottenWords,
        'substitutions': substitutions,
        'orderErrors': orderErrors,
        'pronunciationErrors': pronunciationErrors,
      };
}

class RecitationApi {
  final ApiClient client;
  RecitationApi(this.client);

  Future<String> createSession({
    String? userId,
    required int pageStart,
    required int pageEnd,
    required DifficultyMode difficulty,
  }) async {
    final res = await client.dio.post('/sessions', data: {
      if (userId != null) 'userId': userId,
      'scope': {'type': 'page', 'pageStart': pageStart, 'pageEnd': pageEnd},
      'difficulty': difficulty.name,
    });
    return res.data['sessionId'] as String;
  }

  Future<void> logErrors(String sessionId, List<PendingError> errors) async {
    if (errors.isEmpty) return;
    await client.dio.post(
      '/sessions/$sessionId/errors',
      data: {'errors': errors.map((e) => e.toJson()).toList()},
    );
  }

  Future<void> complete(String sessionId, SessionStats stats) async {
    await client.dio.patch('/sessions/$sessionId/complete', data: {
      'endTime': DateTime.now().toUtc().toIso8601String(),
      'stats': stats.toJson(),
    });
  }
}
