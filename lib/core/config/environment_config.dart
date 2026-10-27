enum Environment { dev, staging, prod }

class EnvironmentConfig {
  static late Environment _environment;
  static late EnvironmentConfig _instance;

  /// Only one EverGreen backend exists (Render, production database), so every
  /// flavor talks to it. The free Render instance sleeps when idle; the first
  /// request after a nap can take ~50s, hence the long timeouts.
  static const String backendUrl = 'https://evergreen-backend-lgmy.onrender.com/';

  /// Sent as the `api-key` header on the two routes that run before a JWT
  /// exists (`auth/signIn`, `user/forgetPassword`). Same value the Kotlin app ships.
  static const String apiKey = 'evergreen_api_key';

  final String apiBaseUrl;
  final int connectionTimeout;
  final int receiveTimeout;
  final bool enableLogging;
  final Map<String, bool> featureFlags;

  EnvironmentConfig._({
    required this.apiBaseUrl,
    required this.connectionTimeout,
    required this.receiveTimeout,
    required this.enableLogging,
    required this.featureFlags,
  });

  static void initialize(Environment environment) {
    _environment = environment;
    _instance = _createConfig(environment);
  }

  static EnvironmentConfig get instance => _instance;
  static Environment get environment => _environment;

  static bool get isDev => _environment == Environment.dev;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProd => _environment == Environment.prod;

  static EnvironmentConfig _createConfig(Environment environment) {
    final isProd = environment == Environment.prod;
    return EnvironmentConfig._(
      apiBaseUrl: backendUrl,
      connectionTimeout: 60000,
      receiveTimeout: 60000,
      enableLogging: !isProd,
      featureFlags: {
        'showDebugInfo': !isProd,
        'enableAnalytics': false,
        'enableCrashReporting': false,
      },
    );
  }

  bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }
}
