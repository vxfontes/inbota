import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/modules/tasks/data/models/task_update_input.dart';
import 'package:inbota/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class UpdateTaskUsecase extends IBUsecase {
  final ITaskRepository _repository;

  UpdateTaskUsecase(this._repository);

  UsecaseResponse<Failure, TaskOutput> call(TaskUpdateInput input) {
    return _repository.updateTask(input);
  }
}
