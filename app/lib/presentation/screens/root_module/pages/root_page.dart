import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/home_module/pages/home_page.dart';
import 'package:inbota/presentation/screens/reminders_module/pages/reminders_page.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;

  List<Widget> get _pages => const [
        HomePage(),
        RemindersPage(),
        _PlaceholderPage(title: 'Criar'),
        _PlaceholderPage(title: 'Compras'),
        _PlaceholderPage(title: 'Eventos'),
      ];

  @override
  Widget build(BuildContext context) {
    return IBScaffold(
      appBar: IBAppBar(
        title: 'Inbota',
        padding: const EdgeInsets.only(left: 12, right: 12),
        actions: [
          IconButton(
            onPressed: () => AppNavigation.push(AppRoutes.settings),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings01,
              color: AppColors.surface,
              size: 22,
              strokeWidth: 1.8,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      currentIndex: _currentIndex,
      onNavTap: (index) => setState(() => _currentIndex = index),
      floatingActionButton: null,
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IBText(title, context: context)
          .titulo
          .color(AppColors.textMuted)
          .build(),
    );
  }
}
