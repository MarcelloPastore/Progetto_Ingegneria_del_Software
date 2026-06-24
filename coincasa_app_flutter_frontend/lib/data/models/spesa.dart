class Spesa {
  Spesa({
    required this.id,
    required this.descrizione,
    required this.importo,
    required this.data,
    this.dataScadenza,
    this.isRicorrente = false,
    List<Map<String, dynamic>> partecipanti = const [],
    this.creatoreId = '',
    this.creatoreNome = '',
    this.idScadenza,
    Map<String, dynamic> raw = const {},
  }) : partecipanti = List.unmodifiable(
         partecipanti.map((item) => Map<String, dynamic>.unmodifiable(item)),
       ),
       raw = Map.unmodifiable(raw);

  final String id;
  final String descrizione;
  final double importo;
  final DateTime data;
  final DateTime? dataScadenza;
  final bool isRicorrente;
  final List<Map<String, dynamic>> partecipanti;
  final String creatoreId;
  final String creatoreNome;
  final String? idScadenza;
  final Map<String, dynamic> raw;

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
      creatoreId: _parseCreatorId(json),
      creatoreNome: _parseCreatorName(json),
      idScadenza: json['idScadenza']?.toString(),
      raw: json,
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
      'creatoreId': creatoreId,
      'creatoreNome': creatoreNome,
    };
  }

  bool isCreatedBy(String? userId) {
    if (userId == null || userId.trim().isEmpty || creatoreId.isEmpty) {
      return false;
    }
    return creatoreId == userId;
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

  static String _parseCreatorId(Map<String, dynamic> json) {
    final direct =
        json['creatoreId'] ??
        json['createdById'] ??
        json['ownerId'] ??
        json['utenteId'] ??
        json['idUtente'] ??
        json['pagatoreId'] ??
        json['idPagatore'];
    if (direct != null) {
      return direct.toString();
    }
    final creator =
        json['creatore'] ??
        json['createdBy'] ??
        json['owner'] ??
        json['pagatore'];
    if (creator is Map<String, dynamic>) {
      final id = creator['id'] ?? creator['idUtente'] ?? creator['userId'];
      return id?.toString() ?? '';
    }
    return '';
  }

  static String _parseCreatorName(Map<String, dynamic> json) {
    final direct =
        json['creatoreNome'] ??
        json['createdByName'] ??
        json['ownerName'] ??
        json['pagatoreNome'] ??
        json['pagatoDa'];
    if (direct != null) {
      return direct.toString();
    }
    final creator =
        json['creatore'] ??
        json['createdBy'] ??
        json['owner'] ??
        json['pagatore'];
    if (creator is Map<String, dynamic>) {
      final name =
          creator['username'] ??
          creator['nome'] ??
          creator['name'] ??
          creator['email'];
      return name?.toString() ?? '';
    }
    return '';
  }
}
