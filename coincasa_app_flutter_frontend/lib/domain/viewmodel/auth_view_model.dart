import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/data/models/auth_user.dart';
import 'package:coincasa_app/core/api/auth_repository_provider.dart';
import 'package:coincasa_app/core/services/session_manager.dart';
import 'package:coincasa_app/core/api/api_provider.dart';


class AuthViewModel extends AsyncNotifier<AuthUser?> {
  @override
  FutureOr<AuthUser?> build() async {
    final restored = await SessionManager.restore();
    if (restored) {
      final client = ApiProvider.client;
      if (client.currentUserId != null) {
        return AuthUser(
          id: client.currentUserId!,
          username: client.currentUserUsername ?? '',
          nome: client.currentUserFirstName ?? '',
          cognome: client.currentUserLastName ?? '',
          email: client.currentUserEmail ?? '',
        );
      }
    }
    return null;
  }


  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final (token, user) = await repository.login(
        email: email,
        password: password,
      );

      ApiProvider.client.setAuthToken(token);
      ApiProvider.client.setCurrentUserIdentity(
        id: user.id,
        email: user.email,
        name: user.nome,
        surname: user.cognome,
        username: user.username,
      );

      await SessionManager.save(
        token: token,
        userId: user.id,
        email: user.email,
        username: user.username,
        nome: user.nome,
        cognome: user.cognome,
      );

      return user;
    });
  }


  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SessionManager.clear();
      ApiProvider.client.setAuthToken(null);
      return null;
    });
  }


  Future<void> register({
    required String username,
    required String nome,
    required String cognome,
    required String email,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.register(
      username: username,
      nome: nome,
      cognome: cognome,
      email: email,
      password: password,
    );
  }


  Future<void> requestPasswordReset(String email) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.requestPasswordReset(email);
  }


  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.verifyPasswordResetCode(email: email, code: code);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }


  Future<bool> checkEmailVerificata(String email) async {
    final repository = ref.read(authRepositoryProvider);
    return repository.checkEmailVerificata(email);
  }
}


final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, AuthUser?>(() => AuthViewModel());
