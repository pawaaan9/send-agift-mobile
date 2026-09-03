import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for environment-driven configuration.
class AppConfig {
  AppConfig._();

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';
}
