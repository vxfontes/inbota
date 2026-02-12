import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/tasks/data/repositories/task_repository.dart';
import 'package:inbota/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:inbota/modules/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:inbota/modules/tasks/domain/usecases/update_task_usecase.dart';

class TasksModule {
  static void binds(Injector i) {
    // repository
    i.addLazySingleton<ITaskRepository>(TaskRepository.new);

    // usecases
    i.addLazySingleton<GetTasksUsecase>(GetTasksUsecase.new);
    i.addLazySingleton<UpdateTaskUsecase>(UpdateTaskUsecase.new);
  }
}
