class Casa {
  const Casa({required this.id, required this.nome, required this.indirizzo});

  final String id;
  final String nome;
  final String indirizzo;

  factory Casa.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['idCasa'];
    final nomeValue = json['nome'] ?? json['name'];
    final indirizzoValue = json['indirizzo'] ?? json['address'];

    return Casa(
      id: idValue?.toString() ?? '',
      nome: nomeValue?.toString() ?? '',
      indirizzo: indirizzoValue?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'indirizzo': indirizzo};
  }
}
