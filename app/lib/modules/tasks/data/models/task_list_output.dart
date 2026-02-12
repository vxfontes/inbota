import 'task_output.dart';

class TaskListOutput {
  const TaskListOutput({required this.items, this.nextCursor});

  final List<TaskOutput> items;
  final String? nextCursor;

  factory TaskListOutput.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <TaskOutput>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(TaskOutput.fromJson(item));
        } else if (item is Map) {
          items.add(TaskOutput.fromJson(item.map((key, value) => MapEntry(key.toString(), value))));
        }
      }
    }

    return TaskListOutput(
      items: items,
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}
