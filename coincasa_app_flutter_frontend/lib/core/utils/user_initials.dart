import 'package:flutter/material.dart';

String initialsFromText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return trimmed.length >= 2
      ? trimmed.substring(0, 2).toUpperCase()
      : trimmed.substring(0, 1).toUpperCase();
}

String initialsFromName({
  String? name,
  String? surname,
  String fallback = '??',
}) {
  final normalizedName = name?.trim() ?? '';
  final normalizedSurname = surname?.trim() ?? '';

  if (normalizedName.isNotEmpty && normalizedSurname.isNotEmpty) {
    return '${normalizedName[0]}${normalizedSurname[0]}'.toUpperCase();
  }

  final fullName = [
    normalizedName,
    normalizedSurname,
  ].where((part) => part.isNotEmpty).join(' ').trim();
  if (fullName.isNotEmpty) {
    return initialsFromText(fullName);
  }

  return fallback;
}

String resolveUserInitials({
  String? name,
  String? surname,
  String? displayName,
  String? email,
  String fallback = '??',
}) {
  final initials = initialsFromName(
    name: name,
    surname: surname,
    fallback: fallback,
  );
  if (initials != fallback) {
    return initials;
  }

  final displayValue = displayName?.trim() ?? '';
  if (displayValue.isNotEmpty) {
    return initialsFromText(displayValue);
  }

  return fallback;
}

@immutable
class UserAvatarColors {
  const UserAvatarColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

// 12 palette colors (Material 700) — visually distinct, all legible with white text
const List<Color> _avatarPalette = [
  Color(0xFF1976D2), // Blue 700
  Color(0xFF388E3C), // Green 700
  Color(0xFFC2185B), // Pink 700
  Color(0xFF00796B), // Teal 700
  Color(0xFF512DA8), // Deep Purple 700
  Color(0xFFD32F2F), // Red 700
  Color(0xFF0097A7), // Cyan 700
  Color(0xFF303F9F), // Indigo 700
  Color(0xFF5D4037), // Brown 700
  Color(0xFFF57C00), // Orange 700
  Color(0xFF455A64), // Blue Grey 700
  Color(0xFF558B2F), // Light Green 800
];

UserAvatarColors userAvatarColorsForSeed(String? seed) {
  final normalized = seed?.trim() ?? '';
  if (normalized.isEmpty) {
    return const UserAvatarColors(
      background: Color(0xFF303F9F),
      foreground: Colors.white,
    );
  }

  final hash = normalized.hashCode & 0x7fffffff;
  final background = _avatarPalette[hash % _avatarPalette.length];

  return UserAvatarColors(background: background, foreground: Colors.white);
}
