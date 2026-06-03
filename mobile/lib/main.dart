import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/preferences/user_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO(phase5c): forward to Crashlytics or Sentry in release builds.
    if (kDebugMode) debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0C1117),
      child: Center(
        child: Text(
          'حدث خطأ غير متوقع.\nأعد تشغيل التطبيق.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFC9A227), fontSize: 16),
        ),
      ),
    );
  };

  // Preload SharedPreferences so the Riverpod provider can be overridden
  // with a synchronous value — eliminates the bootstrap loading flicker.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith((_) async => prefs),
      ],
      child: const QuranTasmee3App(),
    ),
  );
}

class QuranTasmee3App extends StatelessWidget {
  const QuranTasmee3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appNameLatin,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _Bootstrap(),
    );
  }
}

class _Bootstrap extends ConsumerWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    return prefsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Failed to load preferences: $e')),
      ),
      data: (_) {
        final prefs = ref.read(userPreferencesProvider);
        if (!prefs.onboardingSeen) {
          return OnboardingScreen(
            onDone: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          );
        }
        return const HomeScreen();
      },
    );
  }
}
