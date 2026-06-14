import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/services/session_manager.dart';
import 'package:coincasa_app/core/state/active_casa.dart';

Future<Casa> ensureActiveCasaContext(
  ActiveCasaController activeCasa, {
  List<Casa>? caseUtente,
  String? preferredCasaId,
}) async {
  final caseDisponibili = caseUtente ?? await ApiProvider.casa.list();
  if (caseDisponibili.isEmpty) {
    throw StateError('Nessuna casa disponibile.');
  }

  final requestedId = preferredCasaId?.trim();
  final activeId = activeCasa.selectedCasaId?.trim();
  final apiId = ApiProvider.client.currentCasaId?.trim();
  final selectedId = requestedId?.isNotEmpty == true
      ? requestedId
      : activeId?.isNotEmpty == true
      ? activeId
      : apiId;

  final selected = caseDisponibili.firstWhere(
    (casa) => casa.id == selectedId,
    orElse: () => caseDisponibili.first,
  );

  final alreadyActive =
      activeCasa.selectedCasaId == selected.id &&
      ApiProvider.client.currentCasaId == selected.id &&
      activeCasa.ruoloCasa != null;

  if (!alreadyActive) {
    final ruolo = await SessionManager.selectCasa(casaId: selected.id);
    activeCasa.setCasaContext(casaId: selected.id, ruolo: ruolo);
  }
  activeCasa.resolveCasa(caseDisponibili);
  return selected;
}
