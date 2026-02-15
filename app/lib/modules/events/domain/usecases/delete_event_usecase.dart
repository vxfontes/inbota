import 'package:dartz/dartz.dart' show Unit;
import 'package:inbota/modules/events/domain/repositories/i_event_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class DeleteEventUsecase extends IBUsecase {
  DeleteEventUsecase(this._repository);

  final IEventRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteEvent(id);
  }
}
