import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/auth/auth_notifier.dart';
import 'core/auth/auth_providers.dart';
import 'core/auth/auth_state.dart';
import 'core/constants/app_constants.dart';
import 'core/preferences/user_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO 5c.6: replace with FirebaseCrashlytics.instance.recordFlutterFatalError
    if (kDebugMode) debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    // TODO 5c.6: FirebaseCrashlytics.instance.recordError(details.exception, details.stack)
    return const Material(
      color: Color(0xFF0C1117),
      child: Center(
        child: Text(
          'حدث خطأ غير متوقع.\nأعد تشغيل التطبيق.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFC9A227), fontSize: 16),
        ),
      ),
    );
  };

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

class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap();

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  bool _authInitStarted = false;

  void _ensureAuthInit(AuthNotifier notifier) {
    if (_authInitStarted) return;
    _authInitStarted = true;
    // Fire-and-forget; the notifier updates state when init resolves.
    notifier.init();
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    return prefsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Failed to load preferences: $e')),
      ),
      data: (_) {
        final prefs = ref.read(userPreferencesProvider);
        if (!prefs.onboardingSeen) {
          return OnboardingScreen(
            onDone: () {
              // Onboarding done — flip state and re-render the bootstrap.
              setState(() {});
            },
          );
        }

        final authNotifier = ref.read(authNotifierProvider.notifier);
        _ensureAuthInit(authNotifier);
        final auth = ref.watch(authNotifierProvider);

        switch (auth.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.authenticated:
            return const HomeScreen();
        }
      },
    );
  }
}
