import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

export 'auth_login_logo.dart';

class AuthRecoveryScaffold extends StatelessWidget {
  const AuthRecoveryScaffold({
    super.key,
    required this.child,
    this.padding = AppSizes.pageHorizontal,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: AppTheme.darkTheme,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.darkBackground,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBackHeader extends StatelessWidget {
  const AuthBackHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      onTap: onBack ?? () => Navigator.maybePop(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back, color: AppColors.brandAccent, size: 24),
          const SizedBox(width: AppSizes.p4),
          Text(title, style: AppTextStyles.backHeader),
        ],
      ),
    );
  }
}

enum AuthRecoveryBadgeIcon { key, email, lock }

class AuthRecoveryBadge extends StatelessWidget {
  const AuthRecoveryBadge({
    super.key,
    required this.icon,
    this.size = AppSizes.p100,
  });

  final AuthRecoveryBadgeIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.badgeSurface,
        shape: BoxShape.circle,
      ),
      child: Center(child: _buildIcon()),
    );
  }

  Widget _buildIcon() {
    switch (icon) {
      case AuthRecoveryBadgeIcon.key:
        return Transform.rotate(
          angle: -0.72,
          child: const Icon(
            Icons.key_rounded,
            color: AppColors.keyYellow,
            size: 58,
          ),
        );
      case AuthRecoveryBadgeIcon.email:
        return const Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _EnvelopeIcon(),
            Positioned(
              right: AppSizes.p15,
              bottom: AppSizes.p22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.successBright,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: AppSizes.p14,
                  height: AppSizes.p14,
                  child: Icon(Icons.check, color: Colors.white, size: 11),
                ),
              ),
            ),
          ],
        );
      case AuthRecoveryBadgeIcon.lock:
        return const _LockIcon();
    }
  }
}

class _EnvelopeIcon extends StatelessWidget {
  const _EnvelopeIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 46,
      child: CustomPaint(painter: _EnvelopePainter()),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final redPaint = Paint()
      ..color = AppColors.envelopeRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppSizes.radius5),
    );
    canvas.drawRRect(rect, bodyPaint);

    final flap = Path()
      ..moveTo(AppSizes.p4, AppSizes.p5)
      ..lineTo(size.width / 2, size.height * 0.56)
      ..lineTo(size.width - AppSizes.p4, AppSizes.p5);
    canvas.drawPath(flap, redPaint);

    final leftSide = Path()
      ..moveTo(AppSizes.p5, AppSizes.p6)
      ..lineTo(AppSizes.p5, size.height - AppSizes.p5);
    final rightSide = Path()
      ..moveTo(size.width - AppSizes.p5, AppSizes.p6)
      ..lineTo(size.width - AppSizes.p5, size.height - AppSizes.p5);
    canvas.drawPath(leftSide, redPaint);
    canvas.drawPath(rightSide, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LockIcon extends StatelessWidget {
  const _LockIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.p56,
      height: 62,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: AppSizes.p2,
            child: Container(
              width: AppSizes.p28,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lockShackle, width: 5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radius16),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: AppSizes.p2,
            child: Container(
              width: 42,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.lockOrange,
                borderRadius: BorderRadius.circular(AppSizes.radius5),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.lockHole,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    this.margin = AppSizes.zero,
    this.onAction,
    this.actionText,
    this.trailingMessage,
    this.compact = false,
  });

  final String message;
  final EdgeInsets margin;
  final VoidCallback? onAction;
  final String? actionText;
  final String? trailingMessage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: compact
          ? const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p12,
            )
          : const EdgeInsets.fromLTRB(
              AppSizes.p18,
              AppSizes.p13,
              AppSizes.p16,
              AppSizes.p13,
            ),
      decoration: BoxDecoration(
        color: compact
            ? AppColors.errorContainerDark
            : AppColors.errorContainerStrong,
        border: Border.all(
          color: compact ? AppColors.error : AppColors.errorStrong,
          width: compact ? 1.5 : 2.5,
        ),
        borderRadius: BorderRadius.circular(
          compact ? AppSizes.radius12 : AppSizes.radius13,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.p4),
            child: Icon(
              Icons.warning_rounded,
              color: compact ? AppColors.warningSoft : AppColors.warning,
              size: compact ? 27 : 25,
            ),
          ),
          const SizedBox(width: AppSizes.p14),
          Expanded(child: _messageText()),
        ],
      ),
    );
  }

  Widget _messageText() {
    if (actionText == null || onAction == null) {
      return Text(
        message,
        style: compact ? AppTextStyles.errorCompact : AppTextStyles.error,
      );
    }

    return Wrap(
      children: [
        Text(
          message,
          style: compact ? AppTextStyles.errorCompact : AppTextStyles.error,
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText!,
            style: AppTextStyles.link.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        if (trailingMessage != null)
          Text(
            trailingMessage!,
            style: compact ? AppTextStyles.errorCompact : AppTextStyles.error,
          ),
      ],
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.hasError = false,
    this.height = 44,
    this.labelBottomSpacing = AppSizes.p2,
    this.suffixIcon,
    this.errorText,
    this.contentPadding = AppSizes.inputContent,
    this.recoveryStyle = true,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final bool hasError;
  final double height;
  final double labelBottomSpacing;
  final Widget? suffixIcon;
  final String? errorText;
  final EdgeInsets contentPadding;
  final bool recoveryStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: errorText == null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: recoveryStyle
                ? AppTextStyles.recoveryLabel
                : AppTextStyles.label,
          ),
        ),
        SizedBox(height: labelBottomSpacing),
        SizedBox(
          height: height,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style:
                (recoveryStyle
                        ? AppTextStyles.input
                        : AppTextStyles.inputCompact)
                    .copyWith(color: AppColors.textOnDark),
            cursorColor: AppColors.focus,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: recoveryStyle
                  ? AppTextStyles.inputHint
                  : TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: recoveryStyle
                  ? AppColors.inputFillDark
                  : Colors.transparent,
              contentPadding: contentPadding,
              enabledBorder: _border(hasError),
              focusedBorder: _border(hasError, focused: true),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSizes.p4,
              right: AppSizes.p4,
            ),
            child: Text(errorText!, style: AppTextStyles.fieldError),
          ),
      ],
    );
  }

  OutlineInputBorder _border(bool hasError, {bool focused = false}) {
    final color = hasError
        ? AppColors.error
        : focused
        ? AppColors.focus
        : recoveryStyle
        ? AppColors.inputBorderDark
        : AppColors.dividerDark;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        recoveryStyle ? AppSizes.radius14 : AppSizes.radius12,
      ),
      borderSide: BorderSide(color: color, width: hasError ? 2 : 1.5),
    );
  }
}

class AuthPasswordToggle extends StatelessWidget {
  const AuthPasswordToggle({
    super.key,
    required this.obscured,
    required this.onTap,
    this.compact = false,
  });

  final bool obscured;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: compact
            ? const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p10,
              )
            : AppSizes.inputContentTall,
        child: Text(
          obscured ? 'Mostra' : 'Nascondi',
          style: AppTextStyles.link.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.compact = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? AppSizes.p56 : AppSizes.p56,
      child: ElevatedButton(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: compact
              ? AppColors.brandPrimaryDark
              : AppColors.brandPrimary,
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              compact ? AppSizes.radius16 : AppSizes.radius15,
            ),
            side: compact
                ? BorderSide.none
                : const BorderSide(color: AppColors.primaryBorder, width: 2),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: compact ? AppTextStyles.buttonCompact : AppTextStyles.button,
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.dividerDark, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: Text('oppure', style: AppTextStyles.divider),
        ),
        Expanded(child: Divider(color: AppColors.dividerDark, thickness: 1)),
      ],
    );
  }
}

class VerificationCodeBox extends StatelessWidget {
  const VerificationCodeBox({super.key, this.hasError = false});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 102,
      decoration: BoxDecoration(
        color: AppColors.inputFillDark,
        border: Border.all(
          color: hasError ? AppColors.errorStrong : AppColors.inputBorderDark,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          6,
          (_) => Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.p2),
            ),
          ),
        ),
      ),
    );
  }
}

class RecoveryProgressDots extends StatelessWidget {
  const RecoveryProgressDots({super.key, this.activeIndex = 0});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6),
          child: Container(
            width: AppSizes.p14,
            height: AppSizes.p14,
            decoration: BoxDecoration(
              color: index == activeIndex
                  ? AppColors.brandPrimary
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPageDots extends StatelessWidget {
  const AuthPageDots({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
          child: Container(
            width: index == activeIndex ? AppSizes.p12 : AppSizes.p8,
            height: AppSizes.p8,
            decoration: BoxDecoration(
              color: index == activeIndex
                  ? AppColors.brandAccent
                  : AppColors.textMutedDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSizes.radius4),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthRegisterFields extends StatelessWidget {
  const AuthRegisterFields({
    super.key,
    required this.hasError,
    required this.passwordHasError,
    required this.confirmPasswordHasError,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.usernameController,
    required this.nomeController,
    required this.cognomeController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    this.confirmPasswordErrorText,
  });

  final bool hasError;
  final bool passwordHasError;
  final bool confirmPasswordHasError;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final TextEditingController usernameController;
  final TextEditingController nomeController;
  final TextEditingController cognomeController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final String? confirmPasswordErrorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _field('Nome Utente', 'Marco_Rossi', usernameController),
        _field('Nome', 'Marco', nomeController),
        _field('Cognome', 'Rossi', cognomeController),
        _field('Email', 'marco@gmail.com', emailController),
        _field(
          'Password',
          '••••••••',
          passwordController,
          obscureText: obscurePassword,
          fieldHasError: passwordHasError,
          suffixIcon: AuthPasswordToggle(
            compact: true,
            obscured: obscurePassword,
            onTap: onTogglePassword,
          ),
        ),
        _field(
          'Conferma password',
          '••••••••',
          confirmPasswordController,
          obscureText: obscureConfirmPassword,
          fieldHasError: confirmPasswordHasError,
          errorText: confirmPasswordErrorText,
          suffixIcon: AuthPasswordToggle(
            compact: true,
            obscured: obscureConfirmPassword,
            onTap: onToggleConfirmPassword,
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    bool? fieldHasError,
  }) {
    final effectiveError = fieldHasError ?? hasError;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12),
      child: AuthField(
        label: label,
        hint: hint,
        controller: controller,
        obscureText: obscureText,
        suffixIcon: suffixIcon,
        hasError: effectiveError,
        errorText:
            errorText ?? (effectiveError ? 'Campo obbligatorio *' : null),
        recoveryStyle: false,
        labelBottomSpacing: AppSizes.p8,
      ),
    );
  }
}
