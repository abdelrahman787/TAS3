import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/recitation_state.dart';

class SessionSummaryScreen extends StatelessWidget {
  final RecitationState state;
  final int pageNumber;

  const SessionSummaryScreen({
    super.key,
    required this.state,
    required this.pageNumber,
  });

  double get _accuracy =>
      state.totalWords == 0 ? 0 : state.correctWords / state.totalWords;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page $pageNumber — Summary'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScoreCard(accuracy: _accuracy),
            const SizedBox(height: 24),
            _StatRow(label: 'Total words', value: state.totalWords),
            _StatRow(label: 'Correct', value: state.correctWords, color: Colors.greenAccent),
            _StatRow(label: 'Forgotten', value: state.forgottenWords, color: AppColors.gold),
            _StatRow(label: 'Substitutions', value: state.substitutions, color: Colors.orangeAccent),
            _StatRow(label: 'Order errors', value: state.orderErrors, color: Colors.orangeAccent),
            _StatRow(label: 'Pronunciation', value: state.pronunciationErrors, color: Colors.orangeAccent),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final double accuracy;
  const _ScoreCard({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final pct = (accuracy * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const Text('Session score', style: TextStyle(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;
  const _StatRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.text, fontSize: 16)),
          Text(
            '$value',
            style: TextStyle(
              color: color ?? AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
