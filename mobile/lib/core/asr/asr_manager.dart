import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'asr_response.dart';

/// Wraps microphone recording + Groq Whisper transcription.
///
/// Usage:
///   final mgr = ASRManager(apiKey: '...');
///   await mgr.start();          // begin capture
///   final path = await mgr.stop();
///   final result = await mgr.transcribe(path);
class ASRManager {
  final String apiKey;
  final AudioRecorder _recorder = AudioRecorder();
  final Dio _dio;

  int _consecutiveFailures = 0;
  int get consecutiveFailures => _consecutiveFailures;

  ASRManager({required this.apiKey, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(receiveTimeout: const Duration(seconds: 30)));

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Begin recording to a temp .m4a file. Caller invokes [stop] to finish.
  Future<String> start() async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'asr_${DateTime.now().millisecondsSinceEpoch}.m4a');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    return path;
  }

  Future<String?> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();

  /// POST audio file to Groq Whisper. Returns null on failure.
  Future<ASRResponse?> transcribe(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) return null;

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioPath, filename: 'audio.m4a'),
        'model': 'whisper-large-v3',
        'language': 'ar',
        'response_format': 'verbose_json',
        'prompt': 'قرآن كريم بسم الله الرحمن الرحيم',
      });

      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.groq.com/openai/v1/audio/transcriptions',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      _consecutiveFailures = 0;
      return ASRResponse.fromJson(response.data ?? const {});
    } catch (_) {
      _consecutiveFailures++;
      return null;
    }
  }

  /// True when 3+ consecutive ASR calls have failed.
  bool get shouldWarnAudioUnclear => _consecutiveFailures >= 3;
}
