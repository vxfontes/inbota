import 'package:dartz/dartz.dart' show Unit;
import 'package:inbota/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class DeleteTaskUsecase extends IBUsecase {
  DeleteTaskUsecase(this._repository);

  final ITaskRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteTask(id);
  }
}
