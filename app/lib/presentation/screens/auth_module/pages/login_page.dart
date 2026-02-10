import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/auth_module/controller/login_controller.dart';
import 'package:inbota/presentation/screens/auth_module/components/auth_form_scaffold.dart';
import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/components/ib_lib/ib_text_field.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends IBState<LoginPage, LoginController> {
  Future<void> _submit() async {
    final success = await controller.submit();
    if (!success || !mounted) return;
    AppNavigation.clearAndPush(AppRoutes.root);
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      header: Image.asset(
        'assets/app_icon.png',
        width: 64,
        height: 64,
      ),
      title: 'Entrar',
      subtitle: 'Acesse sua conta para continuar.',
      fields: [
        IBTextField(
          label: 'Email',
          hint: 'voce@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textMuted),
          controller: controller.emailController,
        ),
        const SizedBox(height: 16),
        IBTextField(
          label: 'Senha',
          hint: 'Digite sua senha',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
          controller: controller.passwordController,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: IBText('Esqueci minha senha', context: context)
                .label
                .color(AppColors.primary700)
                .build(),
          ),
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
            label: 'Entrar',
            loading: loading,
            onPressed: _submit,
          );
        },
      ),
      secondaryAction: TextButton(
        onPressed: () => AppNavigation.push(AppRoutes.signup),
        child: IBText('Criar uma conta', context: context)
            .label
            .color(AppColors.primary700)
            .build(),
      ),
    );
  }
}
