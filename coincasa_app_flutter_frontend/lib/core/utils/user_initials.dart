String initialsFromText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
  return trimmed.length >= 2
      ? trimmed.substring(0, 2).toUpperCase()
      : trimmed.substring(0, 1).toUpperCase();
}

String resolveUserInitials({
  String? displayName,
  String? email,
  String fallback = '??',
}) {
  final name = displayName?.trim() ?? '';
  if (name.isNotEmpty) {
    return initialsFromText(name);
  }

  final emailValue = email?.trim() ?? '';
  if (emailValue.isNotEmpty) {
    final prefix = emailValue.split('@').first.trim();
    if (prefix.isNotEmpty) {
      return initialsFromText(prefix);
    }
  }

  return fallback;
}
