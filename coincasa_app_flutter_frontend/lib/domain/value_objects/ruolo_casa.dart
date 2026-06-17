/// Costanti e utility per i ruoli all'interno di una casa.
/// Unica fonte di verità per i valori stringa usati dal backend.
abstract final class RuoloCasa {
  static const homeAdmin = 'HomeAdmin';
  static const sysAdmin = 'SysAdmin';
  static const inquilino = 'Inquilino';

  static bool isAdmin(String? ruolo) =>
      ruolo == homeAdmin || ruolo == sysAdmin;
}
