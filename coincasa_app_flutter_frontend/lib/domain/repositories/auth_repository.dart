import '../../core/models/auth_user.dart';

abstract class AuthRepository {
  Future<(String, AuthUser)> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String username,
    required String nome,
    required String cognome,
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  Future<bool> checkEmailVerificata(String email);

  Future<String> refreshToken(String refreshToken);

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
