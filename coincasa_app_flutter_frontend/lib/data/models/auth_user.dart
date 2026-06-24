class AuthUser {
  final String id;
  final String username;
  final String nome;
  final String cognome;
  final String email;

  const AuthUser({
    required this.id,
    required this.username,
    required this.nome,
    required this.cognome,
    required this.email,
  });

  String get displayName {
    final parts = [nome, cognome].where((part) => part.trim().isNotEmpty);
    final fullName = parts.join(' ').trim();
    return fullName.isNotEmpty ? fullName : username;
  }
}
