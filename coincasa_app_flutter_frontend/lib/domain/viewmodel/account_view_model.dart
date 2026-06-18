import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/account_repository_provider.dart';
import 'package:coincasa_app/core/services/session_manager.dart';
import 'package:coincasa_app/domain/repositories/i_account_repository.dart';

class AccountViewModel extends Notifier<void> {
  late IAccountRepository _repository;

  @override
  void build() {
    _repository = ref.read(accountRepositoryProvider);
  }

  /// Cambia username e aggiorna la sessione locale.
  /// Restituisce il nuovo username confermato dal server.
  Future<String> patchUsername(String username) async {
    final saved = await _repository.patchUsername(username);
    await SessionManager.updateUsername(saved);
    return saved;
  }

  /// Cambia email e invalida la sessione (richiede ri-verifica).
  /// Restituisce la nuova email confermata dal server.
  Future<String> patchEmail(String email) async {
    final confirmed = await _repository.patchEmail(email);
    await SessionManager.clear();
    return confirmed;
  }

  /// Cambia password e invalida la sessione (richiede re-login).
  Future<void> patchPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _repository.patchPassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    await SessionManager.clear();
  }

  /// Elimina l'account e invalida la sessione.
  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    await SessionManager.clear();
  }
}

final accountViewModelProvider = NotifierProvider<AccountViewModel, void>(
  AccountViewModel.new,
);
