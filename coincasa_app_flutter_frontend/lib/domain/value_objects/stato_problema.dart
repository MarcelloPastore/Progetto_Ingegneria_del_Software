/// Costanti e utility per gli stati del ciclo di vita di un problema.
abstract final class StatoProblema {
  static const segnalato = 'Segnalato';
  static const assegnato = 'Assegnato';
  static const risolto = 'Risolto';

  static bool isTerminale(String? stato) => stato == risolto;
  static bool isAssegnato(String? stato) => stato == assegnato;
  static bool isSegnalato(String? stato) => stato == segnalato;
}
