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
    return _parseDate(
      raw['data'] ??
          raw['dataTurno'] ??
          raw['dataProssimaPulizia'] ??
          raw['dataScadenza'] ??
          raw['scadenza'] ??
          raw['giorno'],
    );
  }

  DateTime? get dataProssimaPulizia {
    return _parseDate(raw['dataProssimaPulizia']) ?? data;
  }

  DateTime? get dataUltimaPulizia {
    return _parseDate(
      raw['dataUltimaPulizia'] ??
          raw['ultimaPulizia'] ??
          raw['dataUltimaPuliziaTurno'] ??
          raw['lastCleaningDate'] ??
          raw['lastCleaning'],
    );
  }

  DateTime? get dataCreazione {
    return _parseDate(
      raw['dataCreazione'] ??
          raw['createdAt'] ??
          raw['created_at'] ??
          raw['creazione'] ??
          raw['dataInserimento'],
    );
  }

  DateTime? get dataUltimaPuliziaEffettiva {
    final explicit = dataUltimaPulizia;
    if (explicit != null) {
      return _dateOnly(explicit);
    }

    if (completato && data != null) {
      return _dateOnly(data!);
    }

    final creazione = dataCreazione;
    if (creazione != null) {
      return _dateOnly(creazione);
    }

    return data == null ? null : _dateOnly(data!);
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
          '';
    }
    return raw['responsabileNome']?.toString() ?? '';
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

  static DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
