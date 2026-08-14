import 'package:flutter/material.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

const List<String> _deletedData = [
  'Itens da caixa de entrada',
  'Tarefas',
  'Lembretes',
  'Eventos',
  'Rotinas',
  'Listas de compras',
  'Categorias',
  'Conversas com o assistente',
  'Preferências de notificação',
  'Tokens de dispositivo',
];

class SettingsDeleteAccountBottomSheet extends StatefulWidget {
  const SettingsDeleteAccountBottomSheet({super.key, required this.onConfirm});

  /// Returns a message to show inline, or null once the account is gone — the
  /// sheet then pops with `true` so the page can send the user back to login.
  final Future<String?> Function(String password) onConfirm;

  @override
  State<SettingsDeleteAccountBottomSheet> createState() =>
      _SettingsDeleteAccountBottomSheetState();
}

class _SettingsDeleteAccountBottomSheetState
    extends State<SettingsDeleteAccountBottomSheet> {
  late final TextEditingController _passwordController;
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => setState(() => _errorText = null);

  bool get _canSubmit => _passwordController.text.isNotEmpty;

  Future<void> _onConfirmPressed() async {
    if (!_canSubmit || _loading) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final error = await widget.onConfirm(_passwordController.text);
    if (!mounted) return;

    if (error == null) {
      AppNavigation.pop(true, context);
      return;
    }

    setState(() {
      _loading = false;
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OQBottomSheet(
      title: 'Excluir conta',
      primaryLabel: 'Excluir conta',
      primaryEnabled: _canSubmit,
      primaryLoading: _loading,
      onPrimaryPressed: _onConfirmPressed,
      secondaryLabel: 'Cancelar',
      secondaryEnabled: !_loading,
      onSecondaryPressed: () => AppNavigation.pop(false, context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const OQIcon(
                OQIcon.deleteOutlineRounded,
                color: AppColors.danger600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OQText(
                  'Esta ação é permanente e não pode ser desfeita.',
                  context: context,
                ).body.build(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OQText('Você vai perder:', context: context).label.build(),
          const SizedBox(height: 8),
          for (final item in _deletedData)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: OQText('• $item', context: context).muted.build(),
            ),
          const SizedBox(height: 14),
          OQTextField(
            label: 'Senha',
            controller: _passwordController,
            obscureText: true,
            enabled: !_loading,
            errorText: _errorText,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 6),
          OQText(
            'Confirme sua senha para concluir.',
            context: context,
          ).caption.build(),
        ],
      ),
    );
  }
}
