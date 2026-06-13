class Problema {
  const Problema({
    required this.id,
    required this.titolo,
    required this.stato,
    required this.priorita,
    required this.raw,
  });

  final String id;
  final String titolo;
  final String stato;
  final String priorita;
  final Map<String, dynamic> raw;

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

    return Problema(
      id: (json['id'] ?? json['idProblema'] ?? '').toString(),
      titolo:
          (json['titolo'] ?? json['nome'] ?? json['descrizione'] ?? 'Problema')
              .toString(),
      stato: (json['stato'] ?? json['status'] ?? 'Segnalato').toString(),
      priorita: (json['priorita'] ?? json['priority'] ?? 'Media').toString(),
      raw: raw,
    );
  }
}
