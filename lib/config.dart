class AppConfig {
  AppConfig._();

  /// Remote server base URL, injected at build time via:
  ///   flutter run --dart-define=BASE_URL=https://api.yourserver.com
  static const String baseUrl = String.fromEnvironment('BASE_URL');
}
