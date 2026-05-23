class Spesa {
  const Spesa({
    required this.id,
    required this.descrizione,
    required this.importo,
    required this.data,
  });

  final String id;
  final String descrizione;
  final double importo;
  final DateTime data;

  factory Spesa.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['idSpesa'];
    final descrizioneValue =
        json['descrizione'] ?? json['titolo'] ?? json['nome'];
    final importoValue = json['importo'] ?? json['totale'] ?? json['amount'];
    final dataValue = json['data'] ?? json['dataSpesa'] ?? json['createdAt'];

    return Spesa(
      id: idValue?.toString() ?? '',
      descrizione: descrizioneValue?.toString() ?? '',
      importo: _parseAmount(importoValue),
      data: _parseDate(dataValue),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descrizione': descrizione,
      'importo': importo,
      'data': data.toIso8601String(),
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
}
