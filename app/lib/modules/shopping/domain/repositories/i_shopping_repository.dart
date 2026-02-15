import 'package:dartz/dartz.dart';

import 'package:inbota/modules/shopping/data/models/shopping_item_list_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_create_input.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_update_input.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_list_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_create_input.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_update_input.dart';

abstract class IShoppingRepository {
  Future<Either<Failure, ShoppingListListOutput>> fetchShoppingLists({
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, ShoppingItemListOutput>> fetchShoppingItems({
    required String listId,
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, ShoppingItemOutput>> updateShoppingItem(
    ShoppingItemUpdateInput input,
  );

  Future<Either<Failure, ShoppingListOutput>> createShoppingList(
    ShoppingListCreateInput input,
  );

  Future<Either<Failure, ShoppingListOutput>> updateShoppingList(
    ShoppingListUpdateInput input,
  );

  Future<Either<Failure, ShoppingItemOutput>> createShoppingItem(
    ShoppingItemCreateInput input,
  );
}
