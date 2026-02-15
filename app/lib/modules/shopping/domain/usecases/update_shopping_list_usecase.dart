import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_update_input.dart';
import 'package:inbota/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class UpdateShoppingListUsecase extends IBUsecase {
  UpdateShoppingListUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingListOutput> call(
    ShoppingListUpdateInput input,
  ) {
    return _repository.updateShoppingList(input);
  }
}
