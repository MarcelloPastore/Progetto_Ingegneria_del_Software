import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_client.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/casa/screens/casa_pre_schermata_hub_casa.dart';

final inviteCodeEntryControllerProvider =
    StateNotifierProvider.autoDispose<
      InviteCodeEntryController,
      InviteCodeEntryState
    >((ref) => InviteCodeEntryController());

@immutable
class InviteCodeEntryState {
  const InviteCodeEntryState({
    this.code = '',
    this.isSubmitting = false,
    this.errorText,
    this.showInvalidInviteCode = false,
  });

  final String code;
  final bool isSubmitting;
  final String? errorText;
  final bool showInvalidInviteCode;

  bool get canSubmit => code.trim().isNotEmpty && !isSubmitting;
  bool get hasError => errorText != null || showInvalidInviteCode;

  InviteCodeEntryState copyWith({
    String? code,
    bool? isSubmitting,
    String? errorText,
    bool? showInvalidInviteCode,
    bool clearError = false,
  }) {
    return InviteCodeEntryState(
      code: code ?? this.code,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorText: clearError ? null : errorText ?? this.errorText,
      showInvalidInviteCode: clearError
          ? false
          : showInvalidInviteCode ?? this.showInvalidInviteCode,
    );
  }
}

class InviteCodeEntryController extends StateNotifier<InviteCodeEntryState> {
  InviteCodeEntryController() : super(const InviteCodeEntryState());

  static final RegExp _inviteCodePattern = RegExp(r'^CX-[A-Z0-9]{8}$');

  void codeChanged(String value) {
    state = state.copyWith(code: _normalizeCode(value), clearError: true);
  }

  Future<Casa?> verifyCode() async {
    final normalizedCode = _normalizeCode(state.code);
    if (!_inviteCodePattern.hasMatch(normalizedCode)) {
      state = state.copyWith(
        code: normalizedCode,
        errorText: 'Inserisci un codice nel formato CX-MDLE4H58',
      );
      return null;
    }

    state = state.copyWith(
      code: normalizedCode,
      isSubmitting: true,
      clearError: true,
    );

    try {
      final casa = await ApiProvider.casa.joinWithInviteCode(normalizedCode);
      state = state.copyWith(isSubmitting: false, clearError: true);
      return casa;
    } on ApiException catch (error) {
      if (error.statusCode == 403) {
        state = state.copyWith(
          isSubmitting: false,
          showInvalidInviteCode: true,
        );
        return null;
      }

      if (error.statusCode == 404) {
        state = state.copyWith(
          isSubmitting: false,
          errorText:
              'Servizio invito non disponibile. Riavvia il backend e riprova.',
        );
        return null;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorText: 'Non e possibile verificare il codice. Riprova piu tardi.',
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorText: 'Non e possibile verificare il codice. Riprova piu tardi.',
      );
      return null;
    }
  }

  String _normalizeCode(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }
}

class EntraConCodiceInvitoScreen extends ConsumerStatefulWidget {
  const EntraConCodiceInvitoScreen({super.key});

  @override
  ConsumerState<EntraConCodiceInvitoScreen> createState() =>
      _EntraConCodiceInvitoScreenState();
}

class _EntraConCodiceInvitoScreenState
    extends ConsumerState<EntraConCodiceInvitoScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    final casa = await ref
        .read(inviteCodeEntryControllerProvider.notifier)
        .verifyCode();

    if (!mounted || casa == null) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CasaPreSchermataHubCasaScreen(
          houseName: casa.nome,
          houseType: casa.tipoCasa,
          city: casa.citta,
          casaId: casa.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(inviteCodeEntryControllerProvider, (previous, next) {
      if (_codeController.text != next.code) {
        _codeController.value = TextEditingValue(
          text: next.code,
          selection: TextSelection.collapsed(offset: next.code.length),
        );
      }
    });

    final state = ref.watch(inviteCodeEntryControllerProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.p20,
                      AppSizes.p18,
                      AppSizes.p20,
                      AppSizes.p24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _InviteCodeHeader(),
                        SizedBox(height: constraints.maxHeight * 0.07),
                        const _KeyBadge(),
                        const SizedBox(height: AppSizes.p25),
                        const Text(
                          'Codice Invito',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p18),
                        _CodeFieldLabel(hasError: state.hasError),
                        const SizedBox(height: AppSizes.p17),
                        _InviteCodeTextField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          hasError: state.hasError,
                          onChanged: ref
                              .read(inviteCodeEntryControllerProvider.notifier)
                              .codeChanged,
                          onSubmitted: state.canSubmit ? _verifyCode : null,
                        ),
                        if (state.showInvalidInviteCode) ...[
                          const SizedBox(height: AppSizes.p14),
                          const _InlineInviteError(
                            message: 'Codice non trovato o scaduto',
                          ),
                        ] else if (state.errorText != null) ...[
                          const SizedBox(height: AppSizes.p10),
                          Text(
                            state.errorText!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.error.copyWith(fontSize: 13),
                          ),
                        ],
                        if (state.showInvalidInviteCode) ...[
                          const SizedBox(height: AppSizes.p22),
                          const _InvalidInviteCodePanel(),
                        ],
                        const SizedBox(height: AppSizes.p27),
                        _InviteCodeButton(
                          label: state.showInvalidInviteCode
                              ? 'Riprova'
                              : 'Verifica codice',
                          filled: true,
                          isLoading: state.isSubmitting,
                          onPressed: state.canSubmit ? _verifyCode : null,
                        ),
                        const SizedBox(height: AppSizes.p16),
                        _InviteCodeButton(
                          label: 'Annulla',
                          filled: false,
                          onPressed: Navigator.of(context).pop,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InviteCodeHeader extends StatelessWidget {
  const _InviteCodeHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.p40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: AppSizes.p0,
            child: IconButton(
              tooltip: 'Indietro',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: AppSizes.p40,
                height: AppSizes.p40,
              ),
              alignment: Alignment.centerLeft,
              onPressed: Navigator.of(context).pop,
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.brandAccent,
                size: AppSizes.p28,
              ),
            ),
          ),
          const Text(
            'Entra con codice',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  const _KeyBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSizes.p100,
        height: AppSizes.p100,
        decoration: const BoxDecoration(
          color: AppColors.badgeSurface,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.vpn_key,
          color: AppColors.keyYellow,
          size: AppSizes.p58,
        ),
      ),
    );
  }
}

class _CodeFieldLabel extends StatelessWidget {
  const _CodeFieldLabel({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final labelColor = hasError
        ? AppColors.errorStrong
        : AppColors.textMutedLight;

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: labelColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          children: [
            const TextSpan(text: 'Codice '),
            const TextSpan(
              text: '*',
              style: TextStyle(
                color: AppColors.errorStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeTextField extends StatelessWidget {
  const _InviteCodeTextField({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.errorStrong
        : AppColors.inputBorderDark;
    final fillColor = hasError
        ? AppColors.errorContainerDark
        : AppColors.inputFillDark;

    return SizedBox(
      height: AppSizes.p58,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        keyboardType: TextInputType.text,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-\s]')),
          LengthLimitingTextInputFormatter(11),
        ],
        style: const TextStyle(
          color: AppColors.textOnDark,
          fontSize: 28,
          letterSpacing: 5,
          fontWeight: FontWeight.w900,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          hintText: 'CX-MDLE4H58',
          hintStyle: TextStyle(
            color: AppColors.textOnDark.withValues(alpha: 0.45),
            fontSize: 28,
            letterSpacing: 5,
            fontWeight: FontWeight.w900,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p18,
            vertical: AppSizes.p12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            borderSide: const BorderSide(
              color: AppColors.primaryBorder,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineInviteError extends StatelessWidget {
  const _InlineInviteError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSizes.p20,
          height: AppSizes.p20,
          decoration: const BoxDecoration(
            color: AppColors.errorStrong,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '!',
              style: TextStyle(
                color: AppColors.darkBackground,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.errorStrong,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvalidInviteCodePanel extends StatelessWidget {
  const _InvalidInviteCodePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p18,
        AppSizes.p12,
        AppSizes.p18,
        AppSizes.p16,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorContainerStrong.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(color: AppColors.errorStrong, width: 2),
      ),
      child: const Column(
        children: [
          Text(
            'Codice non valido',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.errorStrong,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSizes.p10),
          Text(
            'Richiedi un nuovo codice\nall\'amministratore della casa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeButton extends StatelessWidget {
  const _InviteCodeButton({
    required this.label,
    required this.filled,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final bool filled;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: AppSizes.p58,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: AppColors.textOnDark,
            disabledBackgroundColor: AppColors.brandPrimary.withValues(
              alpha: 0.55,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius15),
              side: const BorderSide(color: AppColors.primaryBorder, width: 2),
            ),
          ),
          child: _ButtonContent(label: label, isLoading: isLoading),
        ),
      );
    }

    return SizedBox(
      height: AppSizes.p58,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textOnDark,
          side: const BorderSide(color: AppColors.primaryBorder, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius15),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.button,
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, required this.isLoading});

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.button,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: AppSizes.p20,
          height: AppSizes.p20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.button,
        ),
      ],
    );
  }
}
