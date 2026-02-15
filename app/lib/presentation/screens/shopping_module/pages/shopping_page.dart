import 'package:flutter/material.dart';

import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/presentation/screens/shopping_module/controller/shopping_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends IBState<ShoppingPage, ShoppingController> {
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.error,
        controller.shoppingLists,
        controller.itemsByList,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final error = controller.error.value;
        final shoppingLists = controller.shoppingLists.value;
        final itemsByList = controller.itemsByList.value;

        final showFullLoading = loading && shoppingLists.isEmpty;

        return Stack(
          children: [
            ColoredBox(
              color: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _buildHeader(context),
                  if (error != null && error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    IBText(
                      error,
                      context: context,
                    ).caption.color(AppColors.danger600).build(),
                  ],
                  const SizedBox(height: 18),
                  if (shoppingLists.isEmpty)
                    const IBCard(
                      child: IBEmptyState(
                        title: 'Sem listas de compras',
                        subtitle:
                            'Quando você confirmar uma lista pelo inbox, ela aparecerá aqui.',
                        icon: IBHugeIcon.shoppingBag,
                      ),
                    )
                  else
                    ...shoppingLists.map((shoppingList) {
                      final items = itemsByList[shoppingList.id] ?? const [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildShoppingListCard(
                          context,
                          shoppingList: shoppingList,
                          items: items,
                        ),
                      );
                    }),
                ],
              ),
            ),
            if (showFullLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background,
                  child: Center(
                    child: IBLoader(label: 'Carregando listas de compras...'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Compras', context: context).titulo.build(),
        const SizedBox(height: 6),
        IBText(
          'Todas as suas listas e itens para comprar em um só lugar.',
          context: context,
        ).muted.build(),
      ],
    );
  }

  Widget _buildShoppingListCard(
    BuildContext context, {
    required ShoppingListOutput shoppingList,
    required List<ShoppingItemOutput> items,
  }) {
    final doneCount = items.where((item) => item.isDone).length;
    final pendingCount = items.length - doneCount;

    return IBTodoList(
      title: shoppingList.title,
      subtitle: '$pendingCount pendente(s) de ${items.length} item(ns)',
      items: items
          .map(
            (item) => IBTodoItemData(
              title: item.title,
              subtitle: _itemSubtitle(item),
              done: item.isDone,
            ),
          )
          .toList(),
      emptyLabel: 'Nenhum item nesta lista.',
      onToggle: (index, done) {
        controller.toggleItemAt(shoppingList.id, index, done);
      },
    );
  }

  String? _itemSubtitle(ShoppingItemOutput item) {
    final quantity = item.quantity?.trim();
    if (quantity == null || quantity.isEmpty) return null;
    return 'Quantidade: $quantity';
  }
}
