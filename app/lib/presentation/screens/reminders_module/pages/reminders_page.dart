import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildQuickStats(context),
        const SizedBox(height: 20),
        _buildTodoSection(context),
        const SizedBox(height: 24),
        _buildTodaySection(context),
        const SizedBox(height: 24),
        _buildUpcomingSection(context),
        const SizedBox(height: 24),
        _buildDoneSection(context),
        const SizedBox(height: 24),
      ],
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

  Widget _buildQuickStats(BuildContext context) {
    return IBOverviewCard(
      title: 'Resumo rápido',
      subtitle: 'Você tem 4 lembretes hoje e 9 agendados na semana.',
      chips: const [
        IBChip(label: 'HOJE 4', color: AppColors.primary700),
        IBChip(label: 'PRÓXIMOS 9', color: AppColors.ai600),
        IBChip(label: 'CONCLUÍDOS 2', color: AppColors.success600),
      ],
    );
  }

  Widget _buildTodoSection(BuildContext context) {
    return const IBTodoList(
      title: 'To-dos críticos',
      subtitle: 'Marque ao concluir para limpar seu foco.',
      items: [
        IBTodoItemData(
          title: 'Revisar lembretes do trabalho',
          subtitle: '2 precisam de confirmação',
        ),
        IBTodoItemData(
          title: 'Enviar comprovante do pagamento',
          subtitle: 'Até 15:00',
        ),
        IBTodoItemData(
          title: 'Confirmar consulta médica',
          subtitle: 'Hoje 11:00',
          done: true,
        ),
      ],
    );
  }

  Widget _buildTodaySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Hoje'),
        const SizedBox(height: 12),
        IBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              IBReminderRow(
                title: 'Pagar fatura do cartão',
                time: '09:00',
                color: AppColors.warning500,
              ),
              Divider(height: 20, color: AppColors.border),
              IBReminderRow(
                title: 'Enviar documentos do TCC',
                time: '18:00',
                color: AppColors.primary700,
              ),
              Divider(height: 20, color: AppColors.border),
              IBReminderRow(
                title: 'Separar compras da semana',
                time: '20:30',
                color: AppColors.success600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Próximos 7 dias'),
        const SizedBox(height: 12),
        IBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              IBReminderRow(
                title: 'Reunião com cliente Alpha',
                time: 'Amanhã 14:00',
                color: AppColors.ai600,
              ),
              Divider(height: 20, color: AppColors.border),
              IBReminderRow(
                title: 'Renovar seguro do carro',
                time: 'Quinta 10:00',
                color: AppColors.warning500,
              ),
              Divider(height: 20, color: AppColors.border),
              IBReminderRow(
                title: 'Check-in da consulta',
                time: 'Sexta 08:00',
                color: AppColors.success600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoneSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Concluídos'),
        const SizedBox(height: 12),
        IBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              IBReminderRow(
                title: 'Enviar feedback do sprint',
                time: 'Ontem 16:00',
                color: AppColors.textMuted,
              ),
              Divider(height: 20, color: AppColors.border),
              IBReminderRow(
                title: 'Pagar plano anual',
                time: 'Ontem 09:00',
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return IBText(title, context: context).subtitulo.build();
  }
}
