import '../../domain/entities/quran_word.dart';

class WordModel {
  static QuranWord fromJson(Map<String, dynamic> json) {
    return QuranWord(
      id: json['id'] as int,
      page: json['page'] as int,
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      line: json['line'] as int,
      wordIndex: json['word_index'] as int,
      uthmaniText: json['uthmani_text'] as String,
      normalizedText: json['normalized_text'] as String,
      bboxX: (json['bbox_x'] as num?)?.toDouble(),
      bboxY: (json['bbox_y'] as num?)?.toDouble(),
      bboxW: (json['bbox_w'] as num?)?.toDouble(),
      bboxH: (json['bbox_h'] as num?)?.toDouble(),
    );
  }
}
