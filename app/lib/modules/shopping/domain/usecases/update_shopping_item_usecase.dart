import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_update_input.dart';
import 'package:inbota/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class UpdateShoppingItemUsecase extends IBUsecase {
  UpdateShoppingItemUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingItemOutput> call(
    ShoppingItemUpdateInput input,
  ) {
    return _repository.updateShoppingItem(input);
  }
}
