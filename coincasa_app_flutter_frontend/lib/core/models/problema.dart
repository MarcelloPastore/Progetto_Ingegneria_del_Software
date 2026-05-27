class Problema {
  const Problema({
    required this.id,
    required this.titolo,
    required this.stato,
    required this.priorita,
    required this.raw,
  });

  final String id;
  final String titolo;
  final String stato;
  final String priorita;
  final Map<String, dynamic> raw;

  factory Problema.fromJson(Map<String, dynamic> json) {
    return Problema(
      id: (json['id'] ?? json['idProblema'] ?? '').toString(),
      titolo: (json['titolo'] ?? json['descrizione'] ?? json['nome'] ?? 'Problema')
          .toString(),
      stato: (json['stato'] ?? json['status'] ?? 'Segnalato').toString(),
      priorita: (json['priorita'] ?? json['priority'] ?? 'Media').toString(),
      raw: json,
    );
  }
}
