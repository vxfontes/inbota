import 'package:flutter/material.dart';

import 'package:inbota/modules/reminders/data/models/reminder_list_output.dart';
import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/reminders/domain/usecases/get_reminders_usecase.dart';
import 'package:inbota/modules/tasks/data/models/task_create_input.dart';
import 'package:inbota/modules/tasks/data/models/task_list_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/modules/tasks/data/models/task_update_input.dart';
import 'package:inbota/modules/tasks/domain/usecases/create_task_usecase.dart';
import 'package:inbota/modules/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:inbota/modules/tasks/domain/usecases/update_task_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class RemindersController implements IBController {
  RemindersController(
    this._createTaskUsecase,
    this._getTasksUsecase,
    this._updateTaskUsecase,
    this._getRemindersUsecase,
  );

  final CreateTaskUsecase _createTaskUsecase;
  final GetTasksUsecase _getTasksUsecase;
  final UpdateTaskUsecase _updateTaskUsecase;
  final GetRemindersUsecase _getRemindersUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<TaskOutput>> tasks = ValueNotifier([]);
  final ValueNotifier<List<ReminderOutput>> reminders = ValueNotifier([]);

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
    tasks.dispose();
    reminders.dispose();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;

    final taskResult = await _getTasksUsecase.call(limit: 50);
    taskResult.fold(
      (failure) =>
          _setError(failure, fallback: 'Nao foi possivel carregar tarefas.'),
      (data) => tasks.value = _safeTaskItems(data),
    );

    final reminderResult = await _getRemindersUsecase.call(limit: 50);
    reminderResult.fold(
      (failure) =>
          _setError(failure, fallback: 'Nao foi possivel carregar lembretes.'),
      (data) => reminders.value = _safeReminderItems(data),
    );

    loading.value = false;
  }

  Future<void> toggleTask(TaskOutput task, bool done) async {
    final nextStatus = done ? 'DONE' : 'OPEN';

    final result = await _updateTaskUsecase.call(
      TaskUpdateInput(id: task.id, status: nextStatus),
    );

    result.fold(
      (failure) {
        _setError(failure, fallback: 'Nao foi possivel atualizar a tarefa.');
        _refreshTasks();
      },
      (updated) {
        final list = List<TaskOutput>.from(tasks.value);
        final index = list.indexWhere((item) => item.id == updated.id);
        if (index != -1) {
          list[index] = updated;
          tasks.value = list;
        }
      },
    );
  }

  Future<bool> createTask({required String title, DateTime? data}) async {
    if (loading.value) return false;
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      error.value = 'Informe um título para a tarefa.';
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _createTaskUsecase.call(
      TaskCreateInput(
        title: trimmed,
        status: 'OPEN',
        dueAt: data,
      ),
    );

    loading.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Nao foi possivel criar a tarefa.');
        return false;
      },
      (created) {
        final list = List<TaskOutput>.from(tasks.value);
        list.add(created);
        tasks.value = list;
        return true;
      },
    );
  }

  Future<void> _refreshTasks() async {
    final result = await _getTasksUsecase.call(limit: 50);
    result.fold((_) {}, (data) => tasks.value = _safeTaskItems(data));
  }

  List<TaskOutput> _safeTaskItems(TaskListOutput output) {
    return output.items.where((item) => item.id.isNotEmpty).toList();
  }

  List<ReminderOutput> _safeReminderItems(ReminderListOutput output) {
    return output.items.where((item) => item.id.isNotEmpty).toList();
  }

  void _setError(Failure failure, {required String fallback}) {
    final message = failure.message?.trim();
    if (message != null && message.isNotEmpty) {
      error.value = message;
    } else if (error.value == null || error.value!.isEmpty) {
      error.value = fallback;
    }
  }
}
