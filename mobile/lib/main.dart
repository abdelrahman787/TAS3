import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/preferences/user_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

void main() {
  runApp(const ProviderScope(child: QuranTasmee3App()));
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
