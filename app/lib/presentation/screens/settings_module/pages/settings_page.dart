import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_controller.dart';
import 'package:inbota/shared/components/ib_lib/ib_app_bar.dart';
import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends IBState<SettingsPage, SettingsController> {
  Future<void> _logout() async {
    final success = await controller.logout();
    if (!success || !mounted) return;
    AppNavigation.clearAndPush(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IBLightAppBar(title: 'Configurações'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IBText('Conta', context: context).subtitulo.build(),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: controller.loading,
                builder: (context, loading, _) {
                  return IBButton(
                    label: 'Sair',
                    loading: loading,
                    onPressed: _logout,
                    variant: IBButtonVariant.secondary,
                  );
                },
              ),
              ValueListenableBuilder<String?>(
                valueListenable: controller.error,
                builder: (context, error, _) {
                  if (error == null || error.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: IBText(error, context: context)
                        .caption
                        .color(AppColors.danger600)
                        .build(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
