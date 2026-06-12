import 'package:flutter/material.dart';

const _kSaveColor = Color(0xFF5228AD);
const _kSaveDisabledColor = Color(0xFF9D9D9D);
const _kCancelBgColor = Color(0xFF501C26);
const _kCancelBorderColor = Color(0xFFFF1744);
const _kCancelTextColor = Color(0xFFFF1744);

class FabSaveButton extends StatelessWidget {
  const FabSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kSaveColor,
          disabledBackgroundColor: _kSaveDisabledColor,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class FabCancelButton extends StatelessWidget {
  const FabCancelButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        height: 54,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: _kCancelBgColor,
            side: const BorderSide(color: _kCancelBorderColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Annulla',
            style: TextStyle(
              color: _kCancelTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
