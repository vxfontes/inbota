import 'package:inbota/modules/tasks/data/models/task_list_output.dart';
import 'package:inbota/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetTasksUsecase extends IBUsecase {
  final ITaskRepository _repository;

  GetTasksUsecase(this._repository);

  UsecaseResponse<Failure, TaskListOutput> call({int? limit, String? cursor}) {
    return _repository.fetchTasks(limit: limit, cursor: cursor);
  }
}
