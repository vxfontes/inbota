import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class HomeDynamicHeader extends StatelessWidget {
  const HomeDynamicHeader({
    super.key,
    this.userName,
    required this.executiveSummary,
    required this.onSettingsTap,
    required this.onNotificationsTap,
  });

  final String? userName;
  final String executiveSummary;
  final VoidCallback onSettingsTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final greetingLabel = TextUtils.greetingWithOptionalName(
      greeting.label,
      name: userName,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        // gradient: greeting.gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IBText(greetingLabel, context: context).subtitulo.build(),
                    const SizedBox(height: 4),
                    IBText(
                      _formatPtDate(now),
                      context: context,
                    ).caption.build(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary700,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: IBText(
                    executiveSummary,
                    context: context,
                  ).body.color(AppColors.text).maxLines(2).build(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPtDate(DateTime date) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    const months = [
      'janeiro',
      'fevereiro',
      'marco',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} de $month';
  }

  _GreetingStyle _greetingForHour(int hour) {
    if (hour < 12) {
      return const _GreetingStyle(
        label: 'Bom dia',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6FAF8), AppColors.background],
        ),
      );
    }

    if (hour < 18) {
      return const _GreetingStyle(
        label: 'Boa tarde',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.background, AppColors.background],
        ),
      );
    }

    return const _GreetingStyle(
      label: 'Boa noite',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF7ED), AppColors.background],
      ),
    );
  }
}

class _GreetingStyle {
  const _GreetingStyle({required this.label, required this.gradient});

  final String label;
  final Gradient gradient;
}
