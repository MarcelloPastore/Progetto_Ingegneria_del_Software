import 'package:flutter/material.dart';

import '../../utils/user_initials.dart';
import '../../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.userId,
    this.username,
    this.firstName,
    this.lastName,
    this.fullName,
    this.displayName,
    this.radius = AppSizes.radius18,
    this.fallback = '??',
    this.showPresenceDot = false,
    this.presenceDotColor = AppColors.statusNegative,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String? userId;
  /// Username is the primary display identifier; takes priority over name fields.
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? displayName;
  final double radius;
  final String fallback;
  final bool showPresenceDot;
  final Color presenceDotColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final seed = [
      userId?.trim() ?? '',
      username?.trim() ?? '',
      firstName?.trim() ?? '',
      lastName?.trim() ?? '',
      fullName?.trim() ?? '',
      displayName?.trim() ?? '',
    ].firstWhere((part) => part.isNotEmpty, orElse: () => '');

    final colors = userAvatarColorsForSeed(seed);

    // Username is the preferred source for initials; fall back to name fields.
    final resolvedUsername = username?.trim() ?? '';
    final initials = resolvedUsername.isNotEmpty
        ? initialsFromText(resolvedUsername)
        : resolveUserInitials(
            name: firstName,
            surname: lastName,
            displayName: fullName ?? displayName,
            fallback: fallback,
          );

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colors.background,
      child: Text(
        initials,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.85,
          height: 1,
        ),
      ),
    );

    if (borderColor != null && borderWidth > 0) {
      avatar = Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: avatar,
      );
    }

    if (!showPresenceDot) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: AppSizes.p2,
          right: AppSizes.p2,
          child: Container(
            width: radius * 0.42,
            height: radius * 0.42,
            decoration: BoxDecoration(
              color: presenceDotColor,
              borderRadius: BorderRadius.circular(AppSizes.radius99),
            ),
          ),
        ),
      ],
    );
  }
}
