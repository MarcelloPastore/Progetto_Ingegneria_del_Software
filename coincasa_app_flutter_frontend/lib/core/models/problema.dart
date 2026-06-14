class StoricoItem {
  const StoricoItem({
    required this.stato,
    required this.data,
    required this.utenteId,
    required this.utenteUsername,
  });

  final String stato;
  final DateTime data;
  final String utenteId;
  final String utenteUsername;

  factory StoricoItem.fromJson(Map<String, dynamic> json) {
    final utente = json['utente'];
    return StoricoItem(
      stato: (json['stato'] ?? '').toString(),
      data: DateTime.tryParse((json['data'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      utenteId: (utente is Map ? utente['id'] : null)?.toString() ?? '',
      utenteUsername:
          (utente is Map ? utente['username'] : null)?.toString() ?? '',
    );
  }
}

class Problema {
  const Problema({
    required this.id,
    required this.titolo,
    required this.stato,
    required this.priorita,
    required this.raw,
    this.storicoStato = const [],
  });

  final String id;
  final String titolo;
  final String stato;
  final String priorita;
  final Map<String, dynamic> raw;
  final List<StoricoItem> storicoStato;

  factory Problema.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    final assegnatario = json['assegnatario'];
    if (assegnatario is Map<String, dynamic>) {
      raw['assegnatarioId'] = assegnatario['id']?.toString() ?? '';
      raw['assegnatarioNome'] =
          (assegnatario['username'] ?? assegnatario['nome'] ?? '').toString();
    }
    final segnalataDa = json['segnalataDa'] ?? json['segnalatoDa'];
    if (segnalataDa is Map<String, dynamic>) {
      raw['segnalatoDaId'] = segnalataDa['id']?.toString() ?? '';
      raw['segnalatoDa'] =
          (segnalataDa['username'] ?? segnalataDa['nome'] ?? '').toString();
    }
    final dataCreazione = DateTime.tryParse(
      (json['dataCreazione'] ?? '').toString(),
    )?.toLocal();
    if (dataCreazione != null) {
      raw['segnalatoData'] =
          '${dataCreazione.day.toString().padLeft(2, '0')}/${dataCreazione.month.toString().padLeft(2, '0')}';
      raw['segnalatoOre'] =
          '${dataCreazione.hour.toString().padLeft(2, '0')}:${dataCreazione.minute.toString().padLeft(2, '0')}';
    }

    final storicoRaw = json['storicoStato'];
    final storicoStato = <StoricoItem>[];
    if (storicoRaw is List) {
      for (final item in storicoRaw) {
        if (item is Map<String, dynamic>) {
          storicoStato.add(StoricoItem.fromJson(item));
        }
      }
    }

    return Problema(
      id: (json['id'] ?? json['idProblema'] ?? '').toString(),
      titolo:
          (json['titolo'] ?? json['nome'] ?? json['descrizione'] ?? 'Problema')
              .toString(),
      stato: (json['stato'] ?? json['status'] ?? 'Segnalato').toString(),
      priorita: (json['priorita'] ?? json['priority'] ?? 'Media').toString(),
      raw: raw,
      storicoStato: storicoStato,
    );
  }

  static int compareByPriority(Problema a, Problema b) {
    const priorityMap = {'urgente': 0, 'media': 1, 'bassa': 2};
    final aVal = priorityMap[a.priorita.toLowerCase()] ?? 3;
    final bVal = priorityMap[b.priorita.toLowerCase()] ?? 3;
    return aVal.compareTo(bVal);
  }
}
