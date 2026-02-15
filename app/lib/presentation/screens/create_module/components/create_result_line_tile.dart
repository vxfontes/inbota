import 'package:flutter/material.dart';
import 'package:inbota/presentation/screens/create_module/controller/create_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class CreateResultLineTile extends StatelessWidget {
  const CreateResultLineTile({super.key, required this.result});

  final CreateLineResult result;

  @override
  Widget build(BuildContext context) {
    final success = result.status == CreateLineStatus.success;
    final color = success ? AppColors.success600 : AppColors.danger600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IBIcon(
                success ? IBIcon.checkRounded : IBIcon.closeRounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: IBText(
                  result.message,
                  context: context,
                ).label.color(color).build(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          IBText(
            result.sourceText,
            context: context,
          ).caption.maxLines(3).build(),
        ],
      ),
    );
  }
}
