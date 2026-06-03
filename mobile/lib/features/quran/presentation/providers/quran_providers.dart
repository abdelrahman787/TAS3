import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/page_model.dart';
import '../../data/repositories/quran_repository.dart';

final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => QuranRepository(ref.watch(apiClientProvider)),
);

final quranPageProvider = FutureProvider.family<QuranPage, int>(
  (ref, page) => ref.watch(quranRepositoryProvider).getPage(page),
);
