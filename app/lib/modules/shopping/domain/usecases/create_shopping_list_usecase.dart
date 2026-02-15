import 'package:inbota/modules/shopping/data/models/shopping_list_create_input.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class CreateShoppingListUsecase extends IBUsecase {
  CreateShoppingListUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingListOutput> call(
    ShoppingListCreateInput input,
  ) {
    return _repository.createShoppingList(input);
  }
}
