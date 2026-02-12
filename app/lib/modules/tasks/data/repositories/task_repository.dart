import 'package:dartz/dartz.dart';

import 'package:inbota/modules/tasks/data/models/task_list_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/modules/tasks/data/models/task_update_input.dart';
import 'package:inbota/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class TaskRepository implements ITaskRepository {
  TaskRepository(this._httpClient);

  final IHttpClient _httpClient;
  final String _path = '/tasks';

  @override
  Future<Either<Failure, TaskListOutput>> fetchTasks({int? limit, String? cursor}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        _path,
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final data = _asMap(response.data);
        return Right(TaskListOutput.fromJson(data));
      }

      return Left(GetListFailure(message: _extractMessage(response.data)));
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskOutput>> updateTask(TaskUpdateInput input) async {
    try {
      final path = '$_path/${input.id}';
      final response = await _httpClient.patch(
        path,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(TaskOutput.fromJson(_asMap(response.data)));
      }

      return Left(UpdateFailure(message: _extractMessage(response.data)));
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  String _extractMessage(dynamic data) {
    if (data is Map) {
      final map = data.map((key, value) => MapEntry(key.toString(), value));
      final error = map['error']?.toString();
      if (error != null && error.isNotEmpty) {
        return _mapErrorCode(error);
      }
      return map['message']?.toString() ?? 'Erro ao carregar tarefas.';
    }
    return 'Erro ao carregar tarefas.';
  }

  String _mapErrorCode(String error) {
    switch (error) {
      case 'connection_refused':
        return 'Sem conexao com o servidor.';
      case 'timeout':
        return 'Tempo de conexao esgotado.';
      default:
        return error;
    }
  }
}
