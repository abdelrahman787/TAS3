class QuranWord {
  final int id;
  final int page;
  final int surah;
  final int ayah;
  final int line;
  final int wordIndex;
  final String uthmaniText;
  final String normalizedText;
  final double? bboxX;
  final double? bboxY;
  final double? bboxW;
  final double? bboxH;
  bool isRevealed; // Phase 2 will toggle this; defaults to true in Phase 1

  QuranWord({
    required this.id,
    required this.page,
    required this.surah,
    required this.ayah,
    required this.line,
    required this.wordIndex,
    required this.uthmaniText,
    required this.normalizedText,
    this.bboxX,
    this.bboxY,
    this.bboxW,
    this.bboxH,
    this.isRevealed = true,
  });
}
