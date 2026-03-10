import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';

class HomeBentoRow extends StatelessWidget {
  const HomeBentoRow({
    super.key,
    required this.progressPercent,
    required this.routinesDone,
    required this.routinesTotal,
    required this.tasksDone,
    required this.tasksTotal,
    required this.shoppingListCount,
    required this.shoppingItemCount,
    required this.onShoppingTap,
  });

  final double progressPercent;
  final int routinesDone;
  final int routinesTotal;
  final int tasksDone;
  final int tasksTotal;
  final int shoppingListCount;
  final int shoppingItemCount;
  final VoidCallback onShoppingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: IBDayProgressCard(
            progressPercent: progressPercent,
            routinesDone: routinesDone,
            routinesTotal: routinesTotal,
            tasksDone: tasksDone,
            tasksTotal: tasksTotal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: IBShoppingBanner(
            listCount: shoppingListCount,
            itemCount: shoppingItemCount,
            onTap: onShoppingTap,
          ),
        ),
      ],
    );
  }
}
