// lib/services/config_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // Cached values
  String? _apiBaseUrl;

  // Getters for configuration values
  String get apiBaseUrl => _apiBaseUrl ??= dotenv.env['API_BASE_URL'] ?? 'http://192.168.7.57:5000';

}

// Create a global instance for easy access
final configService = ConfigService();