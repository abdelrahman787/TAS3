import '../../domain/entities/quran_word.dart';
import 'word_model.dart';

class QuranPage {
  final int page;
  final int totalWords;
  final List<QuranWord> words;

  QuranPage({required this.page, required this.totalWords, required this.words});

  factory QuranPage.fromJson(Map<String, dynamic> json) {
    final list = (json['words'] as List)
        .cast<Map<String, dynamic>>()
        .map(WordModel.fromJson)
        .toList();
    return QuranPage(
      page: json['page'] as int,
      totalWords: json['total_words'] as int,
      words: list,
    );
  }
}
