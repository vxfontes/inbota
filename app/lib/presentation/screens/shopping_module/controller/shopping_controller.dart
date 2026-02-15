import 'package:flutter/material.dart';

import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_update_input.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/modules/shopping/domain/usecases/get_shopping_items_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/get_shopping_lists_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/update_shopping_item_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class ShoppingController implements IBController {
  ShoppingController(
    this._getShoppingListsUsecase,
    this._getShoppingItemsUsecase,
    this._updateShoppingItemUsecase,
  );

  final GetShoppingListsUsecase _getShoppingListsUsecase;
  final GetShoppingItemsUsecase _getShoppingItemsUsecase;
  final UpdateShoppingItemUsecase _updateShoppingItemUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<ShoppingListOutput>> shoppingLists = ValueNotifier(
    [],
  );
  final ValueNotifier<Map<String, List<ShoppingItemOutput>>> itemsByList =
      ValueNotifier({});

  final Set<String> _updatingItemIds = <String>{};

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
    shoppingLists.dispose();
    itemsByList.dispose();
  }

  Future<void> load() async {
    if (loading.value) return;

    loading.value = true;
    error.value = null;

    final listsResult = await _getShoppingListsUsecase.call(limit: 50);

    List<ShoppingListOutput> loadedLists = const [];
    final hasListFailure = listsResult.fold(
      (failure) {
        _setError(
          failure,
          fallback: 'Nao foi possivel carregar suas listas de compras.',
        );
        return true;
      },
      (data) {
        loadedLists = _safeLists(data.items);
        return false;
      },
    );

    if (hasListFailure) {
      loading.value = false;
      return;
    }

    shoppingLists.value = loadedLists;

    if (loadedLists.isEmpty) {
      itemsByList.value = {};
      loading.value = false;
      return;
    }

    final nextItemsByList = <String, List<ShoppingItemOutput>>{};

    for (final list in loadedLists) {
      final itemsResult = await _getShoppingItemsUsecase.call(
        listId: list.id,
        limit: 200,
      );

      itemsResult.fold(
        (failure) {
          _setError(
            failure,
            fallback: 'Nao foi possivel carregar todos os itens de compras.',
          );
          nextItemsByList[list.id] = const [];
        },
        (output) {
          nextItemsByList[list.id] = _safeItems(output.items);
        },
      );
    }

    itemsByList.value = nextItemsByList;
    loading.value = false;
  }

  Future<bool> toggleItemAt(String listId, int index, bool checked) async {
    final currentListItems = itemsByList.value[listId];
    if (currentListItems == null) return false;
    if (index < 0 || index >= currentListItems.length) return false;

    final currentItem = currentListItems[index];
    if (_updatingItemIds.contains(currentItem.id)) return false;

    _updatingItemIds.add(currentItem.id);

    final result = await _updateShoppingItemUsecase.call(
      ShoppingItemUpdateInput(id: currentItem.id, checked: checked),
    );

    _updatingItemIds.remove(currentItem.id);

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Nao foi possivel atualizar o item.');
        return false;
      },
      (updatedItem) {
        final nextMap = Map<String, List<ShoppingItemOutput>>.from(
          itemsByList.value,
        );
        final nextList = List<ShoppingItemOutput>.from(
          nextMap[listId] ?? const [],
        );

        final updatedIndex = nextList.indexWhere(
          (item) => item.id == updatedItem.id,
        );

        if (updatedIndex != -1) {
          nextList[updatedIndex] = updatedItem;
          nextMap[listId] = nextList;
          itemsByList.value = nextMap;
        }

        return true;
      },
    );
  }

  List<ShoppingListOutput> _safeLists(List<ShoppingListOutput> items) {
    return items.where((item) => item.id.isNotEmpty).toList();
  }

  List<ShoppingItemOutput> _safeItems(List<ShoppingItemOutput> items) {
    return items.where((item) => item.id.isNotEmpty).toList();
  }

  void _setError(Failure failure, {required String fallback}) {
    final message = failure.message?.trim();
    if (message != null && message.isNotEmpty) {
      error.value = message;
      return;
    }

    if (error.value == null || error.value!.isEmpty) {
      error.value = fallback;
    }
  }
}
