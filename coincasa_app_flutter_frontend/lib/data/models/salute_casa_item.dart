class SaluteCasaItem {
  const SaluteCasaItem({
    required this.id,
    required this.task,
    required this.giorniPassati,
    required this.cadenzaGiorni,
  });

  final String id;
  final String task;
  final int giorniPassati;
  final int cadenzaGiorni;

  int get giorniRimanenti => cadenzaGiorni - giorniPassati;

  factory SaluteCasaItem.fromJson(Map<String, dynamic> json) {
    return SaluteCasaItem(
      id: json['id']?.toString() ?? '',
      task: json['task']?.toString() ?? '',
      giorniPassati: _parseInt(json['giorniPassati']),
      cadenzaGiorni: _parseInt(json['cadenzaGiorni']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
