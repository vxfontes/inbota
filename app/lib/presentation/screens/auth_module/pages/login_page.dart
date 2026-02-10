import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/auth_module/components/auth_form_scaffold.dart';
import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/components/ib_lib/ib_text_field.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
        const IBTextField(
          label: 'Email',
          hint: 'voce@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        const IBTextField(
          label: 'Senha',
          hint: 'Digite sua senha',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
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
      ],
      primaryAction: IBButton(
        label: 'Entrar',
        onPressed: () => AppNavigation.clearAndPush(AppRoutes.root),
      ),
      secondaryAction: IBButton(
        label: 'Criar uma conta',
        onPressed: () => AppNavigation.push(AppRoutes.login),
        variant: IBButtonVariant.ghost,
      ),
    );
  }
}
