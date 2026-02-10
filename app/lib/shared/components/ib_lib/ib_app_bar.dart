import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final EdgeInsetsGeometry? padding;

  const IBAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.padding,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Padding(
        padding: padding ?? const EdgeInsets.all(0),
        child: IBText(title, context: context).titulo.color(AppColors.surface2).build(),
      ),
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
