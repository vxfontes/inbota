import 'package:inbota/modules/events/data/models/event_list_output.dart';
import 'package:inbota/modules/events/domain/repositories/i_event_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetEventsUsecase extends IBUsecase {
  GetEventsUsecase(this._repository);

  final IEventRepository _repository;

  UsecaseResponse<Failure, EventListOutput> call({int? limit, String? cursor}) {
    return _repository.fetchEvents(limit: limit, cursor: cursor);
  }
}
