import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/domain/repositories/i_account_repository.dart';

class AccountRepositoryImpl implements IAccountRepository {
  const AccountRepositoryImpl();

  @override
  Future<String> patchUsername(String username) =>
      ApiProvider.account.patchUsername(username);

  @override
  Future<String> patchEmail(String email) =>
      ApiProvider.account.patchEmail(email);

  @override
  Future<void> patchPassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      ApiProvider.account.patchPassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

  @override
  Future<void> deleteAccount() => ApiProvider.account.deleteAccount();
}
