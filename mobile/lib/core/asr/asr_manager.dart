import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../constants/app_constants.dart';
import 'asr_response.dart';

/// Wraps microphone recording + transcription via the backend ASR proxy.
///
/// Usage:
///   final mgr = ASRManager(dio: apiClient.dio);
///   final path = await mgr.start();
///   await mgr.stop();
///   final result = await mgr.transcribe(path);
///
/// The legacy `apiKey` parameter is retained for source compatibility with
/// existing fakes (e.g. test doubles); it is no longer read. The Groq key
/// now lives only in the backend `.env` (5c.1 / 5c.2).
class ASRManager {
  @Deprecated('GROQ_API_KEY now lives on the backend; this is unused.')
  final String? apiKey;

  final AudioRecorder _recorder = AudioRecorder();
  final Dio _dio;

  int _consecutiveFailures = 0;
  int get consecutiveFailures => _consecutiveFailures;

  ASRManager({this.apiKey, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.backendUrl,
              receiveTimeout: const Duration(seconds: 30),
            ));

  Future<bool> hasPermission() => _recorder.hasPermission();

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

  /// POST audio file to the backend ASR proxy. The Bearer token is attached
  /// by the global ApiClient's Dio interceptor (5b.5); no header is set here.
  /// Returns null on transport / server failure.
  Future<ASRResponse?> transcribe(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) return null;

    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioPath, filename: 'audio.m4a'),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/asr/transcribe',
        data: formData,
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
