import 'package:dartz/dartz.dart' show Unit;
import 'package:inbota/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class DeleteShoppingListUsecase extends IBUsecase {
  DeleteShoppingListUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteShoppingList(id);
  }
}
