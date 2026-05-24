class Quota {
  const Quota({
    required this.id,
    required this.importo,
    required this.pagata,
    required this.raw,
  });

  final String id;
  final double importo;
  final bool pagata;
  final Map<String, dynamic> raw;

  factory Quota.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['idQuota'];
    final importoValue = json['importo'] ?? json['amount'] ?? json['valore'];
    final pagataValue = json['pagata'] ?? json['pagato'] ?? json['isPaid'];

    return Quota(
      id: idValue?.toString() ?? '',
      importo: _parseAmount(importoValue),
      pagata: _parseBool(pagataValue),
      raw: json,
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
}
