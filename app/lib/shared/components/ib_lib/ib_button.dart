import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

enum IBButtonVariant { primary, secondary, ghost }

class IBButton extends StatelessWidget {
  const IBButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = IBButtonVariant.primary,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IBButtonVariant variant;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    Widget content = IBText(label, context: context).label.build();
    if (loading) {
      content = const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (variant) {
      case IBButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary700,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary700.withAlpha((0.4 * 255).round()),
            disabledForegroundColor: Colors.white.withAlpha((0.85 * 255).round()),
          ),
          child: content,
        );
      case IBButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary600,
            backgroundColor: AppColors.primary600.withAlpha((0.08 * 255).round()),
            side: BorderSide(color: AppColors.primary600),
            disabledForegroundColor: AppColors.primary600.withAlpha((0.6 * 255).round()),
          ),
          child: content,
        );
      case IBButtonVariant.ghost:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary700,
            disabledForegroundColor: AppColors.primary700.withAlpha((0.6 * 255).round()),
          ),
          child: content,
        );
    }
  }
}
