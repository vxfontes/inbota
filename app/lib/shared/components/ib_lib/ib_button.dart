import 'package:flutter/material.dart';

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

    Widget content = Text(label);
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
          child: content,
        );
      case IBButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          child: content,
        );
      case IBButtonVariant.ghost:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          child: content,
        );
    }
  }
}
