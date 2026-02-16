import 'package:dartz/dartz.dart' show Unit;
import 'package:inbota/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class DeleteFlagUsecase extends IBUsecase {
  DeleteFlagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteFlag(id);
  }
}
