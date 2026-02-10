import 'package:flutter/material.dart';

import 'ib_bottom_nav.dart';

class IBScaffold extends StatelessWidget {
  const IBScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.padding = const EdgeInsets.all(20),
    this.currentIndex = 2,
    this.onNavTap,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry padding;
  final int currentIndex;
  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: body ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: IBBottomNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}
