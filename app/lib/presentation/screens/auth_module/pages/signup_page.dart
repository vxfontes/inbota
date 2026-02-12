import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/auth_module/controller/signup_controller.dart';
import 'package:inbota/presentation/screens/auth_module/components/auth_form_scaffold.dart';
import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/components/ib_lib/ib_text_field.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends IBState<SignupPage, SignupController> {
  Future<void> _submit() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    final timezone = DateTime.now().timeZoneName;
    final success = await controller.submit(locale: locale, timezone: timezone);
    if (!success || !mounted) return;
    AppNavigation.clearAndPush(AppRoutes.rootHome);
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      header: Image.asset(
        'assets/app_icon.png',
        width: 64,
        height: 64,
      ),
      title: 'Criar conta',
      subtitle: 'Monte sua rotina inteligente em poucos passos.',
      fields: [
        IBTextField(
          label: 'Nome completo',
          hint: 'Como podemos te chamar?',
          prefixIcon: const IBIcon(IBIcon.personOutline, color: AppColors.textMuted),
          controller: controller.nameController,
        ),
        const SizedBox(height: 16),
        IBTextField(
          label: 'Email',
          hint: 'voce@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const IBIcon(IBIcon.mailOutline, color: AppColors.textMuted),
          controller: controller.emailController,
        ),
        const SizedBox(height: 16),
        IBTextField(
          label: 'Senha',
          hint: 'Crie uma senha segura',
          obscureText: true,
          prefixIcon: const IBIcon(IBIcon.lockOutline, color: AppColors.textMuted),
          controller: controller.passwordController,
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
      primaryAction: ValueListenableBuilder<bool>(
        valueListenable: controller.loading,
        builder: (context, loading, _) {
          return IBButton(
            label: 'Criar conta',
            loading: loading,
            onPressed: _submit,
          );
        },
      ),
      secondaryAction: TextButton(
        onPressed: () => AppNavigation.push(AppRoutes.login),
        child: IBText('Ja tenho conta', context: context)
            .label
            .color(AppColors.primary700)
            .build(),
      ),
    );
  }
}
