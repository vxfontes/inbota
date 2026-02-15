import 'dart:async';

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
  final ValueNotifier<List<TaskOutput>> visibleTasks = ValueNotifier([]);
  final ValueNotifier<List<ReminderOutput>> reminders = ValueNotifier([]);
  final Set<String> _doneGraceVisibleTaskIds = <String>{};
  final Map<String, Timer> _hideDoneTaskTimers = <String, Timer>{};

  @override
  void dispose() {
    for (final timer in _hideDoneTaskTimers.values) {
      timer.cancel();
    }
    _hideDoneTaskTimers.clear();
    loading.dispose();
    error.dispose();
    tasks.dispose();
    visibleTasks.dispose();
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
      (data) => _setTasks(_safeTaskItems(data)),
    );

    final reminderResult = await _getRemindersUsecase.call(limit: 50);
    reminderResult.fold(
      (failure) =>
          _setError(failure, fallback: 'Nao foi possivel carregar lembretes.'),
      (data) => reminders.value = _safeReminderItems(data),
    );

    loading.value = false;
  }

  Future<bool> toggleTask(TaskOutput task, bool done) async {
    final nextStatus = done ? 'DONE' : 'OPEN';
    if (!done) {
      _cancelHideDoneTask(task.id, removeGraceVisibility: true);
    }

    final result = await _updateTaskUsecase.call(
      TaskUpdateInput(id: task.id, status: nextStatus),
    );

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Nao foi possivel atualizar a tarefa.');
        _refreshTasks();
        return false;
      },
      (updated) {
        final list = List<TaskOutput>.from(tasks.value);
        final index = list.indexWhere((item) => item.id == updated.id);
        if (index != -1) {
          list[index] = updated;
        }
        _setTasks(list);
        if (updated.isDone) {
          _scheduleHideDoneTask(updated.id);
        } else {
          _cancelHideDoneTask(updated.id, removeGraceVisibility: true);
        }
        return true;
      },
    );
  }

  Future<void> toggleVisibleTaskAt(int index, bool done) async {
    final list = visibleTasks.value;
    if (index < 0 || index >= list.length) return;
    await toggleTask(list[index], done);
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
      TaskCreateInput(title: trimmed, status: 'OPEN', dueAt: data),
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
        _setTasks(list);
        return true;
      },
    );
  }

  Future<void> _refreshTasks() async {
    final result = await _getTasksUsecase.call(limit: 50);
    result.fold((_) {}, (data) => _setTasks(_safeTaskItems(data)));
  }

  void _setTasks(List<TaskOutput> items) {
    tasks.value = items;
    _rebuildVisibleTasks();
  }

  void _rebuildVisibleTasks() {
    visibleTasks.value = tasks.value
        .where(
          (task) => !task.isDone || _doneGraceVisibleTaskIds.contains(task.id),
        )
        .toList();
  }

  void _scheduleHideDoneTask(String taskId) {
    _cancelHideDoneTask(taskId, removeGraceVisibility: false);
    _doneGraceVisibleTaskIds.add(taskId);
    _rebuildVisibleTasks();

    _hideDoneTaskTimers[taskId] = Timer(const Duration(seconds: 2), () {
      _hideDoneTaskTimers.remove(taskId);
      _doneGraceVisibleTaskIds.remove(taskId);
      _rebuildVisibleTasks();
    });
  }

  void _cancelHideDoneTask(
    String taskId, {
    required bool removeGraceVisibility,
  }) {
    final timer = _hideDoneTaskTimers.remove(taskId);
    timer?.cancel();
    if (removeGraceVisibility) {
      _doneGraceVisibleTaskIds.remove(taskId);
      _rebuildVisibleTasks();
    }
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
