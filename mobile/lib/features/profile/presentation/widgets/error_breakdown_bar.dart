import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/analytics_models.dart';

class ErrorBreakdownBar extends StatelessWidget {
  final ProgressStats stats;
  const ErrorBreakdownBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final segments = [
      _Seg('Forget', stats.forgottenWords, AppColors.gold),
      _Seg('Substitution', stats.substitutions, Colors.orangeAccent),
      _Seg('Order', stats.orderErrors, Colors.purpleAccent),
      _Seg('Pronunciation', stats.pronunciationErrors, Colors.redAccent),
    ];
    final total = segments.fold<int>(0, (a, s) => a + s.value);
    if (total == 0) {
      return const Text(
        'No errors recorded yet.',
        style: TextStyle(color: AppColors.mutedText),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final s in segments)
                  if (s.value > 0)
                    Expanded(flex: s.value, child: Container(color: s.color)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final s in segments)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: s.color),
                  const SizedBox(width: 6),
                  Text('${s.label} (${s.value})',
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Seg {
  final String label;
  final int value;
  final Color color;
  const _Seg(this.label, this.value, this.color);
}
