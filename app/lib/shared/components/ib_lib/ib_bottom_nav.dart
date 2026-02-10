import 'package:flutter/material.dart';

import 'package:inbota/shared/theme/app_colors.dart';

class IBBottomNav extends StatelessWidget {
  const IBBottomNav({
    super.key,
    this.currentIndex = 2,
    this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavIcon(
                    index: 0,
                    icon: Icons.inbox_rounded,
                    label: 'Inbox',
                    isActive: currentIndex == 0,
                    onTap: onTap,
                  ),
                  _NavIcon(
                    index: 1,
                    icon: Icons.alarm_rounded,
                    label: 'Lembretes',
                    isActive: currentIndex == 1,
                    onTap: onTap,
                  ),
                  const SizedBox(width: 56),
                  _NavIcon(
                    index: 3,
                    icon: Icons.shopping_bag_rounded,
                    label: 'Compras',
                    isActive: currentIndex == 3,
                    onTap: onTap,
                  ),
                  _NavIcon(
                    index: 4,
                    icon: Icons.event_rounded,
                    label: 'Eventos',
                    isActive: currentIndex == 4,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 28,
            child: _CenterAction(
              isActive: currentIndex == 2,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.index,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String label;
  final bool isActive;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary700 : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap?.call(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({required this.isActive, required this.onTap});

  final bool isActive;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () => onTap?.call(2),
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary700,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary700.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
