import 'package:flutter/material.dart';

import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/screens/reminders_module/controller/reminders_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/reminders_format.dart';

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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
    return IBTodoList(
      title: 'To-dos',
      action: IconButton(
        tooltip: 'Adicionar tarefa',
        onPressed: _openCreateTodo,
        icon: const IBIcon(
          IBIcon.addRounded,
          color: AppColors.primary700,
          size: 20,
        ),
      ),
      emptyLabel: 'Quando surgirem tarefas, elas vão aparecer aqui.',
      items: tasks
          .map(
            (task) => IBTodoItemData(
              title: task.title,
              subtitle: RemindersFormat.taskSubtitle(task),
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
      title: 'Próximos dias',
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
                    time: RemindersFormat.formatReminderTime(items[i]),
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

  List<ReminderOutput> _todayReminders(List<ReminderOutput> reminders) {
    final now = DateTime.now();
    return reminders
        .where((item) =>
            item.remindAt != null && RemindersFormat.isSameDay(item.remindAt!, now))
        .toList();
  }

  List<ReminderOutput> _upcomingReminders(List<ReminderOutput> reminders) {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    return reminders
        .where((item) =>
            item.remindAt == null ||
            (RemindersFormat.isAfterDay(item.remindAt!, now) &&
                item.remindAt!.isBefore(limit)))
        .toList();
  }

  Color _reminderColor(String section, int index) {
    if (section == 'Hoje') return AppColors.primary700;
    if (section == 'Próximos dias') return AppColors.ai600;
    return index.isEven ? AppColors.warning500 : AppColors.success600;
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required bool enabled,
    required bool hasValue,
    required VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    final contentColor = enabled ? AppColors.text : AppColors.textMuted;
    final iconColor = enabled ? AppColors.primary600 : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IBIcon(
              IBIcon.eventAvailableOutlined,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IBText('Data', context: context).caption.build(),
                  const SizedBox(height: 2),
                  IBText(label, context: context).body.color(contentColor).build(),
                ],
              ),
            ),
            if (hasValue && onClear != null)
              IconButton(
                tooltip: 'Limpar data',
                onPressed: enabled ? onClear : null,
                icon: const IBIcon(
                  IBIcon.closeRounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                splashRadius: 18,
              )
            else
              const IBIcon(
                IBIcon.chevronRight,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickTaskDate(
    BuildContext context,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final initial = current ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Selecionar data',
    );

    if (pickedDate == null) return current;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    final resolvedTime = pickedTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      resolvedTime.hour,
      resolvedTime.minute,
    );
  }

  String _formatTaskDate(DateTime? date) {
    if (date == null) return 'Sem data definida';
    final day = RemindersFormat.formatDate(date);
    if (date.hour == 0 && date.minute == 0) return day;
    final hour = RemindersFormat.formatHour(date);
    return '$day às $hour';
  }

  Future<void> _openCreateTodo() async {
    final titleController = TextEditingController();
    final dateNotifier = ValueNotifier<DateTime?>(null);
    if (!mounted) return;

    await IBBottomSheet.show<void>(
      context: context,
      child: AnimatedBuilder(
        animation: controller.loading,
        builder: (context, _) {
          final loading = controller.loading.value;
          return IBBottomSheet(
            title: 'Nova tarefa',
            primaryLabel: 'Adicionar',
            primaryLoading: loading,
            primaryEnabled: !loading,
            onPrimaryPressed: () async {
              final success = await controller.createTask(
                title: titleController.text,
                data: dateNotifier.value,
              );
              if (!mounted) return;
              if (success) {
                AppNavigation.pop();
                return;
              }
              final message = controller.error.value ?? 'Nao foi possivel criar a tarefa.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            secondaryLabel: 'Cancelar',
            secondaryEnabled: !loading,
            onSecondaryPressed: () => AppNavigation.pop(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IBTextField(
                  label: 'Titulo',
                  hint: 'Ex: Enviar proposta',
                  controller: titleController,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<DateTime?>(
                  valueListenable: dateNotifier,
                  builder: (context, selectedDate, _) {
                    return _buildDateField(
                      context,
                      label: _formatTaskDate(selectedDate),
                      enabled: !loading,
                      hasValue: selectedDate != null,
                      onTap: loading
                          ? null
                          : () async {
                              final next =
                                  await _pickTaskDate(context, selectedDate);
                              if (next != null) {
                                dateNotifier.value = next;
                              }
                            },
                      onClear: loading ? null : () => dateNotifier.value = null,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );

    titleController.dispose();
    dateNotifier.dispose();
  }
}
