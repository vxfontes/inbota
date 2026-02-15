import 'package:flutter/material.dart';
import 'package:inbota/presentation/screens/events_module/components/event_calendar_strip.dart';
import 'package:inbota/presentation/screens/events_module/components/event_feed_item.dart';
import 'package:inbota/presentation/screens/events_module/components/event_filters.dart';
import 'package:inbota/presentation/screens/events_module/controller/events_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends IBState<EventsPage, EventsController> {
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.error,
        controller.calendarDays,
        controller.selectedDate,
        controller.selectedFilter,
        controller.visibleItems,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final error = controller.error.value;
        final days = controller.calendarDays.value;
        final selectedDate = controller.selectedDate.value;
        final selectedFilter = controller.selectedFilter.value;
        final items = controller.visibleItems.value;

        return ColoredBox(
          color: AppColors.background,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _buildHeader(context),
              if (error != null && error.isNotEmpty) ...[
                const SizedBox(height: 10),
                IBText(
                  error,
                  context: context,
                ).caption.color(AppColors.danger600).build(),
              ],
              const SizedBox(height: 16),
              EventCalendarStrip(
                days: days,
                selectedDate: selectedDate,
                months: controller.months,
                weekdays: controller.weekdays,
                onSelectDate: controller.selectDate,
              ),
              const SizedBox(height: 14),
              EventFilters(
                selected: selectedFilter,
                labelBuilder: controller.filterLabel,
                onSelect: controller.selectFilter,
              ),
              const SizedBox(height: 16),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: IBLoader(label: 'Carregando agenda...')),
                )
              else if (items.isEmpty)
                const IBCard(
                  child: IBEmptyState(
                    title: 'Sem itens para este dia',
                    subtitle:
                        'Selecione outra data ou ajuste o filtro para ver mais resultados.',
                    icon: IBHugeIcon.calendar,
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IBItemCard(
                      title: item.title,
                      secondary: item.secondary,
                      done: item.done,
                      doneLabel: 'Feito',
                      typeLabel: _typeLabel(item.type),
                      typeColor: _typeColor(item.type),
                      typeIcon: _typeIcon(item.type),
                      timeLabel: _timeLabel(item),
                      timeIcon: item.allDay
                          ? IBIcon.eventAvailableOutlined
                          : IBIcon.alarmOutlined,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Agenda', context: context).titulo.build(),
        const SizedBox(height: 6),
        IBText(
          'Eventos, tarefas e lembretes com data em um calendário único.',
          context: context,
        ).muted.build(),
      ],
    );
  }

  String _typeLabel(EventFeedItemType type) {
    switch (type) {
      case EventFeedItemType.event:
        return 'Evento';
      case EventFeedItemType.todo:
        return 'To-do';
      case EventFeedItemType.reminder:
        return 'Lembrete';
    }
  }

  Color _typeColor(EventFeedItemType type) {
    switch (type) {
      case EventFeedItemType.event:
        return AppColors.success600;
      case EventFeedItemType.todo:
        return AppColors.primary700;
      case EventFeedItemType.reminder:
        return AppColors.ai600;
    }
  }

  IconData _typeIcon(EventFeedItemType type) {
    switch (type) {
      case EventFeedItemType.event:
        return IBIcon.eventAvailableOutlined;
      case EventFeedItemType.todo:
        return IBIcon.taskAltRounded;
      case EventFeedItemType.reminder:
        return IBIcon.alarmOutlined;
    }
  }

  String _timeLabel(EventFeedItem item) {
    if (item.allDay) return 'Dia inteiro';
    if (!item.hasExplicitTime) return 'Sem horário';

    final hour = item.date.hour.toString().padLeft(2, '0');
    final minute = item.date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
