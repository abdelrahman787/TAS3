import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/analytics_api.dart';

class DifficultWordsScreen extends ConsumerWidget {
  const DifficultWordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(difficultWordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Difficult words')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (words) {
          if (words.isEmpty) {
            return const Center(
              child: Text(
                'No errors logged yet — recite a page to populate this list.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: words.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
            itemBuilder: (_, i) {
              final w = words[i];
              return ListTile(
                title: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    w.expectedWord,
                    style: const TextStyle(
                      fontFamily: 'UthmaniHafs',
                      fontSize: 22,
                      color: AppColors.text,
                    ),
                  ),
                ),
                subtitle: Text(
                  '${w.errorCount} errors  ·  '
                  'F:${w.forgetCount}  S:${w.substitutionCount}  '
                  'O:${w.orderErrorCount}  P:${w.pronunciationCount}',
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
                trailing: CircleAvatar(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  child: Text('${w.errorCount}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
