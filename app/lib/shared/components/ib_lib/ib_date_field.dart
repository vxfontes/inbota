import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBDateField extends StatelessWidget {
  const IBDateField({
    super.key,
    required this.valueLabel,
    required this.enabled,
    required this.hasValue,
    required this.onTap,
    this.onClear,
    this.label = 'Data',
  });

  final String valueLabel;
  final bool enabled;
  final bool hasValue;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String label;

  @override
  Widget build(BuildContext context) {
    final contentColor = enabled ? AppColors.text : AppColors.textMuted;
    final iconColor = enabled ? AppColors.primary600 : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IBIcon(IBIcon.eventAvailableOutlined, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IBText(label, context: context).caption.build(),
                  const SizedBox(height: 2),
                  IBText(
                    valueLabel,
                    context: context,
                  ).body.color(contentColor).build(),
                ],
              ),
            ),
            if (hasValue && onClear != null)
              IconButton(
                tooltip: 'Limpar data',
                onPressed: enabled ? onClear : null,
                icon: const IBIcon(
                  IBIcon.closeRounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                splashRadius: 18,
              )
            else
              const IBIcon(
                IBIcon.chevronRight,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
