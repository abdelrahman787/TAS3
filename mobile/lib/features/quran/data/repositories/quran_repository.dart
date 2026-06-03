import '../../../../core/network/api_client.dart';
import '../models/page_model.dart';

class QuranRepository {
  final ApiClient client;
  QuranRepository(this.client);

  Future<QuranPage> getPage(int pageNumber) async {
    final res = await client.dio.get('/quran/page/$pageNumber');
    return QuranPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getSurah(int surahNumber) async {
    final res = await client.dio.get('/quran/surah/$surahNumber');
    return res.data as Map<String, dynamic>;
  }
}
