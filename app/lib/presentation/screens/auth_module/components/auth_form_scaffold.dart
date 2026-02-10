import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.primaryAction,
    this.secondaryAction,
    this.header,
  });

  final String title;
  final String subtitle;
  final List<Widget> fields;
  final Widget primaryAction;
  final Widget? secondaryAction;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (header != null) ...[
                            header!,
                            const SizedBox(height: 24),
                          ],
                          IBText(title, context: context).titulo.build(),
                          const SizedBox(height: 8),
                          IBText(subtitle, context: context).muted.build(),
                          const SizedBox(height: 24),
                          ...fields,
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          primaryAction,
                          if (secondaryAction != null) ...[
                            secondaryAction!,
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
