class Casa {
  const Casa({
    required this.id,
    required this.nome,
    required this.indirizzo,
    this.citta = '',
    this.tipoCasa = '',
    this.inviteLink = '',
    this.inviteCode = '',
    this.ruolo = '',
  });

  final String id;
  final String nome;
  final String indirizzo;
  final String citta;
  final String tipoCasa;
  final String inviteLink;
  final String inviteCode;
  final String ruolo;

  factory Casa.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['idCasa'];
    final nomeValue = json['nome'] ?? json['name'];
    final indirizzoValue = json['indirizzo'] ?? json['address'];
    final cittaValue = json['citta'] ?? json['city'];
    final tipoCasaValue = json['tipoCasa'] ?? json['type'];
    final inviteLinkValue = json['inviteLink'] ?? json['link'];
    final inviteCodeValue = json['inviteCode'] ?? json['codiceInvito'];
    final ruoloValue = json['ruolo'] ?? json['role'];
    final inviteLinkText = inviteLinkValue?.toString() ?? '';

    return Casa(
      id: idValue?.toString() ?? '',
      nome: nomeValue?.toString() ?? '',
      indirizzo: indirizzoValue?.toString() ?? '',
      citta: cittaValue?.toString() ?? '',
      tipoCasa: tipoCasaValue?.toString() ?? '',
      inviteLink: inviteLinkText,
      inviteCode:
          inviteCodeValue?.toString() ?? _extractInviteCode(inviteLinkText),
      ruolo: ruoloValue?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'indirizzo': indirizzo,
      'citta': citta,
      'tipoCasa': tipoCasa,
      'inviteLink': inviteLink,
      'inviteCode': inviteCode,
      'ruolo': ruolo,
    };
  }

  static String _extractInviteCode(String inviteLink) {
    final normalized = inviteLink.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final separatorIndex = normalized.lastIndexOf('/');
    if (separatorIndex == -1 || separatorIndex == normalized.length - 1) {
      return normalized;
    }

    return normalized.substring(separatorIndex + 1);
  }
}
