class Quota {
  const Quota({
    required this.id,
    required this.importo,
    required this.pagata,
    required this.raw,
    this.utenteId = '',
    this.utenteNome = '',
  });

  final String id;
  final double importo;
  final bool pagata;
  final Map<String, dynamic> raw;
  final String utenteId;
  final String utenteNome;

  factory Quota.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['idQuota'];
    final importoValue =
        json['importo'] ?? json['amount'] ?? json['valore'] ?? json['quota'];
    final pagataValue =
        json['pagata'] ??
        json['pagato'] ??
        json['isPaid'] ??
        (json['dataPagamento'] != null);

    return Quota(
      id: idValue?.toString() ?? '',
      importo: _parseAmount(importoValue),
      pagata: _parseBool(pagataValue),
      raw: json,
      utenteId: _parseUserId(json),
      utenteNome: _parseUserName(json),
    );
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

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  static String _parseUserId(Map<String, dynamic> json) {
    final direct =
        json['utenteId'] ??
        json['idUtente'] ??
        json['inquilinoId'] ??
        json['idInquilino'];
    if (direct != null) {
      return direct.toString();
    }
    final utente = json['utente'] ?? json['inquilino'];
    if (utente is Map<String, dynamic>) {
      final id = utente['id'] ?? utente['idUtente'] ?? utente['userId'];
      return id?.toString() ?? '';
    }
    return '';
  }

  static String _parseUserName(Map<String, dynamic> json) {
    final direct =
        json['utenteNome'] ?? json['nome'] ?? json['username'] ?? json['email'];
    if (direct != null) {
      return direct.toString();
    }
    final utente = json['utente'] ?? json['inquilino'];
    if (utente is Map<String, dynamic>) {
      final name =
          utente['nome'] ??
          utente['name'] ??
          utente['username'] ??
          utente['email'];
      return name?.toString() ?? '';
    }
    return '';
  }
}
