import 'package:flutter/material.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/home_module/components/home_day_hero.dart';
import 'package:inbota/presentation/screens/home_module/components/home_focus_now_card.dart';
import 'package:inbota/presentation/screens/home_module/components/home_quick_actions.dart';
import 'package:inbota/presentation/screens/home_module/controller/home_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/home_format.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends IBState<HomePage, HomeController> {
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
        controller.refreshing,
        controller.error,
        controller.agenda,
        controller.shoppingLists,
        controller.shoppingItemsByList,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final refreshing = controller.refreshing.value;
        final error = controller.error.value;

        if (loading && !controller.hasContent) {
          return const ColoredBox(
            color: AppColors.background,
            child: Center(child: IBLoader(label: 'Carregando resumo...')),
          );
        }

        return ColoredBox(
          color: AppColors.background,
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _buildHeader(context, refreshing),
                if (error != null && error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(context, error),
                ],
                const SizedBox(height: 16),
                _buildDayHero(context),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildAgendaSnapshot(context),
                const SizedBox(height: 20),
                _buildFocusNowSection(),
                const SizedBox(height: 20),
                _buildOverviewSection(context),
                const SizedBox(height: 20),
                _buildTodoSection(context),
                const SizedBox(height: 20),
                _buildEventsSection(context),
                const SizedBox(height: 20),
                _buildReminderSection(context),
                const SizedBox(height: 20),
                _buildShoppingSection(context),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool refreshing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText('Resumo do dia', context: context).titulo.build(),
              const SizedBox(height: 6),
              IBText(
                HomeFormat.todayHeadline(),
                context: context,
              ).muted.build(),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Atualizar',
          onPressed: refreshing ? null : controller.refresh,
          icon: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, color: AppColors.primary700),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger600.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.danger600.withAlpha((0.25 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          const IBIcon(
            Icons.error_outline_rounded,
            color: AppColors.danger600,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: IBText(
              message,
              context: context,
            ).caption.color(AppColors.danger600).build(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHero(BuildContext context) {
    final hasUrgency = controller.totalOverdueCount > 0;
    final completionPercent = (controller.actionCompletionRate * 100).round();
    final dueTodayTotal =
        controller.tasksTodayCount + controller.remindersTodayCount;
    final openTotal =
        controller.openTasksCount + controller.openReminders.length;

    return HomeDayHero(
      title: hasUrgency
          ? '${controller.totalOverdueCount} item(ns) critico(s) em atraso'
          : 'Sem atrasos criticos no momento',
      subtitle: hasUrgency
          ? 'Comece pelos atrasos para liberar sua agenda.'
          : 'Bom ritmo: foque nos itens de hoje para manter a consistencia.',
      completionRate: controller.actionCompletionRate,
      completionLabel:
          '$completionPercent% concluido (${controller.actionItemsDoneCount}/${controller.actionItemsTotalCount})',
      urgencyLabel: hasUrgency
          ? '${controller.totalOverdueCount} atraso(s)'
          : 'Sem atrasos',
      urgencyColor: hasUrgency ? AppColors.danger600 : AppColors.success600,
      stats: [
        HomeDayHeroStat(
          label: 'Hoje',
          value: '$dueTodayTotal pendente(s)',
          icon: IBIcon.alarmOutlined,
          color: AppColors.surface,
        ),
        HomeDayHeroStat(
          label: 'Abertos',
          value: '$openTotal em aberto',
          icon: IBIcon.taskAltRounded,
          color: AppColors.surface,
        ),
        HomeDayHeroStat(
          label: 'Compras',
          value: '${controller.pendingShoppingItemsCount} itens',
          icon: IBIcon.shoppingBagOutlined,
          color: AppColors.surface,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return HomeQuickActionsGrid(
      items: [
        HomeQuickActionItem(
          title: 'Lembretes',
          subtitle: '${controller.remindersTodayCount} para hoje',
          icon: IBIcon.alarmOutlined,
          color: AppColors.ai600,
          onTap: () => _navigateTo(AppRoutes.rootReminders),
        ),
        HomeQuickActionItem(
          title: 'Agenda',
          subtitle: '${controller.eventsThisWeekCount} evento(s) na semana',
          icon: IBIcon.eventAvailableOutlined,
          color: AppColors.success600,
          onTap: () => _navigateTo(AppRoutes.rootEvents),
        ),
        HomeQuickActionItem(
          title: 'Compras',
          subtitle:
              '${controller.pendingShoppingItemsCount} item(ns) pendente(s)',
          icon: IBIcon.shoppingBagOutlined,
          color: AppColors.warning500,
          onTap: () => _navigateTo(AppRoutes.rootShopping),
        ),
        HomeQuickActionItem(
          title: 'Capturar',
          subtitle: 'Criar novo item rapido',
          icon: IBIcon.addRounded,
          color: AppColors.primary700,
          onTap: () => _navigateTo(AppRoutes.rootCreate),
        ),
      ],
    );
  }

  Widget _buildAgendaSnapshot(BuildContext context) {
    final overdueColor = controller.totalOverdueCount > 0
        ? AppColors.danger600
        : AppColors.success600;

    return IBOverviewCard(
      title: 'Panorama',
      subtitle:
          '${controller.eventsTodayCount} evento(s), ${controller.remindersTodayCount} lembrete(s) e ${controller.openTasksCount} tarefa(s) em aberto.',
      chips: [
        IBChip(
          label: 'Atrasos ${controller.totalOverdueCount}',
          color: overdueColor,
        ),
        IBChip(
          label: 'Compras ${controller.pendingShoppingItemsCount}',
          color: AppColors.warning500,
        ),
        IBChip(
          label: 'Semana ${controller.eventsThisWeekCount}',
          color: AppColors.primary700,
        ),
      ],
    );
  }

  Widget _buildFocusNowSection() {
    return HomeFocusNowCard(
      title: 'Foco imediato',
      subtitle: 'Ordem sugerida para o seu proximo passo.',
      entries: _buildFocusNowEntries(),
      emptyTitle: 'Nenhum item urgente',
      emptySubtitle: 'Quando surgirem prioridades, elas vao aparecer aqui.',
    );
  }

  List<HomeFocusNowEntry> _buildFocusNowEntries() {
    final items = <_HomeFocusItem>[];
    final now = DateTime.now();

    for (final task in controller.overdueTasks.take(2)) {
      items.add(
        _HomeFocusItem(
          priority: 0,
          date: task.dueAt?.toLocal(),
          entry: HomeFocusNowEntry(
            title: task.title,
            subtitle: HomeFormat.taskSubtitle(task),
            category: 'Tarefa',
            icon: IBIcon.taskAltRounded,
            color: AppColors.danger600,
          ),
        ),
      );
    }

    for (final reminder in controller.overdueReminders.take(2)) {
      items.add(
        _HomeFocusItem(
          priority: 0,
          date: reminder.remindAt?.toLocal(),
          entry: HomeFocusNowEntry(
            title: reminder.title,
            subtitle: HomeFormat.relativeDateTimeLabel(reminder.remindAt),
            category: 'Lembrete',
            icon: IBIcon.alarmOutlined,
            color: AppColors.danger600,
          ),
        ),
      );
    }

    for (final task in controller.homeUpcomingTasksPreview.take(2)) {
      items.add(
        _HomeFocusItem(
          priority: 1,
          date: task.dueAt?.toLocal(),
          entry: HomeFocusNowEntry(
            title: task.title,
            subtitle: HomeFormat.taskSubtitle(task),
            category: 'Tarefa',
            icon: IBIcon.taskAltRounded,
            color: AppColors.primary700,
          ),
        ),
      );
    }

    for (final reminder in controller.homeUpcomingRemindersPreview.take(2)) {
      items.add(
        _HomeFocusItem(
          priority: 1,
          date: reminder.remindAt?.toLocal(),
          entry: HomeFocusNowEntry(
            title: reminder.title,
            subtitle: HomeFormat.relativeDateTimeLabel(reminder.remindAt),
            category: 'Lembrete',
            icon: IBIcon.alarmOutlined,
            color: AppColors.ai600,
          ),
        ),
      );
    }

    for (final event in controller.homeUpcomingEventsPreview.take(2)) {
      final isToday =
          event.startAt != null &&
          !event.startAt!.toLocal().isBefore(
            DateTime(now.year, now.month, now.day),
          ) &&
          event.startAt!.toLocal().isBefore(
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
          );
      items.add(
        _HomeFocusItem(
          priority: isToday ? 1 : 2,
          date: event.startAt?.toLocal(),
          entry: HomeFocusNowEntry(
            title: event.title,
            subtitle: HomeFormat.eventSubtitle(event),
            category: 'Evento',
            icon: IBIcon.eventAvailableOutlined,
            color: _eventStatusColor(event),
          ),
        ),
      );
    }

    items.sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      if (byPriority != 0) return byPriority;

      final left = a.date;
      final right = b.date;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });

    return items.map((item) => item.entry).take(6).toList(growable: false);
  }

  Widget _buildOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Visao geral'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Lembretes',
                value: '${controller.remindersTodayCount} hoje',
                subtitle: '${controller.remindersUpcomingCount} proximos',
                color: AppColors.primary700,
                icon: IBIcon.alarmOutlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Eventos',
                value: '${controller.eventsThisWeekCount} semana',
                subtitle: '${controller.eventsTodayCount} hoje',
                color: AppColors.success600,
                icon: IBIcon.eventAvailableOutlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Compras',
                value: '${controller.openShoppingListsCount} listas',
                subtitle: '${controller.pendingShoppingItemsCount} itens',
                color: AppColors.warning500,
                icon: IBIcon.shoppingBagOutlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Tarefas',
                value: '${controller.openTasksCount} abertas',
                subtitle: '${controller.overdueTasksCount} atrasadas',
                color: AppColors.primary600,
                icon: IBIcon.taskAltRounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodoSection(BuildContext context) {
    final tasks = controller.criticalTasks;
    return IBTodoList(
      title: 'Prioridades',
      subtitle: '${controller.openTasksCount} tarefa(s) em aberto',
      action: TextButton(
        onPressed: () => _navigateTo(AppRoutes.rootReminders),
        child: IBText(
          'Abrir lista',
          context: context,
        ).label.color(AppColors.primary700).build(),
      ),
      emptyLabel: 'Sem tarefas pendentes no momento.',
      items: tasks
          .map(
            (task) => IBTodoItemData(
              id: task.id,
              title: task.title,
              subtitle: HomeFormat.taskSubtitle(task),
              done: task.isDone,
            ),
          )
          .toList(),
      onToggle: controller.toggleCriticalTaskAt,
    );
  }

  Widget _buildEventsSection(BuildContext context) {
    final events = controller.homeUpcomingEventsPreview;
    if (events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Proximos eventos',
            actionLabel: 'Agenda',
            onAction: () => _navigateTo(AppRoutes.rootEvents),
          ),
          const SizedBox(height: 12),
          const IBCard(
            child: IBEmptyState(
              title: 'Sem eventos proximos',
              subtitle: 'Quando houver eventos agendados, eles aparecem aqui.',
              icon: IBHugeIcon.calendar,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Proximos eventos',
          actionLabel: 'Agenda',
          onAction: () => _navigateTo(AppRoutes.rootEvents),
        ),
        const SizedBox(height: 12),
        ...events.expand(
          (event) => [
            IBInboxItemCard(
              title: event.title,
              subtitle: HomeFormat.eventSubtitle(event),
              statusLabel: HomeFormat.eventStatus(event),
              statusColor: _eventStatusColor(event),
              tags: [
                'Evento',
                if (event.location != null && event.location!.trim().isNotEmpty)
                  event.location!.trim(),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ]..removeLast(),
    );
  }

  Widget _buildReminderSection(BuildContext context) {
    final reminders = controller.homeUpcomingRemindersPreview;
    if (reminders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Proximos lembretes',
            actionLabel: 'Lembretes',
            onAction: () => _navigateTo(AppRoutes.rootReminders),
          ),
          const SizedBox(height: 12),
          const IBCard(
            child: IBEmptyState(
              title: 'Sem lembretes proximos',
              subtitle: 'Quando houver novos lembretes, eles aparecem aqui.',
              icon: IBHugeIcon.reminder,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Proximos lembretes',
          actionLabel: 'Lembretes',
          onAction: () => _navigateTo(AppRoutes.rootReminders),
        ),
        const SizedBox(height: 12),
        IBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < reminders.length; i++) ...[
                IBReminderRow(
                  title: reminders[i].title,
                  time: HomeFormat.relativeDateTimeLabel(reminders[i].remindAt),
                  color: HomeFormat.reminderColor(i),
                ),
                if (i != reminders.length - 1)
                  const Divider(height: 20, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingSection(BuildContext context) {
    final lists = controller.homeShoppingListsPreview;
    if (lists.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Compras em aberto',
            actionLabel: 'Compras',
            onAction: () => _navigateTo(AppRoutes.rootShopping),
          ),
          const SizedBox(height: 12),
          const IBCard(
            child: IBEmptyState(
              title: 'Sem listas pendentes',
              subtitle: 'As listas de compras pendentes aparecem aqui.',
              icon: IBHugeIcon.shoppingBag,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Compras em aberto',
          actionLabel: 'Compras',
          onAction: () => _navigateTo(AppRoutes.rootShopping),
        ),
        const SizedBox(height: 12),
        IBCard(
          child: Column(
            children: [
              for (var i = 0; i < lists.length; i++) ...[
                _buildShoppingRow(context, lists[i]),
                if (i != lists.length - 1)
                  const Divider(height: 18, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingRow(BuildContext context, ShoppingListOutput list) {
    final pending = controller.pendingItemsForList(list.id);
    return Row(
      children: [
        const IBIcon(
          IBIcon.shoppingBagOutlined,
          color: AppColors.warning500,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: IBText(
            list.title,
            context: context,
          ).body.weight(FontWeight.w600).build(),
        ),
        IBChip(
          label: '$pending pendente(s)',
          color: pending == 0 ? AppColors.success600 : AppColors.warning500,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(child: IBText(title, context: context).subtitulo.build()),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: IBText(
              actionLabel,
              context: context,
            ).label.color(AppColors.primary700).build(),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return IBStatCard(
      title: title,
      value: value,
      subtitle: subtitle,
      color: color,
      icon: icon,
    );
  }

  Color _eventStatusColor(EventOutput event) {
    final status = HomeFormat.eventStatus(event);
    if (status == 'HOJE') return AppColors.danger600;
    if (status == 'AMANHA') return AppColors.warning500;
    return AppColors.success600;
  }

  void _navigateTo(String route) {
    AppNavigation.navigate(route);
  }
}

class _HomeFocusItem {
  const _HomeFocusItem({
    required this.priority,
    required this.date,
    required this.entry,
  });

  final int priority;
  final DateTime? date;
  final HomeFocusNowEntry entry;
}
