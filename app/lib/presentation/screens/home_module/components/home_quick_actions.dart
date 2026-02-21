import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomeQuickActionItem {
  const HomeQuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class HomeQuickActionsGrid extends StatelessWidget {
  const HomeQuickActionsGrid({super.key, required this.items});

  final List<HomeQuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.38,
      ),
      itemBuilder: (context, index) {
        return _QuickActionCard(item: items[index]);
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.item});

  final HomeQuickActionItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withAlpha((0.16 * 255).round()),
                AppColors.surface,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IBIcon(
                    item.icon,
                    color: item.color,
                    size: 18,
                    backgroundColor: item.color.withAlpha((0.16 * 255).round()),
                    borderColor: item.color.withAlpha((0.36 * 255).round()),
                    padding: const EdgeInsets.all(6),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  const Spacer(),
                  const IBIcon(
                    IBIcon.chevronRight,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              IBText(
                item.title,
                context: context,
              ).body.weight(FontWeight.w700).build(),
              const SizedBox(height: 4),
              IBText(
                item.subtitle,
                context: context,
              ).caption.maxLines(2).build(),
            ],
          ),
        ),
      ),
    );
  }
}
