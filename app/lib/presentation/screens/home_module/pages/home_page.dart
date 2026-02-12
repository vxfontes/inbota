import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildTodoSection(context),
          const SizedBox(height: 20),
          _buildInboxSnapshot(context),
          const SizedBox(height: 20),
          _buildOverviewSection(context),
          const SizedBox(height: 24),
          _buildReviewSection(context),
          const SizedBox(height: 24),
          _buildReminderSection(context),
          const SizedBox(height: 24),
          _buildContextsSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Resumo do seu dia', context: context).titulo.build(),
        const SizedBox(height: 6),
        IBText(
          'Veja o que entrou no seu inbox e o que precisa da sua atenção.',
          context: context,
        ).muted.build(),
      ],
    );
  }

  Widget _buildTodoSection(BuildContext context) {
    return const IBTodoList(
      title: 'Tarefas críticas',
      subtitle: 'Resolva estas primeiro para liberar o restante do dia.',
      items: [
        IBTodoItemData(
          title: 'Revisar sugestões da IA do inbox',
          subtitle: '4 itens aguardando confirmação',
        ),
        IBTodoItemData(
          title: 'Enviar proposta para cliente Alpha',
          subtitle: 'Prazo hoje 17:00',
        ),
        IBTodoItemData(
          title: 'Comprar itens da semana',
          subtitle: 'Lista Casa com 8 itens',
          done: true,
        ),
      ],
    );
  }

  Widget _buildInboxSnapshot(BuildContext context) {
    return const IBOverviewCard(
      title: 'Inbox agora',
      subtitle: '12 itens aguardando, 3 em processamento pela IA.',
      chips: [
        IBChip(label: 'PROCESSING 3', color: AppColors.ai600),
        IBChip(label: 'NEEDS_REVIEW 4', color: AppColors.warning500),
        IBChip(label: 'CONFIRMED 5', color: AppColors.success600),
      ],
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Visão geral'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: IBStatCard(
                title: 'Lembretes',
                value: '4 hoje',
                subtitle: '9 próximos',
                color: AppColors.primary700,
                icon: IBIcon.alarmOutlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: IBStatCard(
                title: 'Eventos',
                value: '3 na semana',
                subtitle: '1 amanhã',
                color: AppColors.success600,
                icon: IBIcon.eventAvailableOutlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: IBStatCard(
                title: 'Compras',
                value: '2 listas',
                subtitle: '8 itens',
                color: AppColors.warning500,
                icon: IBIcon.shoppingBagOutlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: IBStatCard(
                title: 'Notas',
                value: '6 novas',
                subtitle: 'Últimas 24h',
                color: AppColors.ai600,
                icon: IBIcon.stickyNote2Outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Precisa revisar'),
        const SizedBox(height: 12),
        const IBInboxItemCard(
          title: 'Pagar internet dia 12',
          subtitle: 'Sugestão: Lembrete · 12/02 09:00',
          statusLabel: 'NEEDS_REVIEW',
          statusColor: AppColors.warning500,
          tags: ['Finanças', 'Casa'],
        ),
        const SizedBox(height: 12),
        const IBInboxItemCard(
          title: 'Reunião com cliente Alpha',
          subtitle: 'Sugestão: Evento · Amanhã 14:00',
          statusLabel: 'NEEDS_REVIEW',
          statusColor: AppColors.warning500,
          tags: ['Trabalho', 'Projeto QQPAG'],
        ),
      ],
    );
  }

  Widget _buildReminderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Próximos lembretes'),
        const SizedBox(height: 12),
        const IBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBReminderRow(
                title: 'Enviar documentos do TCC',
                time: 'Hoje 18:00',
                color: AppColors.primary700,
              ),
              Divider(height: 20, color: AppColors.border),
              IBReminderRow(
                title: 'Pagar fatura do cartão',
                time: 'Amanhã 09:00',
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

  Widget _buildContextsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Contextos ativos'),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            IBChip(label: 'Trabalho', color: AppColors.primary600),
            IBChip(label: 'Estudos', color: AppColors.ai600),
            IBChip(label: 'Casa', color: AppColors.success600),
            IBChip(label: 'Finanças', color: AppColors.warning500),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return IBText(title, context: context).subtitulo.build();
  }
}
