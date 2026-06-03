import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/matching/matching_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../recitation/presentation/screens/recitation_screen.dart';
import '../providers/quran_providers.dart';
import '../widgets/mushaf_page_widget.dart';

class QuranPageScreen extends ConsumerStatefulWidget {
  final int initialPage;
  const QuranPageScreen({super.key, required this.initialPage});

  @override
  ConsumerState<QuranPageScreen> createState() => _QuranPageScreenState();
}

class _QuranPageScreenState extends ConsumerState<QuranPageScreen> {
  late final PageController _controller;
  late int _currentPage;
  DifficultyMode _difficulty = DifficultyMode.normal;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startRecitation() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }
    final async = ref.read(quranPageProvider(_currentPage));
    final page = async.value;
    if (page == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecitationScreen(
          pageNumber: _currentPage,
          words: page.words,
          difficulty: _difficulty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(quranPageProvider(_currentPage));
    final canStart = pageAsync.hasValue;
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة $_currentPage'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              reverse: true,
              itemCount: AppConstants.totalPages,
              onPageChanged: (i) => setState(() => _currentPage = i + 1),
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                final async = ref.watch(quranPageProvider(pageNumber));
                return async.when(
                  data: (page) => MushafPageWidget(words: page.words),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load page $pageNumber.\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                SegmentedButton<DifficultyMode>(
                  segments: const [
                    ButtonSegment(value: DifficultyMode.easy, label: Text('Easy')),
                    ButtonSegment(value: DifficultyMode.normal, label: Text('Normal')),
                    ButtonSegment(value: DifficultyMode.strict, label: Text('Strict')),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (s) => setState(() => _difficulty = s.first),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canStart ? _startRecitation : null,
                    child: const Text('Start Recitation'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
