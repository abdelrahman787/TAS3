import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    // In RTL, page 1 is on the right. We use reverse: true on PageView so a
    // right-to-left swipe advances to the next page.
    _controller = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null, // Phase 2 will enable this
                child: const Text('Start Recitation (Phase 2)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
