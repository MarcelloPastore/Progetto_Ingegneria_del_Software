class Inquilino {
  const Inquilino({required this.id, required this.nome, required this.email});

  final String id;
  final String nome;
  final String email;

  factory Inquilino.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['idInquilino'] ?? json['idUtente'];
    final nomeValue = json['nome'] ?? json['name'];
    final emailValue = json['email'] ?? json['mail'];

    return Inquilino(
      id: idValue?.toString() ?? '',
      nome: nomeValue?.toString() ?? '',
      email: emailValue?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'email': email};
  }
}
