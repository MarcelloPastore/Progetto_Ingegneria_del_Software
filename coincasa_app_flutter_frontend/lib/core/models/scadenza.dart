class Scadenza {
  const Scadenza({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.dataScadenza,
    this.isRicorrente = false,
    this.cadenzaGiorni,
    required this.idCasa,
    required this.dataCreazione,
  });

  final String id;
  final String nome;
  final String descrizione;
  final DateTime dataScadenza;
  final bool isRicorrente;
  final int? cadenzaGiorni;
  final String idCasa;
  final DateTime dataCreazione;

  factory Scadenza.fromJson(Map<String, dynamic> json) {
    return Scadenza(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descrizione: json['descrizione']?.toString() ?? '',
      dataScadenza: _parseDate(json['dataScadenza']),
      isRicorrente: json['isRicorrente'] as bool? ?? false,
      cadenzaGiorni: (json['cadenzaGiorni'] as num?)?.toInt(),
      idCasa: json['idCasa']?.toString() ?? '',
      dataCreazione: _parseDate(json['dataCreazione']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
