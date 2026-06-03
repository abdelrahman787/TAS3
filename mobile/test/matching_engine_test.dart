import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tasmee3/core/matching/matching_engine.dart';
import 'package:quran_tasmee3/features/quran/domain/entities/quran_word.dart';

QuranWord _w(int id, String text) => QuranWord(
      id: id,
      page: 1,
      surah: 1,
      ayah: 1,
      line: 1,
      wordIndex: id,
      uthmaniText: text,
      normalizedText: text,
    );

void main() {
  group('normalize', () {
    test('strips tashkeel', () {
      expect(
        MatchingEngine.normalize('بِسْمِ', DifficultyMode.normal),
        'بسم',
      );
    });

    test('normalizes alif variants and wasla', () {
      expect(MatchingEngine.normalize('أحمد', DifficultyMode.normal), 'احمد');
      expect(MatchingEngine.normalize('إنّ', DifficultyMode.normal), 'ان');
      expect(MatchingEngine.normalize('آمن', DifficultyMode.normal), 'امن');
      expect(MatchingEngine.normalize('ٱللَّه', DifficultyMode.normal), 'الله');
    });

    test('normalizes ya maqsura', () {
      expect(MatchingEngine.normalize('هدى', DifficultyMode.normal), 'هدي');
    });

    test('removes tatweel', () {
      expect(MatchingEngine.normalize('مـحـمد', DifficultyMode.normal), 'محمد');
    });

    test('easy mode collapses ta marbuta', () {
      expect(MatchingEngine.normalize('صلاة', DifficultyMode.easy), 'صلاه');
      expect(MatchingEngine.normalize('صلاة', DifficultyMode.normal), 'صلاة');
    });
  });

  group('levenshtein', () {
    test('identical strings → 0', () {
      expect(MatchingEngine.levenshtein('بسم', 'بسم'), 0);
    });

    test('single substitution → 1', () {
      expect(MatchingEngine.levenshtein('بسم', 'بشم'), 1);
    });

    test('ratio is in [0,1]', () {
      final r = MatchingEngine.levenshteinRatio('بسم', 'الله');
      expect(r, greaterThan(0.0));
      expect(r, lessThanOrEqualTo(1.0));
    });
  });

  group('match single word', () {
    test('exact match with high confidence → isMatch true', () {
      final r = MatchingEngine.match(
        asrToken: 'بِسْمِ',
        expectedWord: 'بِسْمِ',
        confidence: 0.9,
        mode: DifficultyMode.normal,
      );
      expect(r.isMatch, isTrue);
    });

    test('text match but low confidence → pronunciation error', () {
      final r = MatchingEngine.match(
        asrToken: 'بسم',
        expectedWord: 'بسم',
        confidence: 0.5,
        mode: DifficultyMode.normal,
      );
      expect(r.isMatch, isFalse);
      expect(r.errorType, ErrorType.pronunciation);
    });

    test('clearly different word → substitution', () {
      final r = MatchingEngine.match(
        asrToken: 'الله',
        expectedWord: 'بسم',
        confidence: 0.9,
        mode: DifficultyMode.normal,
      );
      expect(r.isMatch, isFalse);
      expect(r.errorType, ErrorType.substitution);
    });

    test('empty asr token → asrFailure', () {
      final r = MatchingEngine.match(
        asrToken: '   ',
        expectedWord: 'بسم',
        confidence: 0.9,
        mode: DifficultyMode.normal,
      );
      expect(r.errorType, ErrorType.asrFailure);
    });

    test('easy mode is more lenient than strict', () {
      const asr = 'بسما'; // one char extra
      const expected = 'بسم';
      final easy = MatchingEngine.match(
        asrToken: asr,
        expectedWord: expected,
        confidence: 0.9,
        mode: DifficultyMode.easy,
      );
      final strict = MatchingEngine.match(
        asrToken: asr,
        expectedWord: expected,
        confidence: 0.9,
        mode: DifficultyMode.strict,
      );
      expect(easy.isMatch, isTrue);
      expect(strict.isMatch, isFalse);
    });
  });

  group('matchSequence', () {
    test('reveals all matching prefix and stops at first error', () {
      final expected = [
        _w(1, 'بِسْمِ'),
        _w(2, 'ٱللَّهِ'),
        _w(3, 'ٱلرَّحْمَٰنِ'),
        _w(4, 'ٱلرَّحِيمِ'),
      ];
      final tokens = ['بسم', 'الله', 'الرحيم', 'الرحيم']; // 3rd is wrong order
      final r = MatchingEngine.matchSequence(
        asrTokens: tokens,
        expectedSequence: expected,
        confidence: 0.9,
        mode: DifficultyMode.normal,
      );
      expect(r.matchedCount, 2);
      expect(r.firstError, isNotNull);
      expect(r.firstError!.errorType, ErrorType.substitution);
    });

    test('reciting a later word out of order → orderError', () {
      final expected = [
        _w(1, 'بِسْمِ'),
        _w(2, 'ٱللَّهِ'),
        _w(3, 'ٱلرَّحْمَٰنِ'),
        _w(4, 'ٱلرَّحِيمِ'),
      ];
      // User skips ٱللَّهِ and jumps to ٱلرَّحِيمِ
      final r = MatchingEngine.matchSequence(
        asrTokens: ['بسم', 'الرحيم'],
        expectedSequence: expected,
        confidence: 0.9,
        mode: DifficultyMode.normal,
      );
      expect(r.matchedCount, 1);
      expect(r.firstError?.errorType, ErrorType.orderError);
    });

    test('full ayah recited in one breath reveals all', () {
      final expected = [
        _w(1, 'بِسْمِ'),
        _w(2, 'ٱللَّهِ'),
        _w(3, 'ٱلرَّحْمَٰنِ'),
        _w(4, 'ٱلرَّحِيمِ'),
      ];
      final r = MatchingEngine.matchSequence(
        asrTokens: ['بسم', 'الله', 'الرحمن', 'الرحيم'],
        expectedSequence: expected,
        confidence: 0.9,
        mode: DifficultyMode.normal,
      );
      expect(r.matchedCount, 4);
      expect(r.firstError, isNull);
    });
  });

  group('tokenize', () {
    test('splits on whitespace and removes punctuation', () {
      expect(
        MatchingEngine.tokenize('بسم الله، الرحمن الرحيم.'),
        ['بسم', 'الله', 'الرحمن', 'الرحيم'],
      );
    });
  });
}
