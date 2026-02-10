import 'package:flutter/material.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBAppBar extends StatelessWidget implements PreferredSizeWidget {
  const IBAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      elevation: 0,
      backgroundColor: AppColors.transparent,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary700,
                AppColors.primary600,
                AppColors.primary500,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
