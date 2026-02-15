import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/events/data/repositories/event_repository.dart';
import 'package:inbota/modules/events/domain/repositories/i_event_repository.dart';
import 'package:inbota/modules/events/domain/usecases/get_events_usecase.dart';

class EventsModule {
  static void binds(Injector i) {
    i.addLazySingleton<IEventRepository>(EventRepository.new);
    i.addLazySingleton<GetEventsUsecase>(GetEventsUsecase.new);
  }
}
