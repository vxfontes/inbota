import 'package:inbota/modules/tasks/data/models/task_create_input.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class CreateTaskUsecase extends IBUsecase {
  final ITaskRepository _repository;

  CreateTaskUsecase(this._repository);

  UsecaseResponse<Failure, TaskOutput> call(TaskCreateInput input) {
    return _repository.createTask(input);
  }
}
