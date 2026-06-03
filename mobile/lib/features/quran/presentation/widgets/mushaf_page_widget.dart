import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/quran_word.dart';

class MushafPageWidget extends StatelessWidget {
  final List<QuranWord> words;
  const MushafPageWidget({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    // Group words by line number.
    final byLine = <int, List<QuranWord>>{};
    for (final w in words) {
      byLine.putIfAbsent(w.line, () => []).add(w);
    }
    final lines = byLine.keys.toList()..sort();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final lineNum in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  textDirection: TextDirection.rtl,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final w in byLine[lineNum]!)
                      Text(
                        w.uthmaniText,
                        style: TextStyle(
                          fontFamily: 'UthmaniHafs',
                          fontSize: lineNum == 1 ? 18 : 22,
                          color: AppColors.text,
                          height: 1.6,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
