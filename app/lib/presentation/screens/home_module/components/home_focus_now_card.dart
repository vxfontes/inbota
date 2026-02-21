import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_card.dart';
import 'package:inbota/shared/components/ib_lib/ib_chip.dart';
import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomeFocusNowEntry {
  const HomeFocusNowEntry({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;
}

class HomeFocusNowCard extends StatelessWidget {
  const HomeFocusNowCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String title;
  final String subtitle;
  final List<HomeFocusNowEntry> entries;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return IBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IBText(title, context: context).subtitulo.build(),
          const SizedBox(height: 4),
          IBText(subtitle, context: context).caption.build(),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            _EmptyState(title: emptyTitle, subtitle: emptySubtitle)
          else
            Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  _FocusRow(entry: entries[i]),
                  if (i != entries.length - 1)
                    const Divider(height: 18, color: AppColors.border),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({required this.entry});

  final HomeFocusNowEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBIcon(
          entry.icon,
          color: entry.color,
          size: 16,
          backgroundColor: entry.color.withAlpha((0.1 * 255).round()),
          borderColor: entry.color.withAlpha((0.3 * 255).round()),
          padding: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(11),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText(
                entry.title,
                context: context,
              ).body.weight(FontWeight.w700).maxLines(2).build(),
              const SizedBox(height: 3),
              IBText(
                entry.subtitle,
                context: context,
              ).caption.maxLines(2).build(),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IBChip(label: entry.category, color: entry.color),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surfaceSoft,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IBText(title, context: context).body.weight(FontWeight.w600).build(),
          const SizedBox(height: 4),
          IBText(subtitle, context: context).caption.build(),
        ],
      ),
    );
  }
}
