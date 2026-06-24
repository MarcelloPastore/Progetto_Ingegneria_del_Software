import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/api/api_provider.dart';
import 'core/services/session_manager.dart';
import 'core/state/active_casa.dart';

final ProviderContainer _container = ProviderContainer();

void main() {
  ApiProvider.client.onUnauthorized = () async {
    await SessionManager.clear();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  };

  ApiProvider.client.onRoleOutdated = () {
    _container.read(activeCasaProvider.notifier).state = const ActiveCasaState();
    ApiProvider.client.clearCasaContext();
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Il tuo ruolo è cambiato. Riseleziona la casa.'),
        duration: Duration(seconds: 4),
      ),
    );
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/casa', (_) => false);
  };

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
  );
  runApp(
    UncontrolledProviderScope(container: _container, child: const CoinCasaApp()),
  );
}
