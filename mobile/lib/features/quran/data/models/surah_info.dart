class SurahInfo {
  final int surah;
  final int pageStart;
  final int pageEnd;
  final int ayahCount;

  SurahInfo({
    required this.surah,
    required this.pageStart,
    required this.pageEnd,
    required this.ayahCount,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> json) => SurahInfo(
        surah: json['surah'] as int,
        pageStart: json['page_start'] as int,
        pageEnd: json['page_end'] as int,
        ayahCount: json['ayah_count'] as int,
      );
}
