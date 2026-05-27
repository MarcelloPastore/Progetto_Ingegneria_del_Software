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
        raw['task']?.toString() ??
        raw['nome']?.toString() ??
        raw['descrizione']?.toString() ??
        'Turno';
  }

  DateTime? get data {
    final value =
        raw['data'] ??
        raw['dataProssimaPulizia'] ??
        raw['dataScadenza'] ??
        raw['scadenza'] ??
        raw['giorno'];
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  DateTime? get dataProssimaPulizia {
    final value = raw['dataProssimaPulizia'];
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return data;
  }

  String get assegnatarioId {
    final value = raw['assegnatario'];
    if (value is Map<String, dynamic>) {
      return value['id']?.toString() ?? '';
    }
    return raw['assegnatarioCorrente']?.toString() ??
        raw['responsabileId']?.toString() ??
        '';
  }

  String get assegnatarioNome {
    final value = raw['assegnatario'];
    if (value is Map<String, dynamic>) {
      return value['username']?.toString() ??
          value['nome']?.toString() ??
          value['name']?.toString() ??
          'Non assegnato';
    }
    return raw['responsabileNome']?.toString() ?? 'Non assegnato';
  }

  int get cadenzaGiorni {
    final value = raw['cadenzaGiorni'];
    if (value is num) {
      return value.toInt();
    }
    return 1;
  }

  bool get completato {
    final value = raw['completato'] ?? raw['completatoQuestaSettimana'];
    if (value is bool) {
      return value;
    }
    return false;
  }

  bool get rotazioneAttiva {
    final value = raw['rotazioneAttiva'] ?? raw['rotazioneTurno'];
    if (value is bool) {
      return value;
    }
    return false;
  }
}
