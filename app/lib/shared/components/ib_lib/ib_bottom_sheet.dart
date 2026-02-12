import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBBottomSheet extends StatelessWidget {
  const IBBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryEnabled = true,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.secondaryEnabled = true,
    this.secondaryLoading = false,
    this.padding,
    this.showHandle = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => child,
    );
  }

  final String title;
  final String? subtitle;
  final Widget child;
  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool primaryEnabled;
  final bool primaryLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool secondaryEnabled;
  final bool secondaryLoading;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final resolvedPadding =
        padding ??
        EdgeInsets.only(
          left: 20,
          right: 20,
          top: showHandle ? 12 : 20,
          bottom: 20 + bottomInset,
        );
    final hasPrimary = primaryLabel != null;
    final hasSecondary = secondaryLabel != null;
    final hasActions = hasPrimary || hasSecondary;

    return Padding(
      padding: resolvedPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle) ...[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          IBText(title, context: context).subtitulo.build(),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            IBText(subtitle!, context: context).muted.build(),
          ],
          const SizedBox(height: 12),
          child,
          if (hasActions) ...[
            const SizedBox(height: 16),
            if (hasPrimary)
              IBButton(
                label: primaryLabel!,
                loading: primaryLoading,
                onPressed: primaryEnabled ? onPrimaryPressed : null,
                variant: IBButtonVariant.primary,
              ),
            if (hasSecondary) ...[
              const SizedBox(height: 8),
              IBButton(
                label: secondaryLabel!,
                loading: secondaryLoading,
                onPressed: secondaryEnabled ? onSecondaryPressed : null,
                variant: IBButtonVariant.secondary,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
