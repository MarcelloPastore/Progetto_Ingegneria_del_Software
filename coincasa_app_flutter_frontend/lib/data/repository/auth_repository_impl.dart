import 'package:coincasa_app/core/api/auth_api.dart';
import '../../core/models/auth_user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;

  AuthRepositoryImpl(this._authApi);

  @override
  Future<(String, domain.AuthUser)> login({
    required String email,
    required String password,
  }) async {
    final result = await _authApi.login(email: email, password: password);
    
    final user = domain.AuthUser(
      id: result.user.id,
      username: result.user.username,
      nome: result.user.nome,
      cognome: result.user.cognome,
      email: email,
    );

    return (result.token, user);
  }

  @override
  Future<void> register({
    required String username,
    required String nome,
    required String cognome,
    required String email,
    required String password,
  }) async {
    await _authApi.register(
      username: username,
      nome: nome,
      cognome: cognome,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _authApi.requestPasswordReset(email);
  }

  @override
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    await _authApi.verifyPasswordResetCode(email: email, code: code);
  }

  @override
  Future<bool> checkEmailVerificata(String email) async {
    return await _authApi.checkEmailVerificata(email);
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    return await _authApi.refreshToken(refreshToken);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _authApi.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }
}
