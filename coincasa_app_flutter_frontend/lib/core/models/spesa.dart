class Spesa {
  const Spesa({
    required this.id,
    required this.descrizione,
    required this.importo,
    required this.data,
    this.dataScadenza,
    this.isRicorrente = false,
    this.partecipanti = const [],
  });

  final String id;
  final String descrizione;
  final double importo;
  final DateTime data;
  final DateTime? dataScadenza;
  final bool isRicorrente;
  final List<Map<String, dynamic>> partecipanti;

  factory Spesa.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['idSpesa'];
    final descrizioneValue =
        json['descrizione'] ?? json['titolo'] ?? json['nome'];
    final importoValue = json['importo'] ?? json['totale'] ?? json['amount'];
    final dataValue =
        json['data'] ??
        json['dataSpesa'] ??
        json['dataCreazione'] ??
        json['createdAt'];
    final dataScadenzaValue = json['dataScadenza'] ?? json['scadenza'];

    return Spesa(
      id: idValue?.toString() ?? '',
      descrizione: descrizioneValue?.toString() ?? '',
      importo: _parseAmount(importoValue),
      data: _parseDate(dataValue),
      dataScadenza: _parseOptionalDate(dataScadenzaValue),
      isRicorrente: _parseBool(json['isRicorrente']),
      partecipanti: _parseMapList(json['partecipanti']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descrizione': descrizione,
      'importo': importo,
      'data': data.toIso8601String(),
      'dataScadenza': dataScadenza?.toIso8601String(),
      'isRicorrente': isRicorrente,
      'partecipanti': partecipanti,
    };
  }

  static double _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) {
      return null;
    }
    final parsed = _parseDate(value);
    if (parsed.millisecondsSinceEpoch == 0) {
      return null;
    }
    return parsed;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  static List<Map<String, dynamic>> _parseMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }
}
