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
        return 'http://10.0.2.2:5000/logistics';
      case Environment.staging:
        return 'https://staging-server.com/logistics';
      case Environment.production:
        return 'https://production-server.com/logistics';
    }
  }
}