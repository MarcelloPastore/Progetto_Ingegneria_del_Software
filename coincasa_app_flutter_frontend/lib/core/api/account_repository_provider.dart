import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/data/repository/account_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_account_repository.dart';

final accountRepositoryProvider = Provider<IAccountRepository>((ref) {
  return const AccountRepositoryImpl();
});
