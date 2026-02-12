import 'package:flutter/material.dart';

import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/presentation/screens/reminders_module/controller/reminders_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends IBState<RemindersPage, RemindersController> {
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
        controller.tasks,
        controller.reminders,
      ]),
      builder: (context, _) {
        final tasks = _sortedTasks(controller.tasks.value);
        final reminders = controller.reminders.value;
        final loading = controller.loading.value;
        final error = controller.error.value;
        final showFullLoading = loading;
        final loadingLabel =
            tasks.isEmpty && reminders.isEmpty ? 'Carregando...' : 'Atualizando...';

        return Stack(
          children: [
            ColoredBox(
              color: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildHeader(context),
                  if (error != null && error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    IBText(error, context: context)
                        .caption
                        .color(AppColors.danger600)
                        .build(),
                  ],
                  const SizedBox(height: 16),
                  _buildQuickStats(context, reminders),
                  const SizedBox(height: 20),
                  _buildTodoSection(context, tasks),
                  const SizedBox(height: 24),
                  _buildTodaySection(context, reminders),
                  const SizedBox(height: 24),
                  _buildUpcomingSection(context, reminders),
                  const SizedBox(height: 24),
                  _buildDoneSection(context, reminders),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (showFullLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background,
                  child: Center(child: IBLoader(label: loadingLabel)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Lembretes', context: context).titulo.build(),
        const SizedBox(height: 6),
        IBText(
          'Priorize o que vence hoje e acompanhe os próximos dias.',
          context: context,
        ).muted.build(),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, List<ReminderOutput> reminders) {
    final open = reminders.where((item) => !item.isDone).toList();
    final done = reminders.where((item) => item.isDone).toList();
    final today = _todayReminders(open);

    return IBOverviewCard(
      title: 'Resumo rápido',
      subtitle: 'Você tem ${today.length} lembretes hoje e ${open.length} ativos.',
      chips: [
        IBChip(label: 'HOJE ${today.length}', color: AppColors.primary700),
        IBChip(label: 'ATIVOS ${open.length}', color: AppColors.ai600),
        IBChip(label: 'CONCLUÍDOS ${done.length}', color: AppColors.success600),
      ],
    );
  }

  Widget _buildTodoSection(BuildContext context, List<TaskOutput> tasks) {
    if (tasks.isEmpty) {
      return const IBEmptyState(
        title: 'Nenhuma tarefa crítica',
        subtitle: 'Quando surgirem tarefas, elas vão aparecer aqui.',
      );
    }

    return IBTodoList(
      title: 'To-dos críticos',
      subtitle: 'Marque ao concluir para limpar seu foco.',
      items: tasks
          .map(
            (task) => IBTodoItemData(
              title: task.title,
              subtitle: _taskSubtitle(task),
              done: task.isDone,
            ),
          )
          .toList(),
      onToggle: (index, done) => controller.toggleTask(tasks[index], done),
    );
  }

  Widget _buildTodaySection(BuildContext context, List<ReminderOutput> reminders) {
    final items = _todayReminders(reminders.where((item) => !item.isDone).toList());
    return _buildReminderSection(
      context,
      title: 'Hoje',
      items: items,
      fallback: 'Nenhum lembrete para hoje.',
    );
  }

  Widget _buildUpcomingSection(BuildContext context, List<ReminderOutput> reminders) {
    final items = _upcomingReminders(reminders.where((item) => !item.isDone).toList());
    return _buildReminderSection(
      context,
      title: 'Próximos 7 dias',
      items: items,
      fallback: 'Sem lembretes programados.',
    );
  }

  Widget _buildDoneSection(BuildContext context, List<ReminderOutput> reminders) {
    final items = reminders.where((item) => item.isDone).toList();
    return _buildReminderSection(
      context,
      title: 'Concluídos',
      items: items,
      fallback: 'Nada concluído ainda.',
      muted: true,
    );
  }

  Widget _buildReminderSection(
    BuildContext context, {
    required String title,
    required List<ReminderOutput> items,
    required String fallback,
    bool muted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText(title, context: context).subtitulo.build(),
        const SizedBox(height: 12),
        if (items.isEmpty)
          IBText(fallback, context: context).muted.build()
        else
          IBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  IBReminderRow(
                    title: items[i].title,
                    time: _formatReminderTime(items[i]),
                    color: muted ? AppColors.textMuted : _reminderColor(title, i),
                  ),
                  if (i != items.length - 1)
                    const Divider(height: 20, color: AppColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }

  List<TaskOutput> _sortedTasks(List<TaskOutput> tasks) {
    final sorted = List<TaskOutput>.from(tasks);
    sorted.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final dueA = a.dueAt ?? DateTime(2100);
      final dueB = b.dueAt ?? DateTime(2100);
      return dueA.compareTo(dueB);
    });
    return sorted;
  }

  String _taskSubtitle(TaskOutput task) {
    if (task.dueAt == null) return 'Sem data definida';
    final date = task.dueAt!.toLocal();
    return 'Vence ${_formatDate(date)}';
  }

  List<ReminderOutput> _todayReminders(List<ReminderOutput> reminders) {
    final now = DateTime.now();
    return reminders
        .where((item) => item.remindAt != null && _isSameDay(item.remindAt!, now))
        .toList();
  }

  List<ReminderOutput> _upcomingReminders(List<ReminderOutput> reminders) {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    return reminders
        .where((item) =>
            item.remindAt == null ||
            (_isAfterDay(item.remindAt!, now) && item.remindAt!.isBefore(limit)))
        .toList();
  }

  String _formatReminderTime(ReminderOutput reminder) {
    final date = reminder.remindAt?.toLocal();
    if (date == null) return 'Sem data';

    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Hoje ${_formatHour(date)}';
    }
    if (_isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Amanhã ${_formatHour(date)}';
    }
    return '${_formatDate(date)} ${_formatHour(date)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _formatHour(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isAfterDay(DateTime a, DateTime b) {
    if (_isSameDay(a, b)) return false;
    return a.isAfter(DateTime(b.year, b.month, b.day, 23, 59, 59));
  }

  Color _reminderColor(String section, int index) {
    if (section == 'Hoje') return AppColors.primary700;
    if (section == 'Próximos 7 dias') return AppColors.ai600;
    return index.isEven ? AppColors.warning500 : AppColors.success600;
  }
}
