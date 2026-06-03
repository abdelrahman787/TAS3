import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/analytics_api.dart';
import '../../data/analytics_models.dart';
import '../widgets/error_breakdown_bar.dart';
import 'difficult_words_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final sessions = ref.watch(sessionsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My progress')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(progressProvider);
          ref.invalidate(sessionsListProvider);
          ref.invalidate(difficultWordsProvider);
          await ref.read(progressProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            progress.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Failed to load progress: $e',
                  style: const TextStyle(color: AppColors.mutedText)),
              data: (p) => _ProgressCard(stats: p),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Error breakdown'),
            const SizedBox(height: 8),
            progress.maybeWhen(
              data: (p) => ErrorBreakdownBar(stats: p),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber, color: AppColors.gold),
              title: const Text('Difficult words'),
              subtitle: const Text(
                'Words you forget or mispronounce most often',
                style: TextStyle(color: AppColors.mutedText),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DifficultWordsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _SectionHeader('Recent sessions'),
            const SizedBox(height: 8),
            sessions.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Failed: $e',
                  style: const TextStyle(color: AppColors.mutedText)),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No completed sessions yet.',
                        style: TextStyle(color: AppColors.mutedText)),
                  );
                }
                return Column(
                  children: list.map(_SessionTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ProgressStats stats;
  const _ProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pct = (stats.accuracy * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$pct%',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  )),
              const Text('Overall accuracy',
                  style: TextStyle(color: AppColors.mutedText)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Kv('Sessions', '${stats.sessionCount}'),
              _Kv('Words', '${stats.totalWords}'),
              _Kv('Correct', '${stats.correctWords}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  final String k;
  final String v;
  const _Kv(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$k: ', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
          Text(v, style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionSummary s;
  const _SessionTile(this.s);

  String _date() {
    final d = s.endedAt ?? s.createdAt;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final acc = s.accuracy;
    final pct = acc == null ? '—' : '${(acc * 100).round()}%';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.gold,
        child: Text(pct, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      title: Text('Page ${s.pageStart}${s.pageEnd != s.pageStart ? '–${s.pageEnd}' : ''}  ·  ${s.difficulty}'),
      subtitle: Text(
        '${_date()}  ·  ${s.correctWords ?? 0}/${s.totalWords ?? 0} correct',
        style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
      ),
    );
  }
}
