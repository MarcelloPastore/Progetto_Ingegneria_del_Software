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

UserAvatarColors userAvatarColorsForSeed(String? seed) {
  final normalized = seed?.trim() ?? '';
  if (normalized.isEmpty) {
    return const UserAvatarColors(
      background: Color(0xFF3F33B8),
      foreground: Colors.white,
    );
  }

  final hash = normalized.hashCode & 0x7fffffff;
  final hue = (hash % 360).toDouble();
  final background = HSLColor.fromAHSL(
    1,
    hue,
    0.58,
    0.35 + ((hash >> 8) % 8) * 0.01,
  ).toColor();
  final foregroundHue = (hue + 42) % 360;
  final foreground = HSLColor.fromAHSL(
    1,
    foregroundHue.toDouble(),
    0.78,
    0.86,
  ).toColor();

  return UserAvatarColors(background: background, foreground: foreground);
}
