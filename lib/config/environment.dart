// lib/config/environment.dart
enum Environment {
  development,
  staging,
  production
}

class EnvironmentConfig {
  static Environment environment = Environment.development;

  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'https://shreelalchand.com';
      case Environment.staging:
        return 'https://shreelalchand.com';
      case Environment.production:
        return 'https://shreelalchand.com/logistics';
    }
  }
}