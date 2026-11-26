import 'package:flutter/foundation.dart';

class AppConfig {
  static String? _overrideBaseUrl;

  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static String get apiBaseUrl =>
      (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty)
          ? _overrideBaseUrl!
          : defaultBaseUrl;

  static void setOverrideBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _overrideBaseUrl = null;
    } else {
      _overrideBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    }
  }

  static String get wsBaseUrl {
    final httpUrl = apiBaseUrl;
    if (httpUrl.startsWith('https://')) {
      return httpUrl.replaceFirst('https://', 'wss://');
    }
    return httpUrl.replaceFirst('http://', 'ws://');
  }

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 25);
}
