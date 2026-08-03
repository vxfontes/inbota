import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/theme_controller.dart';

class SettingsAppearancePage extends StatefulWidget {
  const SettingsAppearancePage({super.key});

  @override
  State<SettingsAppearancePage> createState() => _SettingsAppearancePageState();
}

class _SettingsAppearancePageState extends State<SettingsAppearancePage> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = Modular.get<ThemeController>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aparência'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OQText('Tema', context: context).subtitulo.build(),
              const SizedBox(height: 12),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: _themeController.themeMode,
                builder: (context, current, _) {
                  return Column(
                    children: [
                      _ThemeOption(
                        label: 'Sistema',
                        subtitle: 'Segue a configuração do dispositivo',
                        icon: Icons.brightness_auto_rounded,
                        selected: current == ThemeMode.system,
                        onTap: () =>
                            _themeController.setThemeMode(ThemeMode.system),
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 8),
                      _ThemeOption(
                        label: 'Claro',
                        subtitle: 'Interface sempre em modo claro',
                        icon: Icons.light_mode_rounded,
                        selected: current == ThemeMode.light,
                        onTap: () =>
                            _themeController.setThemeMode(ThemeMode.light),
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 8),
                      _ThemeOption(
                        label: 'Escuro',
                        subtitle: 'Interface sempre em modo escuro',
                        icon: Icons.dark_mode_rounded,
                        selected: current == ThemeMode.dark,
                        onTap: () =>
                            _themeController.setThemeMode(ThemeMode.dark),
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ],
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? colorScheme.primary : colorScheme.outlineVariant;
    final bgColor = selected
        ? colorScheme.primary.withAlpha((0.08 * 255).round())
        : colorScheme.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
