import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomeQuickAddBar extends StatelessWidget {
  const HomeQuickAddBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const IBIcon(
                IBIcon.autoAwesomeRounded,
                size: 18,
                color: AppColors.primary700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: IBText(
                  'O que voce quer organizar hoje?',
                  context: context,
                ).body.color(AppColors.textMuted).build(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
