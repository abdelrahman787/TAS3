import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../quran/domain/entities/quran_word.dart';

class WordWidget extends StatelessWidget {
  final QuranWord word;
  final bool isRevealed;
  final bool isCurrent;
  final double fontSize;

  const WordWidget({
    super.key,
    required this.word,
    required this.isRevealed,
    required this.isCurrent,
    this.fontSize = 22,
  });

  double get _hiddenWidth => (word.uthmaniText.length * 14.0).clamp(30.0, 120.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: isCurrent && !isRevealed
            ? Border.all(color: AppColors.gold, width: 1)
            : null,
        borderRadius: BorderRadius.circular(4),
        color: isRevealed ? Colors.transparent : const Color(0xFF1E2D40),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        child: isRevealed
            ? Text(
                word.uthmaniText,
                key: ValueKey('w${word.id}-shown'),
                style: TextStyle(
                  fontFamily: 'UthmaniHafs',
                  fontSize: fontSize,
                  color: AppColors.text,
                  height: 1.6,
                ),
              )
            : SizedBox(
                key: ValueKey('w${word.id}-hidden'),
                width: _hiddenWidth,
                height: fontSize + 6,
              ),
      ),
    );
  }
}
