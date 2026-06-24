import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/repository/turni_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

final turniRepositoryProvider = Provider<ITurniRepository>(
  (_) => const TurniRepositoryImpl(),
);
