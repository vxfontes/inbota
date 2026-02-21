import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_chip.dart';
import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomeDayHeroStat {
  const HomeDayHeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class HomeDayHero extends StatelessWidget {
  const HomeDayHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completionRate,
    required this.completionLabel,
    required this.urgencyLabel,
    required this.urgencyColor,
    required this.stats,
  });

  final String title;
  final String subtitle;
  final double completionRate;
  final String completionLabel;
  final String urgencyLabel;
  final Color urgencyColor;
  final List<HomeDayHeroStat> stats;

  @override
  Widget build(BuildContext context) {
    final progress = completionRate.clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary700, AppColors.ai600],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withAlpha((0.16 * 255).round()),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.surface.withAlpha((0.9 * 255).round()),
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.surface.withAlpha((0.22 * 255).round()),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.surface),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  completionLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.surface.withAlpha((0.9 * 255).round()),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IBChip(label: urgencyLabel, color: urgencyColor),
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: stats
                  .map((item) => _HeroStatPill(stat: item))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({required this.stat});

  final HomeDayHeroStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha((0.16 * 255).round()),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surface.withAlpha((0.28 * 255).round()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IBIcon(stat.icon, color: stat.color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                stat.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.surface.withAlpha((0.85 * 255).round()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
