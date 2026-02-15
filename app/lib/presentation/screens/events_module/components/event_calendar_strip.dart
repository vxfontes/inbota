import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class EventCalendarStrip extends StatelessWidget {
  const EventCalendarStrip({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.months,
    required this.weekdays,
    required this.onSelectDate,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final List<String> months;
  final List<String> weekdays;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected =
              day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onSelectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 88,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary700 : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary700 : AppColors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary700.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IBText(months[day.month - 1], context: context).caption
                      .color(
                        isSelected ? AppColors.surface : AppColors.textMuted,
                      )
                      .build(),
                  const SizedBox(height: 2),
                  IBText('${day.day}', context: context).titulo
                      .color(isSelected ? AppColors.surface : AppColors.text)
                      .build(),
                  const SizedBox(height: 2),
                  IBText(_weekdayLabel(day), context: context).caption
                      .color(
                        isSelected ? AppColors.surface : AppColors.textMuted,
                      )
                      .build(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    final adjusted = date.weekday == 7 ? 6 : date.weekday - 1;
    return weekdays[adjusted];
  }
}
