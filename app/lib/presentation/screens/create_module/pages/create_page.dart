import 'package:flutter/material.dart';
import 'package:inbota/presentation/screens/create_module/components/create_result_line_tile.dart';
import 'package:inbota/presentation/screens/create_module/controller/create_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends IBState<CreatePage, CreateController> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.error,
        controller.batchResult,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final error = controller.error.value;
        final batchResult = controller.batchResult.value;

        return ColoredBox(
          color: AppColors.background,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _buildHeader(context),
              const SizedBox(height: 14),
              IBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IBText(
                      'Descreva do seu jeito. Iremos processar e criar itens organizados para você.',
                      context: context,
                    ).muted.build(),
                    const SizedBox(height: 10),
                    IBTextField(
                      label: 'Como anda sua vida?',
                      hint:
                          'Ex:\n- Pagar aluguel dia 05\n- Reunião com time amanhã 14h\n- Comprar leite e cafe',
                      controller: controller.inputController,
                      minLines: 8,
                      maxLines: 10,
                    ),
                    const SizedBox(height: 12),
                    IBButton(
                      label: 'Organizar',
                      loading: loading,
                      onPressed: loading ? null : controller.processText,
                    ),
                    const SizedBox(height: 8),
                    IBButton(
                      label: 'Limpar',
                      variant: IBButtonVariant.secondary,
                      onPressed: loading ? null : controller.clearInput,
                    ),
                    if (error != null && error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      IBText(
                        error,
                        context: context,
                      ).caption.color(AppColors.danger600).build(),
                    ],
                  ],
                ),
              ),
              if (batchResult != null) ...[
                const SizedBox(height: 16),
                _buildSummary(context, batchResult),
                const SizedBox(height: 12),
                IBCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IBText(
                        'Itens por linha',
                        context: context,
                      ).subtitulo.build(),
                      const SizedBox(height: 10),
                      ...batchResult.lines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CreateResultLineTile(
                            result: line,
                            onDelete: controller.deleteLineResult,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        IBText('Criar', context: context).titulo.build(),
        const SizedBox(height: 6),
        IBText(
          'Transforme texto em itens organizados: tarefas, lembretes, eventos e compras.',
          context: context,
        ).muted.build(),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, CreateBatchResult batchResult) {
    return IBOverviewCard(
      title: 'Resumo',
      subtitle:
          '${batchResult.successCount} de ${batchResult.totalInputs} linha(s) processadas. Revise abaixo.',
      chips: [
        IBChip(
          label: 'Tarefas ${batchResult.tasksCount}',
          color: AppColors.primary700,
        ),
        IBChip(
          label: 'Lembretes ${batchResult.remindersCount}',
          color: AppColors.ai600,
        ),
        IBChip(
          label: 'Eventos ${batchResult.eventsCount}',
          color: AppColors.success600,
        ),
        IBChip(
          label: 'Lista de compras ${batchResult.shoppingListsCount}',
          color: AppColors.warning500,
        ),
        IBChip(
          label: 'Itens de compra ${batchResult.shoppingItemsCount}',
          color: AppColors.primary500,
        ),
        IBChip(
          label: 'Falhas ${batchResult.failedCount}',
          color: AppColors.danger600,
        ),
      ],
    );
  }
}
