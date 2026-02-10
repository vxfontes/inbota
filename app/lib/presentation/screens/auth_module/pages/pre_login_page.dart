import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class PreLoginPage extends StatelessWidget {
  const PreLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroCard(constraints: constraints),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          IBText('Sua rotina mais leve', context: context)
                              .titulo
                              .align(TextAlign.center)
                              .build(),
                          const SizedBox(height: 12),
                          IBText(
                            'Organize tarefas, lembretes e projetos em um só lugar com a ajuda da IA.',
                            context: context,
                          ).muted.align(TextAlign.center).build(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IBButton(
                            label: 'Começar',
                            onPressed: () => AppNavigation.push(AppRoutes.signup),
                          ),
                          IBButton(
                            label: 'Já tenho conta',
                            onPressed: () => AppNavigation.push(AppRoutes.login),
                            variant: IBButtonVariant.ghost,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.constraints});

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final height = constraints.maxHeight * 0.48;
    return SizedBox(
      height: height.clamp(360, 360),
      child: Stack(
        children: [
          const _Dot(color: AppColors.ai600, top: 20, left: 24, size: 10),
          const _Dot(color: AppColors.warning500, top: 36, right: 32, size: 8),
          const _Dot(color: AppColors.success600, bottom: 38, left: 42, size: 8),
          const _Dot(color: AppColors.primary500, bottom: 28, right: 40, size: 12),
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              'assets/app_icon.png',
              width: 300,
              height: 300,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final Color color;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha((0.6 * 255).round()),
        ),
      ),
    );
  }
}
