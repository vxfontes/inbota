import 'package:flutter/material.dart';

import 'package:inbota/presentation/screens/schedule_module/controller/schedule_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class CreateRoutineBottomSheet extends StatefulWidget {
  const CreateRoutineBottomSheet({
    super.key,
    required this.controller,
  });

  final ScheduleController controller;

  @override
  State<CreateRoutineBottomSheet> createState() =>
      _CreateRoutineBottomSheetState();
}

class _CreateRoutineBottomSheetState extends State<CreateRoutineBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller.loading,
        widget.controller.error,
        widget.controller.flags,
        widget.controller.subflagsByFlag,
        widget.controller.createSelectedWeekdays,
        widget.controller.createStartTime,
        widget.controller.createEndTime,
        widget.controller.createRecurrenceType,
        widget.controller.createSelectedFlagId,
        widget.controller.createSelectedSubflagId,
      ]),
      builder: (context, _) {
        final isLoading = widget.controller.loading.value;
        final error = widget.controller.error.value;
        final flags = widget.controller.flags.value;
        final flagOptions = flags
            .map(
              (flag) => IBFlagsFieldOption(
                id: flag.id,
                label: flag.name,
                color: flag.color,
              ),
            )
            .toList(growable: false);
        final selectedWeekdays = widget.controller.createSelectedWeekdays.value;
        final startTime = widget.controller.createStartTime.value;
        final endTime = widget.controller.createEndTime.value;
        final recurrenceType = widget.controller.createRecurrenceType.value;
        final selectedFlagId = widget.controller.createSelectedFlagId.value;
        final selectedSubflagId =
            widget.controller.createSelectedSubflagId.value;
        final subflags = selectedFlagId == null
            ? const []
            : widget.controller.subflagsByFlag.value[selectedFlagId] ?? const [];
        final subflagOptions = subflags
            .map(
              (subflag) => IBFlagsFieldOption(
                id: subflag.id,
                label: subflag.name,
                color: subflag.color,
              ),
            )
            .toList(growable: false);
        final title = widget.controller.formTitle;
        final primaryLabel = widget.controller.formPrimaryLabel;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                IBText(title, context: context).titulo.build(),
                const SizedBox(height: 24),
                if (error != null && error.isNotEmpty) ...[
                  IBText(error, context: context)
                      .caption
                      .color(AppColors.danger600)
                      .build(),
                  const SizedBox(height: 16),
                ],
                IBTextField(
                  controller: widget.controller.createTitleController,
                  label: 'Título',
                  hint: 'Ex: Academia, Reunião, Tomar remédio',
                  enabled: !isLoading,
                ),
                const SizedBox(height: 20),
                IBText('Dias da semana', context: context).subtitulo.build(),
                const SizedBox(height: 12),
                _buildWeekdayChips(
                  selectedWeekdays,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 20),
                _buildTimePickers(
                  startTime,
                  endTime,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 20),
                _buildRecurrenceChips(isLoading, recurrenceType),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: IBFlagsField(
                    label: 'Contextos',
                    options: flagOptions,
                    selectedId: selectedFlagId,
                    enabled: !isLoading,
                    onChanged: (value) async {
                      if (value == selectedFlagId) return;
                      widget.controller.setCreateFlagId(value);
                      if (value != null) {
                        await widget.controller.loadSubflags(value);
                      }
                    },
                  ),
                ),
                if (selectedFlagId != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: IBFlagsField(
                      label: 'Subflag',
                      emptyLabel: 'Nenhuma subflag disponível',
                      options: subflagOptions,
                      selectedId: selectedSubflagId,
                      enabled: !isLoading,
                      onChanged: widget.controller.setCreateSubflagId,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: IBButton(
                    label: primaryLabel,
                    loading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekdayChips(
    Set<int> selectedWeekdays, {
    required bool enabled,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScheduleController.weekdayChipOptions.map((day) {
        final value = day.value;
        final isSelected = selectedWeekdays.contains(value);
        final textColor =
            isSelected ? AppColors.surface : AppColors.textMuted;

        return InkWell(
          onTap:
              enabled ? () => widget.controller.toggleCreateWeekday(value) : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary700 : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary700 : AppColors.border,
              ),
            ),
            child: Center(
              child: IBText(day.label, context: context)
                  .label
                  .color(textColor)
                  .build(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimePickers(
    String startTime,
    String? endTime, {
    required bool enabled,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTimeField(
            label: 'Início',
            value: startTime,
            hasValue: true,
            enabled: enabled,
            onTap: _pickStartTime,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeField(
            label: 'Término (opcional)',
            value: endTime ?? '--:--',
            hasValue: endTime != null,
            enabled: enabled,
            onTap: _pickEndTime,
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceChips(bool isLoading, String recurrenceType) {
    const options = [
      _RecurrenceOption('weekly', 'Semanal'),
      _RecurrenceOption('biweekly', 'Quinzenal'),
      _RecurrenceOption('triweekly', '3 em 3 semanas'),
      _RecurrenceOption('monthly_week', 'Mensal (semana do mês)'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Frequência', context: context).caption.build(),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: isLoading
                    ? null
                    : () => widget.controller.setCreateRecurrenceType(
                          option.value,
                        ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: isLoading
                      ? 0.5
                      : option.value == recurrenceType
                      ? 1
                      : 0.6,
                  child: IBChip(
                    label: option.label,
                    color: option.value == recurrenceType
                        ? AppColors.primary700
                        : AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required bool hasValue,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final textColor = hasValue ? AppColors.text : AppColors.textMuted;
    final iconColor = enabled ? AppColors.textMuted : AppColors.borderStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText(label, context: context).caption.build(),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IBIcon(
                  IBIcon.alarmOutlined,
                  size: 20,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                IBText(value, context: context).body.color(textColor).build(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartTime() async {
    final parts = widget.controller.createStartTime.value.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      widget.controller.setCreateStartTime(time);
    }
  }

  Future<void> _pickEndTime() async {
    final endTime = widget.controller.createEndTime.value;
    final initialTime = endTime != null
        ? TimeOfDay(
            hour: int.parse(endTime.split(':')[0]),
            minute: int.parse(endTime.split(':')[1]),
          )
        : TimeOfDay.now();

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      widget.controller.setCreateEndTime(time);
    }
  }

  Future<void> _submit() async {
    final success = await widget.controller.submitRoutineForm();

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _RecurrenceOption {
  const _RecurrenceOption(this.value, this.label);

  final String value;
  final String label;
}
