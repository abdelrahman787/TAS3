import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../../quran/presentation/screens/quran_page_screen.dart';
import '../../../settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openPage(BuildContext context, int page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuranPageScreen(initialPage: page)),
    );
  }

  Future<void> _pickSurah(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Surah number (1–114)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 114) Navigator.pop(ctx, v);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (n == null || !context.mounted) return;

    try {
      final info = await ref.read(quranRepositoryProvider).getSurahInfo(n);
      if (!context.mounted) return;
      _openPage(context, info.pageStart);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load surah $n: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.mutedText),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppConstants.appNameArabic,
                  style: const TextStyle(
                    fontFamily: 'UthmaniHafs',
                    fontSize: 48,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConstants.appNameLatin,
                  style: TextStyle(fontSize: 16, color: AppColors.mutedText),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openPage(context, 1),
                    child: const Text('Open Page 1'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.gold),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _pickSurah(context, ref),
                    child: const Text('Choose Surah'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
