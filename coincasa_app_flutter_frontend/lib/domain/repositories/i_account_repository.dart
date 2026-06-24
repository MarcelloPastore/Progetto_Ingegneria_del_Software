abstract interface class IAccountRepository {
  Future<String> patchUsername(String username);

  Future<String> patchEmail(String email);

  Future<void> patchPassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<void> deleteAccount();
}
