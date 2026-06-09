class Turno {
  const Turno({required this.id, required this.raw});

  final String id;
  final Map<String, dynamic> raw;

  factory Turno.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['idTurno'] ?? json['turnoId'];

    return Turno(id: idValue?.toString() ?? '', raw: json);
  }

  String get titolo {
    return raw['titolo']?.toString() ??
        raw['nome']?.toString() ??
        raw['descrizione']?.toString() ??
        'Turno';
  }

  DateTime? get data {
    final value =
        raw['data'] ?? raw['dataScadenza'] ?? raw['scadenza'] ?? raw['giorno'];
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
