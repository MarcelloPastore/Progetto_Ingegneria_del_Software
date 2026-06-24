import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/repository/spese_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

final speseRepositoryProvider = Provider<ISpeseRepository>(
  (_) => const SpeseRepositoryImpl(),
);
