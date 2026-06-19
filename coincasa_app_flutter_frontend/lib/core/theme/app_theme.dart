import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_sizes.dart';

export '../constants/app_sizes.dart';

/// Centralizzazione di tutti i colori del brand e dell'interfaccia.
/// Utilizzare preferibilmente via Theme.of(context).colorScheme.
abstract final class AppColors {
  // Brand Colors
  static const brandPrimary = Color(0xFF6436D1);
  static const brandPrimaryDark = Color(0xFF552EA8);
  static const brandSecondary = Color(0xFF8256E5);
  static const brandAccent = Color(0xFFAC86FC);
  static const focus = Color(0xFF9E86E3);
  static const primaryBorder = Color(0xFFB0A2F4);

  // Surface & Background
  static const transparent = Color(0x00000000);
  static const surface = Color(0xFFFFFFFF);
  static const pageBackground = Color(0xFFF6F5FB);
  static const darkBackground = Color(0xFF151127);
  static const surfaceDark = Color(0xFF151528);
  static const surfaceDarkElevated = Color(0xFF1F2848);
  static const surfaceDarkCard = Color(0xFF1E1A2D);
  static const surfaceDarkCardAlt = Color(0xFF211C35);
  static const surfaceDarkMuted = Color(0xFF2C2846);
  static const surfaceTint = Color(0xFFF1EBFF);
  static const badgeSurface = Color(0xFF202468);
  static const shadowStrong = Color(0x19000000);
  static const shadowSoft = Color(0x12000000);
  static const shadowMedium = Color(0x55000000);
  static const shadowOverlay = Color(0x3F000000);
  static const shadowPressed = Color(0x33000000);

  // Text Colors
  static const textPrimary = Color(0xFF1E1B2E);
  static const textSecondary = Color(0xFF5B5668);
  static const textMuted = Color(0xFF8D889C);
  static const textMutedLight = Color(0xFFC6C1CC);
  static const textMutedDark = Color(0xFF8C8CA0);
  static const textMutedSoft = Color(0xFFB0A9B8);
  static const textDisabled = Color(0xFFC1BFC8);
  static const textSubtle = Color(0xFFAFAEAE);
  static const textDim = Color(0xFF918D9A);
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnDarkMuted = Color(0xB3FFFFFF);

  // Form & Inputs
  static const inputFillDark = Color(0xFF171B35);
  static const inputBorder = Color(0xFFD6D2E6);
  static const inputBorderDark = Color(0xFFA7A9D8);
  static const dividerDark = Color(0xFF3B3B54);
  static const dividerOnDark = Color(0xFF3F4A72);
  static const borderMuted = Color(0xFF807D7D);
  static const borderSubtle = Color(0xFF77727F);

  // Status & Alerts
  static const error = Color(0xFFD32F2F);
  static const errorStrong = Color(0xFFFF333B);
  static const errorContainerDark = Color(0xFF3A0B0B);
  static const errorContainerStrong = Color(0xFF580300);
  static const warning = Color(0xFFFFC21A);
  static const warningSoft = Color(0xFFF9A825);
  static const warningDark = Color(0xFFC09A00);
  static const success = Color(0xFF2E7D32);
  static const successBright = Color(0xFF3EAE4F);
  static const info = Color(0xFF1565C0);

  // Semantic/Feature Status
  static const problemPriorityUrgent = Color(0xFFFF0005);
  static const problemPriorityMedium = Color(0xFFFF8D28);
  static const problemPriorityLow = Color(0xFFFFCC00);
  static const statusPositive = Color(0xFF5EEB64);
  static const statusNegative = Color(0xFFF75C6C);
  static const statusWarning = Color(0xFFF8A541);
  static const statusSuccess = Color(0xFF39B54A);
  static const statusInfo = Color(0xFF3E80FF);
  static const statusNeutral = Color(0xFFA77F74);
  static const balanceCredit = Color(0xFF47CC5D);
  static const balanceDebit = Color(0xFFF14A4A);

  // Priority chip backgrounds
  static const problemChipUrgentBg = Color(0xFF710002);
  static const problemChipMediumBg = Color(0xFF7E3B00);
  static const problemChipLowBg = Color(0xFF786000);

  // Assets/Illustration Colors
  static const keyYellow = Color(0xFFFFD31A);
  static const lockOrange = Color(0xFFFF9800);
  static const lockHole = Color(0xFFB86800);
  static const lockShackle = Color(0xFFB9B4C0);
  static const envelopeRed = Color(0xFFE84545);

  // Feature specific (Legacy/Migration)
  static const turniTabSurface = Color(0xFFE1E0E7);
  static const featureAccent = Color(0xFF996CFA);
  static const turniDropdownSelectedText = Color(0xFFD98DFF);
  static const turniAssigneeMenuSurface = Color(0xFF4B3A2B);
  static const turniAssignMeSurface = Color(0xFF214B23);
  static const turniAssigneeSurface = Color(0xFF5A4528);
  static const turniAssigneeDivider = Color(0xFF6D5435);
  static const turniAssigneeBorder = Color(0xFFFF8A1C);
  static const turniAssigneeSelectedSurface = Color(0xFF7B6B57);
}

/// Centralizzazione degli stili tipografici.
/// Da utilizzare preferibilmente tramite Theme.of(context).textTheme.
abstract final class AppTextStyles {
  static const brandTitle = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static const screenTitle = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static const screenTitleStrong = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );

  static const subtitle = TextStyle(color: AppColors.textOnDark, fontSize: 20);

  static const backHeader = TextStyle(
    color: AppColors.brandAccent,
    fontSize: 22,
    fontWeight: FontWeight.w500,
  );

  static const title = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const strongTitle = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 21,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    color: AppColors.textMutedLight,
    fontSize: 17,
    height: 1.14,
    fontWeight: FontWeight.w500,
  );

  static const bodyStrong = TextStyle(
    color: AppColors.textMutedLight,
    fontSize: 17,
    height: 1.12,
    fontWeight: FontWeight.w600,
  );

  static const bodyMuted = TextStyle(
    color: AppColors.textMutedDark,
    fontSize: 16,
  );

  static const bodyMutedLarge = TextStyle(
    color: AppColors.textMutedSoft,
    fontSize: 20,
    height: 1.18,
    fontWeight: FontWeight.w500,
  );

  static const bodyMutedRelaxed = TextStyle(
    color: AppColors.textMutedDark,
    fontSize: 16,
    height: 1.5,
  );

  static const label = TextStyle(
    color: AppColors.brandAccent,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const recoveryLabel = TextStyle(
    color: AppColors.brandAccent,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  static const input = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 19,
    fontWeight: FontWeight.w500,
  );

  static const inputCompact = TextStyle(color: AppColors.textOnDark);

  static const inputHint = TextStyle(
    color: AppColors.textMuted,
    fontSize: 19,
    fontWeight: FontWeight.w500,
  );

  static const button = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const buttonCompact = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const link = TextStyle(color: AppColors.brandAccent, fontSize: 16);

  static const linkStrong = TextStyle(
    color: AppColors.brandAccent,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const divider = TextStyle(
    color: AppColors.textMutedDark,
    fontSize: 14,
  );

  static const error = TextStyle(
    color: AppColors.errorStrong,
    fontSize: 15.5,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  static const errorCompact = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 13,
    height: 1.3,
  );

  static const fieldError = TextStyle(color: AppColors.error, fontSize: 11);

  static const dashboardHeaderTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const dashboardHeaderSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const dashboardSectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static const dashboardBalanceTitle = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const dashboardBalanceAmount = TextStyle(
    color: AppColors.statusNegative,
    fontSize: 48,
    fontWeight: FontWeight.w800,
  );

  static const dashboardCardLabel = TextStyle(
    color: AppColors.textMutedLight,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const dashboardCardPositiveValue = TextStyle(
    color: AppColors.statusPositive,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const dashboardCardNegativeValue = TextStyle(
    color: AppColors.statusNegative,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const dashboardListTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const dashboardListStatus = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const dashboardCardTitleOnDark = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const dashboardCardSubtitleOnDark = TextStyle(
    color: AppColors.textMutedLight,
    fontSize: 13,
  );

  static const dashboardSectionLink = TextStyle(
    color: AppColors.brandSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const dashboardProblemInitials = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
  );

  static const dashboardTurnInitials = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
  );

  static const dashboardBadgeLabel = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const dashboardBadgeCaption = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 12,
    height: 1,
  );

  static const dashboardCalendarWeekday = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const dashboardCalendarDay = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const dashboardLegendLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  );

  static const dashboardSectionMonth = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const priorityChipSelected = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 15,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.3,
  );

  static const priorityChipUnselected = TextStyle(
    color: AppColors.textOnDarkMuted,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}

/// Centralizzazione di tutti i gradienti dell'applicazione.
abstract final class AppGradients {
  // --- Brand & Purple Gradients ---

  /// Gradiente viola brand (da AppColors.brandAccent a AppColors.brandPrimary).
  static const brandPurple = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.brandAccent, AppColors.brandPrimary],
  );

  /// Gradiente viola primario (da Color(0xFF7B55E0) a Color(0xFF4A2BAE)).
  static const primaryPurple = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7B55E0), Color(0xFF4A2BAE)],
  );

  /// Gradiente a 3 stop per la conferma spesa in modifica spesa admin.
  static const spesaFormConfirm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF9B7FE8), Color(0xFF7B5DC8), Color(0xFF5C3FA8)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradiente a 2 stop per conferma/inserimento spesa membro.
  static const inserisciSpesaConfirm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF834BE0), Color(0xFF5526BA)],
  );

  /// Gradiente dinamico per il pulsante di logout.
  static final logoutButton = LinearGradient(
    begin: const Alignment(0.50, 0.00),
    end: const Alignment(0.50, 1.00),
    colors: [
      Color.lerp(const Color(0xFF6F4DBB), AppColors.brandPrimary, 0.15)!,
      AppColors.brandPrimary,
      const Color(0xFF5228AD),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // --- Other UI Gradients ---

  /// Gradiente blu per i pulsanti primari CTA.
  static const blueCta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5A7EEE), Color(0xFF2B5CE6), Color(0xFF2145B0)],
    stops: [0.0, 0.60, 1.0],
  );

  /// Gradiente per l'icona del globo nella schermata no connection.
  static const globeIcon = LinearGradient(
    colors: [Color(0xFF3E80FF), Color(0xFF8D8DFF), Color(0xFFE84545)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente di sfondo per l'icona wifi warning.
  static const wifiWarningBackground = LinearGradient(
    colors: [Color(0xFF2A1A5E), Color(0xFF3B1F7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente per l'icona wifi warning.
  static const wifiWarningIcon = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF7B61FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Divisore orizzontale sfumato per i dettagli dei problemi.
  static const horizontalDivider = LinearGradient(
    colors: [Color(0x00000000), Color(0x59AC86FC), Color(0x00000000)],
  );

  /// Gradiente dorato per il badge admin nella dashboard.
  static const goldBadge = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gradiente Instagram per la condivisione del codice invito.
  static const instagram = LinearGradient(
    colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  /// Gradiente di intestazione del form di creazione/modifica della casa.
  static const formHeaderBackground = LinearGradient(
    colors: [Color(0xFF21154C), Color(0xFF0F0A27)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradiente verde per le azioni di successo/assegnazione.
  static const greenAction = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
  );

  // --- Dynamic Helper Methods ---

  /// Helper per il gradiente dei chip di priorità.
  static LinearGradient priorityChip({
    required Color bgColor,
    bool isSelected = false,
  }) {
    final darkBg = Color.lerp(bgColor, Colors.black, 0.18)!;
    final topColor = Color.lerp(
      bgColor,
      Colors.white,
      isSelected ? 0.50 : 0.28,
    )!;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bgColor, darkBg],
      stops: const [0, 0.62, 1],
    );
  }

  /// Helper per il gradiente del pulsante di assegnazione turno "Assegna a me".
  static LinearGradient assignMeButton({
    required bool selected,
    required bool pressed,
  }) {
    Color topColor;
    Color bottomColor;
    if (pressed) {
      topColor = selected ? const Color(0xFF7BE47E) : const Color(0xFF77C879);
      bottomColor = selected
          ? const Color(0xFF2C7D34)
          : const Color(0xFF256A2D);
    } else {
      topColor = selected ? const Color(0xFF53C95B) : const Color(0xFF68B86C);
      bottomColor = selected
          ? const Color(0xFF2E9F3D)
          : const Color(0xFF2E7736);
    }
    return LinearGradient(
      colors: [topColor, bottomColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Helper per l'overlay bianco semi-trasparente (shimmer/overlay dei pulsanti).
  static LinearGradient whiteOverlay({double topAlpha = 0.18}) {
    return LinearGradient(
      begin: const Alignment(0.50, 0.00),
      end: const Alignment(0.50, 1.00),
      colors: [
        Colors.white.withValues(alpha: topAlpha),
        Colors.white.withValues(alpha: 0.00),
      ],
    );
  }

  /// Helper per creare un gradiente basato su un colore base con lerping standard.
  static LinearGradient buttonGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(baseColor, Colors.white, 0.30)!,
        baseColor,
        Color.lerp(baseColor, Colors.black, 0.18)!,
      ],
      stops: const [0, 0.62, 1],
    );
  }
}

/// Definizione dei temi dell'applicazione.
abstract final class AppTheme {
  /// ColorScheme per il tema chiaro mappato sui colori brand.
  static final ColorScheme lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.brandPrimary,
        onPrimary: AppColors.textOnDark,
        primaryContainer: AppColors.surfaceTint,
        onPrimaryContainer: AppColors.brandPrimaryDark,
        secondary: AppColors.brandSecondary,
        onSecondary: AppColors.textOnDark,
        tertiary: AppColors.brandAccent,
        onTertiary: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textOnDark,
        errorContainer: AppColors.errorContainerStrong,
        onErrorContainer: AppColors.textOnDark,
        surface: AppColors.pageBackground,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surface,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.inputBorder,
        shadow: AppColors.shadowSoft,
        inverseSurface: AppColors.darkBackground,
        onInverseSurface: AppColors.textOnDark,
      );

  /// ColorScheme per il tema scuro mappato sui colori brand.
  static final ColorScheme darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.brandAccent,
        onPrimary: AppColors.darkBackground,
        primaryContainer: AppColors.brandPrimaryDark,
        onPrimaryContainer: AppColors.brandAccent,
        secondary: AppColors.brandSecondary,
        onSecondary: AppColors.textOnDark,
        tertiary: AppColors.focus,
        onTertiary: AppColors.textOnDark,
        error: AppColors.errorStrong,
        onError: AppColors.textOnDark,
        errorContainer: AppColors.errorContainerDark,
        onErrorContainer: AppColors.textOnDark,
        surface: AppColors.darkBackground,
        onSurface: AppColors.textOnDark,
        surfaceContainerHighest: AppColors.surfaceDark,
        onSurfaceVariant: AppColors.textMutedSoft,
        outline: AppColors.inputBorderDark,
        shadow: AppColors.shadowStrong,
        inverseSurface: AppColors.pageBackground,
        onInverseSurface: AppColors.textPrimary,
      );

  static final TextTheme _textTheme = GoogleFonts.interTextTheme()
      .apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      )
      .copyWith(
        displayLarge: AppTextStyles.brandTitle,
        headlineLarge: AppTextStyles.screenTitle,
        headlineMedium: AppTextStyles.screenTitleStrong,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.strongTitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodyMuted,
        labelLarge: AppTextStyles.button,
      );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: lightColorScheme.surface,
    textTheme: _textTheme,
    pageTransitionsTheme: _pageTransitionsTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.surface,
      foregroundColor: lightColorScheme.onSurface,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      fillColor: lightColorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: lightColorScheme.onSurfaceVariant),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      border: _inputBorder(lightColorScheme.outline),
      enabledBorder: _inputBorder(lightColorScheme.outline),
      focusedBorder: _inputBorder(lightColorScheme.primary, width: 1.5),
      errorBorder: _inputBorder(lightColorScheme.error),
      focusedErrorBorder: _inputBorder(lightColorScheme.error, width: 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.onPrimary,
        padding: AppSizes.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: lightColorScheme.primary),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: darkColorScheme.surface,
    textTheme: _textTheme.apply(
      bodyColor: darkColorScheme.onSurface,
      displayColor: darkColorScheme.onSurface,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.surface,
      foregroundColor: darkColorScheme.onSurface,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkColorScheme.surfaceContainerHighest,
      border: _inputBorder(darkColorScheme.outline),
      enabledBorder: _inputBorder(darkColorScheme.outline),
      focusedBorder: _inputBorder(darkColorScheme.primary, width: 1.5),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _InstantPageTransition(),
      TargetPlatform.iOS: _InstantPageTransition(),
      TargetPlatform.windows: _InstantPageTransition(),
      TargetPlatform.macOS: _InstantPageTransition(),
      TargetPlatform.linux: _InstantPageTransition(),
      TargetPlatform.fuchsia: _InstantPageTransition(),
    },
  );
}

class _InstantPageTransition extends PageTransitionsBuilder {
  const _InstantPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
