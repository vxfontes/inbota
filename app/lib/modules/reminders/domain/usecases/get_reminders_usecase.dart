import 'package:inbota/modules/reminders/data/models/reminder_list_output.dart';
import 'package:inbota/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetRemindersUsecase extends IBUsecase {
  final IReminderRepository _repository;

  GetRemindersUsecase(this._repository);

  UsecaseResponse<Failure, ReminderListOutput> call({
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchReminders(limit: limit, cursor: cursor);
  }
}
