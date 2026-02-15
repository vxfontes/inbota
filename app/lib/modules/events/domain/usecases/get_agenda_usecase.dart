import 'package:inbota/modules/events/data/models/agenda_output.dart';
import 'package:inbota/modules/events/domain/repositories/i_event_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetAgendaUsecase extends IBUsecase {
  GetAgendaUsecase(this._repository);

  final IEventRepository _repository;

  UsecaseResponse<Failure, AgendaOutput> call({int? limit}) {
    return _repository.fetchAgenda(limit: limit);
  }
}
