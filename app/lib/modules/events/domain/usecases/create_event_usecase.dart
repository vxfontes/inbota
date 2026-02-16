import 'package:inbota/modules/events/data/models/event_create_input.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/events/domain/repositories/i_event_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class CreateEventUsecase extends IBUsecase {
  CreateEventUsecase(this._repository);

  final IEventRepository _repository;

  UsecaseResponse<Failure, EventOutput> call(EventCreateInput input) {
    return _repository.createEvent(input);
  }
}
