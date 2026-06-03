import 'dart:math';

class ASRResponse {
  final String text;
  final double avgLogprob;
  final List<String> tokens;

  ASRResponse({
    required this.text,
    required this.avgLogprob,
    required this.tokens,
  });

  /// Convert avg_logprob (negative) to a 0..1 confidence proxy.
  double get confidence => exp(avgLogprob).clamp(0.0, 1.0);

  factory ASRResponse.fromJson(Map<String, dynamic> json) {
    final segments = (json['segments'] as List?) ?? const [];
    double avg = 0.0;
    int count = 0;
    for (final s in segments.cast<Map<String, dynamic>>()) {
      final lp = s['avg_logprob'];
      if (lp is num) {
        avg += lp.toDouble();
        count++;
      }
    }
    final avgLp = count > 0 ? avg / count : -0.3; // default ~0.74 conf
    final text = (json['text'] as String? ?? '').trim();
    final words = (json['words'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map((w) => (w['word'] as String? ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    return ASRResponse(text: text, avgLogprob: avgLp, tokens: words);
  }
}
