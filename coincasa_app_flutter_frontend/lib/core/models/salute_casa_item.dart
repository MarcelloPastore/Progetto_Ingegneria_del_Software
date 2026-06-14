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

  int get giorniRimanenti => cadenzaGiorni - giorniPassati - 1;

  factory SaluteCasaItem.fromJson(Map<String, dynamic> json) {
    return SaluteCasaItem(
      id: json['id'] as String,
      task: json['task'] as String,
      giorniPassati: json['giorniPassati'] as int,
      cadenzaGiorni: json['cadenzaGiorni'] as int,
    );
  }
}
