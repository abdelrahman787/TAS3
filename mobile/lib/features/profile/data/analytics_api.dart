import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../quran/presentation/providers/quran_providers.dart';
import 'analytics_models.dart';

class AnalyticsApi {
  final ApiClient client;
  AnalyticsApi(this.client);

  Future<ProgressStats> getProgress({String? userId}) async {
    final res = await client.dio.get('/analytics/progress', queryParameters: {
      if (userId != null) 'userId': userId,
    });
    return ProgressStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SessionSummary>> listSessions({String? userId, int limit = 50}) async {
    final res = await client.dio.get('/analytics/sessions', queryParameters: {
      if (userId != null) 'userId': userId,
      'limit': limit,
    });
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(SessionSummary.fromJson)
        .toList();
  }

  Future<List<DifficultWord>> getDifficultWords({String? userId, int limit = 20}) async {
    final res = await client.dio.get('/analytics/difficult-words', queryParameters: {
      if (userId != null) 'userId': userId,
      'limit': limit,
    });
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(DifficultWord.fromJson)
        .toList();
  }
}

final analyticsApiProvider = Provider<AnalyticsApi>(
  (ref) => AnalyticsApi(ref.watch(apiClientProvider)),
);

final progressProvider = FutureProvider.autoDispose<ProgressStats>(
  (ref) => ref.watch(analyticsApiProvider).getProgress(),
);

final sessionsListProvider = FutureProvider.autoDispose<List<SessionSummary>>(
  (ref) => ref.watch(analyticsApiProvider).listSessions(limit: 20),
);

final difficultWordsProvider = FutureProvider.autoDispose<List<DifficultWord>>(
  (ref) => ref.watch(analyticsApiProvider).getDifficultWords(limit: 30),
);
