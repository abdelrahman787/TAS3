import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/matching/matching_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../quran/domain/entities/quran_word.dart';
import '../../domain/recitation_state.dart';
import '../notifier/recitation_notifier.dart';
import '../widgets/word_widget.dart';
import 'session_summary_screen.dart';

class RecitationScreen extends ConsumerStatefulWidget {
  final int pageNumber;
  final List<QuranWord> words;
  final DifficultyMode difficulty;

  const RecitationScreen({
    super.key,
    required this.pageNumber,
    required this.words,
    this.difficulty = DifficultyMode.normal,
  });

  @override
  ConsumerState<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends ConsumerState<RecitationScreen> {
  late final RecitationParams _params;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _params = RecitationParams(
      pageNumber: widget.pageNumber,
      words: widget.words,
      difficulty: widget.difficulty,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(authNotifierProvider).user?.id;
      await ref.read(recitationProvider(_params).notifier).start(userId: userId);
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recitationProvider(_params));
    final notifier = ref.read(recitationProvider(_params).notifier);

    ref.listen<RecitationState>(recitationProvider(_params), (prev, next) {
      if (next.audioUnclearWarning && prev?.audioUnclearWarning != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio unclear'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      if (next.status == RecitationStatus.complete &&
          prev?.status != RecitationStatus.complete) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SessionSummaryScreen(
              state: next,
              pageNumber: widget.pageNumber,
            ),
          ),
        );
      }
    });

    final showManualHighlight = state.silenceSeconds >= 10;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.stop),
          tooltip: 'End session',
          onPressed: () async {
            await notifier.end();
          },
        ),
        title: Text('Page ${widget.pageNumber} — Reciting'),
        actions: [
          IconButton(
            icon: Icon(state.status == RecitationStatus.paused
                ? Icons.play_arrow
                : Icons.pause),
            onPressed: () async {
              if (state.status == RecitationStatus.paused) {
                await notifier.resume();
              } else {
                await notifier.pause();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusBar(state: state, totalWords: widget.words.length),
          Expanded(
            child: !_started
                ? const Center(child: CircularProgressIndicator())
                : _WordsView(words: widget.words, state: state),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: showManualHighlight
                            ? AppColors.gold
                            : AppColors.mutedText,
                        width: showManualHighlight ? 2 : 1,
                      ),
                      foregroundColor: AppColors.text,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: state.isActive
                        ? () => notifier.revealNextWord()
                        : null,
                    child: const Text('Reveal next word'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: showManualHighlight
                            ? AppColors.gold
                            : AppColors.mutedText,
                        width: showManualHighlight ? 2 : 1,
                      ),
                      foregroundColor: AppColors.text,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: state.isActive
                        ? () => notifier.revealFullAyah()
                        : null,
                    child: const Text('Reveal full ayah'),
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

class _StatusBar extends StatelessWidget {
  final RecitationState state;
  final int totalWords;
  const _StatusBar({required this.state, required this.totalWords});

  @override
  Widget build(BuildContext context) {
    final showListening = state.isListening && state.silenceSeconds >= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface.withOpacity(0.6),
      child: Row(
        children: [
          _PulsingDot(active: state.isListening),
          const SizedBox(width: 8),
          Text(
            showListening
                ? 'Listening…  word ${state.currentWordIndex + 1} of $totalWords'
                : 'Word ${state.currentWordIndex + 1} of $totalWords',
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final bool active;
  const _PulsingDot({required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.active ? _c : const AlwaysStoppedAnimation(0.4),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.greenAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _WordsView extends StatelessWidget {
  final List<QuranWord> words;
  final RecitationState state;
  const _WordsView({required this.words, required this.state});

  @override
  Widget build(BuildContext context) {
    final byLine = <int, List<int>>{};
    for (int i = 0; i < words.length; i++) {
      byLine.putIfAbsent(words[i].line, () => []).add(i);
    }
    final lines = byLine.keys.toList()..sort();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            for (final lineNum in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    for (final idx in byLine[lineNum]!)
                      WordWidget(
                        word: words[idx],
                        isRevealed: idx < state.revealedWords.length
                            ? state.revealedWords[idx]
                            : false,
                        isCurrent: idx == state.currentWordIndex,
                        fontSize: lineNum == 1 ? 18 : 22,
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
