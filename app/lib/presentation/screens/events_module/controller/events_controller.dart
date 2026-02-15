import 'package:flutter/material.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/events/domain/usecases/get_events_usecase.dart';
import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/reminders/domain/usecases/get_reminders_usecase.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/modules/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:inbota/presentation/screens/events_module/components/event_feed_item.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class EventsController implements IBController {
  EventsController(
    this._getEventsUsecase,
    this._getTasksUsecase,
    this._getRemindersUsecase,
  );

  final GetEventsUsecase _getEventsUsecase;
  final GetTasksUsecase _getTasksUsecase;
  final GetRemindersUsecase _getRemindersUsecase;

  final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
  final months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<EventFeedFilter> selectedFilter = ValueNotifier(
    EventFeedFilter.all,
  );
  final ValueNotifier<DateTime> selectedDate = ValueNotifier(
    _startOfDay(DateTime.now()),
  );
  final ValueNotifier<List<DateTime>> calendarDays = ValueNotifier(
    const <DateTime>[],
  );
  final ValueNotifier<List<EventFeedItem>> allItems = ValueNotifier(
    const <EventFeedItem>[],
  );
  final ValueNotifier<List<EventFeedItem>> visibleItems = ValueNotifier(
    const <EventFeedItem>[],
  );

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
    selectedFilter.dispose();
    selectedDate.dispose();
    calendarDays.dispose();
    allItems.dispose();
    visibleItems.dispose();
  }

  Future<void> load() async {
    if (loading.value) return;

    loading.value = true;
    error.value = null;

    final merged = <EventFeedItem>[];

    final eventsResult = await _getEventsUsecase.call(limit: 200);
    eventsResult.fold(
      (failure) {
        _setError(failure, fallback: 'Nao foi possivel carregar eventos.');
      },
      (output) {
        merged.addAll(_eventItems(output.items));
      },
    );

    final tasksResult = await _getTasksUsecase.call(limit: 200);
    tasksResult.fold(
      (failure) {
        _setError(failure, fallback: 'Nao foi possivel carregar tarefas.');
      },
      (output) {
        merged.addAll(_taskItems(output.items));
      },
    );

    final remindersResult = await _getRemindersUsecase.call(limit: 200);
    remindersResult.fold(
      (failure) {
        _setError(failure, fallback: 'Nao foi possivel carregar lembretes.');
      },
      (output) {
        merged.addAll(_reminderItems(output.items));
      },
    );

    merged.sort((a, b) => a.date.compareTo(b.date));
    allItems.value = merged;

    _rebuildCalendarDays();
    _rebuildVisibleItems();
    loading.value = false;
  }

  void selectDate(DateTime date) {
    final next = _startOfDay(date);
    if (_isSameDay(next, selectedDate.value)) return;
    selectedDate.value = next;
    _rebuildVisibleItems();
  }

  void selectFilter(EventFeedFilter filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
    _rebuildVisibleItems();
  }

  String filterLabel(EventFeedFilter filter) {
    switch (filter) {
      case EventFeedFilter.all:
        return 'Todos';
      case EventFeedFilter.events:
        return 'Eventos';
      case EventFeedFilter.todos:
        return 'To-dos';
      case EventFeedFilter.reminders:
        return 'Lembretes';
    }
  }

  bool matchesFilter(EventFeedItem item, EventFeedFilter filter) {
    switch (filter) {
      case EventFeedFilter.all:
        return true;
      case EventFeedFilter.events:
        return item.type == EventFeedItemType.event;
      case EventFeedFilter.todos:
        return item.type == EventFeedItemType.todo;
      case EventFeedFilter.reminders:
        return item.type == EventFeedItemType.reminder;
    }
  }

  List<EventFeedItem> _eventItems(List<EventOutput> events) {
    return events
        .where((event) => event.id.isNotEmpty && event.startAt != null)
        .map(
          (event) => EventFeedItem(
            id: event.id,
            type: EventFeedItemType.event,
            title: event.title,
            date: event.startAt!.toLocal(),
            secondary: event.location,
            allDay: event.allDay,
          ),
        )
        .toList(growable: false);
  }

  List<EventFeedItem> _taskItems(List<TaskOutput> tasks) {
    return tasks
        .where((task) => task.id.isNotEmpty && task.dueAt != null)
        .map(
          (task) => EventFeedItem(
            id: task.id,
            type: EventFeedItemType.todo,
            title: task.title,
            date: task.dueAt!.toLocal(),
            secondary: task.description,
            done: task.isDone,
            allDay: task.dueAt!.hour == 0 && task.dueAt!.minute == 0,
          ),
        )
        .toList(growable: false);
  }

  List<EventFeedItem> _reminderItems(List<ReminderOutput> reminders) {
    return reminders
        .where(
          (reminder) => reminder.id.isNotEmpty && reminder.remindAt != null,
        )
        .map(
          (reminder) => EventFeedItem(
            id: reminder.id,
            type: EventFeedItemType.reminder,
            title: reminder.title,
            date: reminder.remindAt!.toLocal(),
            done: reminder.isDone,
            allDay:
                reminder.remindAt!.hour == 0 && reminder.remindAt!.minute == 0,
          ),
        )
        .toList(growable: false);
  }

  void _rebuildCalendarDays() {
    final now = _startOfDay(DateTime.now());

    DateTime start = now.subtract(const Duration(days: 4));
    DateTime end = now.add(const Duration(days: 14));

    if (allItems.value.isNotEmpty) {
      final minDate = _startOfDay(allItems.value.first.date);
      final maxDate = _startOfDay(allItems.value.last.date);

      if (minDate.isBefore(start)) start = minDate;
      if (maxDate.isAfter(end)) end = maxDate;
    }

    final days = <DateTime>[];
    var current = start;
    var guard = 0;
    while (!current.isAfter(end) && guard < 120) {
      days.add(current);
      current = current.add(const Duration(days: 1));
      guard++;
    }

    calendarDays.value = days;

    final selected = _startOfDay(selectedDate.value);
    final selectedExists = days.any((day) => _isSameDay(day, selected));
    if (!selectedExists) {
      selectedDate.value = days.isNotEmpty ? days.first : now;
    }
  }

  void _rebuildVisibleItems() {
    final selected = _startOfDay(selectedDate.value);
    final filter = selectedFilter.value;

    final filtered =
        allItems.value
            .where((item) {
              if (!_isSameDay(item.date, selected)) return false;
              return matchesFilter(item, filter);
            })
            .toList(growable: false)
          ..sort((a, b) => a.date.compareTo(b.date));

    visibleItems.value = filtered;
  }

  void _setError(Failure failure, {required String fallback}) {
    final message = failure.message?.trim();
    if (message != null && message.isNotEmpty) {
      error.value = message;
      return;
    }

    if (error.value == null || error.value!.isEmpty) {
      error.value = fallback;
    }
  }

  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

enum EventFeedFilter { all, events, todos, reminders }
