/// Costanti e sort order per le priorità di un problema.
abstract final class PrioritaProblema {
  static const urgente = 'Urgente';
  static const media = 'Media';
  static const bassa = 'Bassa';

  /// Indice di ordinamento: 0 = più urgente.
  static int sortIndex(String? priorita) => switch (priorita) {
        urgente => 0,
        media => 1,
        _ => 2,
      };
}
