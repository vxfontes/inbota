import 'package:inbota/modules/shopping/data/models/shopping_list_list_output.dart';
import 'package:inbota/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetShoppingListsUsecase extends IBUsecase {
  GetShoppingListsUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingListListOutput> call({
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchShoppingLists(limit: limit, cursor: cursor);
  }
}
