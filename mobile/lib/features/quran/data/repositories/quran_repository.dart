import '../../../../core/network/api_client.dart';
import '../models/page_model.dart';
import '../models/surah_info.dart';

class QuranRepository {
  final ApiClient client;
  QuranRepository(this.client);

  Future<QuranPage> getPage(int pageNumber) async {
    final res = await client.dio.get('/quran/page/$pageNumber');
    return QuranPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SurahInfo> getSurahInfo(int surahNumber) async {
    final res = await client.dio.get('/quran/surah/$surahNumber');
    return SurahInfo.fromJson(res.data as Map<String, dynamic>);
  }
}
