class AppConstants {
  static const String appNameArabic = 'قرآن تسميع';
  static const String appNameLatin = 'Quran Tasmee3';

  // Backend URL — override at build with --dart-define=BACKEND_URL=...
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator → host
  );

  static const int totalPages = 604;

  /// Set with --dart-define=GROQ_API_KEY=...
  static const String groqApiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
}
