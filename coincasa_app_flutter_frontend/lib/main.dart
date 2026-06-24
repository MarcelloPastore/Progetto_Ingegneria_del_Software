import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/api/api_provider.dart';
import 'core/services/session_manager.dart';

void main() {
  ApiProvider.client.onUnauthorized = () async {
    await SessionManager.clear();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  };

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
  );
  runApp(const ProviderScope(child: CoinCasaApp()));
}
