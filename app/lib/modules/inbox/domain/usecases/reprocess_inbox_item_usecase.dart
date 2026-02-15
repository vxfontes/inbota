import 'package:inbota/modules/inbox/data/models/inbox_item_output.dart';
import 'package:inbota/modules/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class ReprocessInboxItemUsecase extends IBUsecase {
  ReprocessInboxItemUsecase(this._repository);

  final IInboxRepository _repository;

  UsecaseResponse<Failure, InboxItemOutput> call(String id) {
    return _repository.reprocessInboxItem(id);
  }
}
