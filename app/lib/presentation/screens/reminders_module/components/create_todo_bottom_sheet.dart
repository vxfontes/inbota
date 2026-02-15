import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class CreateTodoSheet extends StatefulWidget {
  const CreateTodoSheet({
    super.key,
    required this.loadingListenable,
    required this.errorListenable,
    required this.onCreateTask,
    required this.pickTaskDate,
    required this.formatTaskDate,
  });

  final ValueNotifier<bool> loadingListenable;
  final ValueNotifier<String?> errorListenable;
  final Future<bool> Function({required String title, DateTime? data})
  onCreateTask;
  final Future<DateTime?> Function(BuildContext context, DateTime? current)
  pickTaskDate;
  final String Function(DateTime? date) formatTaskDate;

  @override
  State<CreateTodoSheet> createState() => CreateTodoSheetState();
}

class CreateTodoSheetState extends State<CreateTodoSheet> {
  late final TextEditingController _titleController;
  late final ValueNotifier<DateTime?> _dateNotifier;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _dateNotifier = ValueNotifier<DateTime?>(null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.loadingListenable,
      builder: (sheetContext, _) {
        final loading = widget.loadingListenable.value;
        return IBBottomSheet(
          title: 'Nova tarefa',
          primaryLabel: 'Adicionar',
          primaryLoading: loading,
          primaryEnabled: !loading,
          onPrimaryPressed: () async {
            final success = await widget.onCreateTask(
              title: _titleController.text,
              data: _dateNotifier.value,
            );
            if (!mounted) return;
            if (!sheetContext.mounted) return;
            if (success) {
              _closeSheet(sheetContext);
              return;
            }
            final message =
                widget.errorListenable.value ??
                    'Nao foi possivel criar a tarefa.';
            ScaffoldMessenger.of(
              sheetContext,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
          secondaryLabel: 'Cancelar',
          secondaryEnabled: !loading,
          onSecondaryPressed: () => _closeSheet(sheetContext),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IBTextField(
                label: 'Titulo',
                hint: 'Ex: Enviar proposta',
                controller: _titleController,
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<DateTime?>(
                valueListenable: _dateNotifier,
                builder: (context, selectedDate, _) {
                  return _buildDateField(
                    sheetContext,
                    label: widget.formatTaskDate(selectedDate),
                    enabled: !loading,
                    hasValue: selectedDate != null,
                    onTap: loading
                        ? null
                        : () async {
                      final next = await widget.pickTaskDate(
                        sheetContext,
                        selectedDate,
                      );
                      if (next != null) {
                        _dateNotifier.value = next;
                      }
                    },
                    onClear: loading ? null : () => _dateNotifier.value = null,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _closeSheet(BuildContext context) {
    return AppNavigation.pop(null, context);
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
            IBIcon(IBIcon.eventAvailableOutlined, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IBText('Data', context: context).caption.build(),
                  const SizedBox(height: 2),
                  IBText(
                    label,
                    context: context,
                  ).body.color(contentColor).build(),
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
}
