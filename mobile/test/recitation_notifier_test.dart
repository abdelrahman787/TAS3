import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tasmee3/core/asr/asr_manager.dart';
import 'package:quran_tasmee3/core/asr/asr_response.dart';
import 'package:quran_tasmee3/core/matching/matching_engine.dart';
import 'package:quran_tasmee3/core/network/api_client.dart';
import 'package:quran_tasmee3/features/quran/domain/entities/quran_word.dart';
import 'package:quran_tasmee3/features/recitation/data/recitation_api.dart';
import 'package:quran_tasmee3/features/recitation/domain/recitation_state.dart';
import 'package:quran_tasmee3/features/recitation/presentation/notifier/recitation_notifier.dart';

import 'helpers/mock_secure_storage.dart';

class FakeASRManager extends ASRManager {
  final List<String> responses;
  int _index = 0;
  final String _lastPath = '/tmp/fake.m4a';

  FakeASRManager(this.responses) : super(apiKey: 'test');

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<String> start() async => _lastPath;

  @override
  Future<String?> stop() async => _lastPath;

  @override
  Future<void> dispose() async {}

  @override
  Future<ASRResponse?> transcribe(String audioPath) async {
    if (_index >= responses.length) {
      return ASRResponse(text: '', avgLogprob: -5.0, tokens: const []);
    }
    final text = responses[_index++];
    return ASRResponse(
      text: text,
      avgLogprob: 0.0, // exp(0) = 1.0 → high confidence
      tokens: text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList(),
    );
  }
}

class FakeRecitationApi extends RecitationApi {
  final List<List<PendingError>> errorBatches = [];
  SessionStats? completedStats;

  FakeRecitationApi() : super(ApiClient());

  @override
  Future<String> createSession({
    String? userId,
    required int pageStart,
    required int pageEnd,
    required DifficultyMode difficulty,
  }) async =>
      'fake-session-id';

  @override
  Future<void> logErrors(String sessionId, List<PendingError> errors) async {
    if (errors.isNotEmpty) errorBatches.add(List.of(errors));
  }

  @override
  Future<void> complete(String sessionId, SessionStats stats) async {
    completedStats = stats;
  }
}

QuranWord _w(int id, String text) => QuranWord(
      id: id,
      page: 1,
      surah: 1,
      ayah: 1,
      line: 1,
      wordIndex: id,
      uthmaniText: text,
      normalizedText: text,
    );

RecitationParams _params(List<QuranWord> words) => RecitationParams(
      pageNumber: 1,
      words: words,
      difficulty: DifficultyMode.normal,
    );

void main() {
  // flutter_secure_storage uses MethodChannels that aren't implemented on
  // the Dart VM. ApiClient's request interceptor reads from secure storage,
  // and although our fakes never trigger a real HTTP call, constructing the
  // ApiClient still wires the channel — stub it out so any incidental use
  // resolves to MockSecureStorage instead of crashing the test isolate.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final backing = MockSecureStorage();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'read':
          return await backing.read(key: call.arguments['key'] as String);
        case 'write':
          await backing.write(
            key: call.arguments['key'] as String,
            value: call.arguments['value'] as String?,
          );
          return null;
        case 'delete':
          await backing.delete(key: call.arguments['key'] as String);
          return null;
        case 'deleteAll':
          await backing.deleteAll();
          return null;
        case 'containsKey':
          return await backing.containsKey(key: call.arguments['key'] as String);
        case 'readAll':
          return jsonEncode(await backing.readAll());
        default:
          return null;
      }
    });
  });

  test('starts in idle state', () {
    final notifier = RecitationNotifier(
      params: _params([_w(1, 'بِسْمِ')]),
      asr: FakeASRManager(const []),
      api: FakeRecitationApi(),
    );
    expect(notifier.state.status, RecitationStatus.idle);
    expect(notifier.state.currentWordIndex, 0);
    expect(notifier.state.revealedWords, [false]);
    expect(notifier.state.totalWords, 1);
  });

  test('start() flips status to listening and stores sessionId', () {
    fakeAsync((async) {
      final notifier = RecitationNotifier(
        params: _params([_w(1, 'بِسْمِ')]),
        asr: FakeASRManager(const []),
        api: FakeRecitationApi(),
      );
      unawaited(notifier.start());
      async.flushMicrotasks();
      expect(notifier.state.sessionId, 'fake-session-id');
      // After createSession resolves and the loop schedules its first chunk,
      // status is listening; once the chunk's Future.delayed expires we
      // briefly transition through processing. Either is acceptable here.
      expect(notifier.state.status, isNot(RecitationStatus.idle));
    });
  });

  test('reveals a word when ASR returns correct text', () {
    fakeAsync((async) {
      final asr = FakeASRManager(['بِسْمِ']);
      final notifier = RecitationNotifier(
        params: _params([_w(1, 'بِسْمِ')]),
        asr: asr,
        api: FakeRecitationApi(),
      );
      unawaited(notifier.start());
      async.flushMicrotasks();
      // Advance past one chunk window (4s) so the first transcribe lands.
      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();

      expect(notifier.state.currentWordIndex, 1);
      expect(notifier.state.revealedWords.first, isTrue);
      expect(notifier.state.correctWords, 1);
    });
  });

  test('pause() stops the listening cycle', () {
    fakeAsync((async) {
      final notifier = RecitationNotifier(
        params: _params([_w(1, 'بِسْمِ')]),
        asr: FakeASRManager(const []),
        api: FakeRecitationApi(),
      );
      unawaited(notifier.start());
      async.flushMicrotasks();
      unawaited(notifier.pause());
      async.flushMicrotasks();
      expect(notifier.state.status, RecitationStatus.paused);
    });
  });

  test('silence timer increments and surfaces 10s threshold', () {
    fakeAsync((async) {
      final notifier = RecitationNotifier(
        params: _params([_w(1, 'بِسْمِ')]),
        asr: FakeASRManager(const []), // never returns text → no reset
        api: FakeRecitationApi(),
      );
      unawaited(notifier.start());
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 11));
      async.flushMicrotasks();
      // The silence Timer.periodic ticks once per second while listening; we
      // only assert that the counter advanced past the 10s forget threshold.
      // TODO(5b): assert _forgotten increment once we expose stats via state.
      expect(notifier.state.silenceSeconds, greaterThanOrEqualTo(10));
    });
  });
}
