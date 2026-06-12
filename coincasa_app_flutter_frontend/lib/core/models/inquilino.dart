class Inquilino {
  const Inquilino({
    required this.id,
    required this.nome,
    required this.email,
    this.cognome = '',
    this.username = '',
    this.ruolo = '',
    this.isOwner = false,
    this.dataIngresso,
  });

  final String id;
  final String nome;
  final String email;
  final String cognome;
  final String username;
  final String ruolo;
  final bool isOwner;
  final DateTime? dataIngresso;

  String get nomeCompleto {
    final parts = [nome, cognome].where((part) => part.trim().isNotEmpty);
    final fullName = parts.join(' ').trim();
    return fullName.isEmpty ? username : fullName;
  }

  bool get isHomeAdmin => ruolo == 'HomeAdmin' || ruolo == 'SysAdmin';

  factory Inquilino.fromJson(Map<String, dynamic> json) {
    // Il backend nidifica i dati anagrafici sotto la chiave 'utente'.
    final utente = json['utente'] as Map<String, dynamic>?;
    final idValue = utente?['id'] ?? json['id'] ?? json['idInquilino'] ?? json['idUtente'];
    final nomeValue = utente?['nome'] ?? json['nome'] ?? json['name'];
    final cognomeValue = utente?['cognome'] ?? json['cognome'] ?? json['surname'];
    final usernameValue = utente?['username'] ?? json['username'];
    final emailValue = utente?['email'] ?? json['email'] ?? json['mail'];
    final ruoloValue = json['ruolo'] ?? json['role'];
    final dataIngressoValue = json['dataIngresso'] ?? json['joinedAt'];
    final isOwnerValue = json['isOwner'] ?? false;

    return Inquilino(
      id: idValue?.toString() ?? '',
      nome: nomeValue?.toString() ?? '',
      email: emailValue?.toString() ?? '',
      cognome: cognomeValue?.toString() ?? '',
      username: usernameValue?.toString() ?? '',
      ruolo: ruoloValue?.toString() ?? '',
      isOwner: isOwnerValue == true,
      dataIngresso: dataIngressoValue == null
          ? null
          : DateTime.tryParse(dataIngressoValue.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'username': username,
      'email': email,
      'ruolo': ruolo,
      'isOwner': isOwner,
      'dataIngresso': dataIngresso?.toIso8601String(),
    };
  }
}
