import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_controller.dart';
import 'package:inbota/shared/components/ib_lib/ib_app_bar.dart';
import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/components/ib_lib/ib_menu_card.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends IBState<SettingsPage, SettingsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IBLightAppBar(title: 'Configurações'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IBText('Configurações', context: context).subtitulo.build(),
              const SizedBox(height: 12),
              IBMenuCard(
                items: [
                  IBMenuItem(
                    title: 'Conta',
                    subtitle: 'Dados pessoais e segurança',
                    icon: IBIcon.personOutline,
                    onTap: () {},
                  ),
                  IBMenuItem(
                    title: 'Notificações',
                    subtitle: 'Lembretes e alertas',
                    icon: IBIcon.notificationsNoneOutlined,
                    onTap: () {},
                  ),
                  IBMenuItem(
                    title: 'Preferências',
                    subtitle: 'Idioma e aparência',
                    icon: IBIcon.tune,
                    onTap: () {},
                  ),
                  IBMenuItem(
                    title: 'Componentes',
                    subtitle: 'Biblioteca visual',
                    icon: IBIcon.gridViewRounded,
                    onTap: () => AppNavigation.push(AppRoutes.settingsComponents),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              IBText('Suporte', context: context).subtitulo.build(),
              const SizedBox(height: 12),
              IBMenuCard(
                items: [
                  IBMenuItem(
                    title: 'Central de ajuda',
                    subtitle: 'Perguntas frequentes',
                    icon: IBIcon.helpOutline,
                    onTap: () {},
                    iconColor: AppColors.ai600,
                  ),
                  IBMenuItem(
                    title: 'Privacidade',
                    subtitle: 'Termos e políticas',
                    icon: IBIcon.privacyTipOutlined,
                    onTap: () {},
                    iconColor: AppColors.ai600,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ValueListenableBuilder<bool>(
                valueListenable: controller.loading,
                builder: (context, loading, _) {
                  return IBButton(
                    label: 'Sair',
                    loading: loading,
                    onPressed: () async => await controller.logout(),
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
