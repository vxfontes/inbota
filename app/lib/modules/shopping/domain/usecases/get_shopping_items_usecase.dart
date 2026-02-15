import 'package:inbota/modules/shopping/data/models/shopping_item_list_output.dart';
import 'package:inbota/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetShoppingItemsUsecase extends IBUsecase {
  GetShoppingItemsUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingItemListOutput> call({
    required String listId,
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchShoppingItems(
      listId: listId,
      limit: limit,
      cursor: cursor,
    );
  }
}
