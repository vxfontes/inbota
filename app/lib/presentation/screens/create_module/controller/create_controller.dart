import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:inbota/modules/inbox/data/models/inbox_confirm_input.dart';
import 'package:inbota/modules/inbox/data/models/inbox_confirm_output.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_input.dart';
import 'package:inbota/modules/inbox/data/models/inbox_item_output.dart';
import 'package:inbota/modules/inbox/domain/usecases/confirm_inbox_item_usecase.dart';
import 'package:inbota/modules/inbox/domain/usecases/create_inbox_item_usecase.dart';
import 'package:inbota/modules/inbox/domain/usecases/reprocess_inbox_item_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

enum CreateLineStatus { success, failed }

class CreateLineResult {
  const CreateLineResult({
    required this.sourceText,
    required this.status,
    required this.message,
  });

  final String sourceText;
  final CreateLineStatus status;
  final String message;
}

class CreateBatchResult {
  const CreateBatchResult({
    required this.totalInputs,
    required this.successCount,
    required this.failedCount,
    required this.tasksCount,
    required this.remindersCount,
    required this.eventsCount,
    required this.shoppingListsCount,
    required this.shoppingItemsCount,
    required this.lines,
  });

  final int totalInputs;
  final int successCount;
  final int failedCount;
  final int tasksCount;
  final int remindersCount;
  final int eventsCount;
  final int shoppingListsCount;
  final int shoppingItemsCount;
  final List<CreateLineResult> lines;
}

class CreateController implements IBController {
  CreateController(
    this._createInboxItemUsecase,
    this._reprocessInboxItemUsecase,
    this._confirmInboxItemUsecase,
  );

  final CreateInboxItemUsecase _createInboxItemUsecase;
  final ReprocessInboxItemUsecase _reprocessInboxItemUsecase;
  final ConfirmInboxItemUsecase _confirmInboxItemUsecase;

  final TextEditingController inputController = TextEditingController();
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<CreateBatchResult?> batchResult = ValueNotifier(null);

  @override
  void dispose() {
    inputController.dispose();
    loading.dispose();
    error.dispose();
    batchResult.dispose();
  }

  void clearInput() {
    inputController.clear();
    error.value = null;
  }

  Future<bool> processText() async {
    if (loading.value) return false;

    final rawText = inputController.text;
    final lines = _extractLines(rawText);
    if (lines.isEmpty) {
      error.value = 'Digite algo para processar com IA.';
      return false;
    }

    loading.value = true;
    error.value = null;

    var success = 0;
    var failed = 0;
    var tasks = 0;
    var reminders = 0;
    var events = 0;
    var shoppingLists = 0;
    var shoppingItems = 0;

    final lineResults = <CreateLineResult>[];

    for (final line in lines) {
      final processing = await _processSingleLine(line);

      processing.fold(
        (failureMessage) {
          failed++;
          lineResults.add(
            CreateLineResult(
              sourceText: line,
              status: CreateLineStatus.failed,
              message: failureMessage,
            ),
          );
        },
        (output) {
          success++;

          final type = output.type.trim().toLowerCase();
          switch (type) {
            case 'task':
              tasks++;
              break;
            case 'reminder':
              reminders++;
              break;
            case 'event':
              events++;
              break;
            case 'shopping':
              if (output.shoppingList != null) {
                shoppingLists++;
              }
              shoppingItems += output.shoppingItems.length;
              break;
          }

          final entityLabel = _entityLabel(type);
          lineResults.add(
            CreateLineResult(
              sourceText: line,
              status: CreateLineStatus.success,
              message: '$entityLabel criado com sucesso.',
            ),
          );
        },
      );
    }

    batchResult.value = CreateBatchResult(
      totalInputs: lines.length,
      successCount: success,
      failedCount: failed,
      tasksCount: tasks,
      remindersCount: reminders,
      eventsCount: events,
      shoppingListsCount: shoppingLists,
      shoppingItemsCount: shoppingItems,
      lines: lineResults,
    );

    loading.value = false;

    if (failed > 0 && success == 0) {
      error.value = 'Nao foi possivel processar os textos enviados.';
      return false;
    }

    return true;
  }

  Future<Either<String, InboxConfirmOutput>> _processSingleLine(
    String line,
  ) async {
    final createResult = await _createInboxItemUsecase.call(
      InboxCreateInput(source: 'manual', rawText: line),
    );

    final createdItem = createResult.fold<InboxItemOutput?>(
      (failure) {
        return null;
      },
      (item) {
        return item;
      },
    );

    if (createdItem == null) {
      return Left(_failureMessage(createResult));
    }

    final reprocessResult = await _reprocessInboxItemUsecase.call(
      createdItem.id,
    );
    final processedItem = reprocessResult.fold<InboxItemOutput?>(
      (failure) {
        return null;
      },
      (item) {
        return item;
      },
    );

    if (processedItem == null) {
      return Left(_failureMessage(reprocessResult));
    }

    final confirmInput = InboxConfirmInput.fromSuggestion(
      processedItem,
      fallbackTitle: line,
    );

    if (!confirmInput.isValidForConfirm) {
      return const Left('A IA nao retornou dados suficientes para confirmar.');
    }

    final confirmResult = await _confirmInboxItemUsecase.call(confirmInput);
    return confirmResult.fold(
      (failure) => Left(
        (failure.message?.trim().isNotEmpty ?? false)
            ? failure.message!.trim()
            : 'Falha ao confirmar item processado.',
      ),
      Right.new,
    );
  }

  String _failureMessage(Either<Failure, dynamic> either) {
    return either.fold((failure) {
      final message = failure.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return 'Falha no processamento.';
    }, (_) => 'Falha no processamento.');
  }

  List<String> _extractLines(String rawText) {
    final normalized = rawText.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];

    final candidateLines = normalized.split('\n');
    final lines = <String>[];

    for (final candidate in candidateLines) {
      final cleaned = _normalizeLine(candidate);
      if (cleaned.isNotEmpty) {
        lines.add(cleaned);
      }
    }

    if (lines.isNotEmpty) return lines;

    final fallback = _normalizeLine(normalized);
    if (fallback.isEmpty) return const [];
    return [fallback];
  }

  String _normalizeLine(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final withoutBullet = trimmed.replaceFirst(RegExp(r'^[-*•\d\.)\s]+'), '');

    return withoutBullet.trim();
  }

  String _entityLabel(String type) {
    switch (type) {
      case 'task':
        return 'To-do';
      case 'reminder':
        return 'Lembrete';
      case 'event':
        return 'Evento';
      case 'shopping':
        return 'Lista de compras';
      default:
        return 'Item';
    }
  }
}
