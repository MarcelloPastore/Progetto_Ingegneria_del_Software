import 'package:flutter/foundation.dart';

class Env {
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:23109/api/v1';
    }

    return 'http://localhost:23109/api/v1';
  }
}
