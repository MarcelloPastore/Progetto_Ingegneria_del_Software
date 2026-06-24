/// Centralized Italian formatting utilities for currency, dates, and months.
///
/// Import this instead of defining _formatCurrency / _formatDate locally.
library;

/// "€1,50" — uses Italian decimal comma
String formatCurrency(double value) =>
    '€${value.toStringAsFixed(2).replaceAll('.', ',')}';

/// "15 gen 2024"
String formatLongDate(DateTime date) =>
    '${date.day} ${monthShort(date.month)} ${date.year}';

/// "15 gennaio 2024" (full month name)
String formatFullDate(DateTime date) =>
    '${date.day} ${monthName(date.month)} ${date.year}';

/// "15/06/2024"
String formatShortDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

/// Full Italian month name in lowercase: "gennaio"
String monthName(int month) => const [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
][month - 1];

/// Abbreviated Italian month in lowercase: "gen"
String monthShort(int month) => const [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
][month - 1];
