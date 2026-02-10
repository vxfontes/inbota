import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/auth_module/components/auth_form_scaffold.dart';
import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/components/ib_lib/ib_text_field.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

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
      fields: const [
        IBTextField(
          label: 'Nome completo',
          hint: 'Como podemos te chamar?',
          prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
        ),
        SizedBox(height: 16),
        IBTextField(
          label: 'Email',
          hint: 'voce@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(Icons.mail_outline, color: AppColors.textMuted),
        ),
        SizedBox(height: 16),
        IBTextField(
          label: 'Senha',
          hint: 'Crie uma senha segura',
          obscureText: true,
          prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
        ),
      ],
      primaryAction: IBButton(
        label: 'Criar conta',
        onPressed: () => AppNavigation.clearAndPush(AppRoutes.root),
      ),
      secondaryAction: IBButton(
        label: 'Já tenho conta',
        onPressed: () => AppNavigation.push(AppRoutes.login),
        variant: IBButtonVariant.ghost,
      ),
    );
  }
}
