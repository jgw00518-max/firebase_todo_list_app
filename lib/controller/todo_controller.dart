import 'dart:async';

import 'package:firebase_todo_list_app/model/todolist.dart';
import 'package:firebase_todo_list_app/repository/todo_repository.dart';
import 'package:get/get.dart';

/// Repository의 Todo 데이터를 화면에서 사용할 반응형 상태로 관리합니다.
class TodoController extends GetxController {
  TodoController({required this.repository});

  final TodoRepositoryBase repository;
  StreamSubscription<List<TodoList>>? _todoSubscription;
  StreamSubscription<List<DeletedTodoList>>? _deletedTodoSubscription;

  final RxList<TodoList> todos = <TodoList>[].obs;
  final RxList<DeletedTodoList> deletedTodos = <DeletedTodoList>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isDeletedLoading = true.obs;
  final RxBool isAdding = false.obs;
  final RxSet<String> deletingTodoIds = <String>{}.obs;
  final RxSet<String> restoringTodoIds = <String>{}.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    _watchTodos();
    _watchDeletedTodos();
  }

  /// 삭제된 Todo 목록을 실시간으로 구독합니다.
  void _watchDeletedTodos() {
    isDeletedLoading.value = true;

    _deletedTodoSubscription = repository.watchDeletedTodos().listen(
      (items) {
        deletedTodos.assignAll(items);
        isDeletedLoading.value = false;
      },
      onError: (Object error) {
        isDeletedLoading.value = false;
        errorMessage.value = '삭제 목록을 불러오지 못했습니다.';
      },
    );
  }

  /// Todo 실시간 목록을 구독하고 로딩 및 오류 상태를 갱신합니다.
  void _watchTodos() {
    isLoading.value = true;
    errorMessage.value = null;

    _todoSubscription = repository.watchTodos().listen(
      (items) {
        todos.assignAll(items);
        isLoading.value = false;
      },
      onError: (Object error) {
        isLoading.value = false;
        errorMessage.value = 'Todo 목록을 불러오지 못했습니다.';
      },
    );
  }

  /// Todo를 추가하고 성공 여부를 화면에 전달합니다.
  Future<bool> addTodo(String content) async {
    if (content.trim().isEmpty) {
      errorMessage.value = 'Todo 내용을 입력해주세요.';
      return false;
    }

    isAdding.value = true;
    errorMessage.value = null;
    try {
      await repository.addTodo(content);
      return true;
    } catch (_) {
      errorMessage.value = 'Todo를 추가하지 못했습니다.';
      return false;
    } finally {
      isAdding.value = false;
    }
  }

  /// 선택한 Todo를 삭제 목록으로 이동하고 처리 상태를 관리합니다.
  Future<bool> deleteTodo(TodoList todo) async {
    if (deletingTodoIds.contains(todo.id)) {
      return false;
    }

    deletingTodoIds.add(todo.id);
    errorMessage.value = null;
    try {
      await repository.deleteTodo(todo);
      return true;
    } catch (_) {
      errorMessage.value = 'Todo를 삭제하지 못했습니다.';
      return false;
    } finally {
      deletingTodoIds.remove(todo.id);
    }
  }

  /// 삭제된 Todo를 원래 목록으로 복구합니다.
  Future<bool> restoreTodo(DeletedTodoList todo) async {
    if (restoringTodoIds.contains(todo.id)) {
      return false;
    }

    restoringTodoIds.add(todo.id);
    errorMessage.value = null;
    try {
      await repository.restoreTodo(todo);
      return true;
    } catch (_) {
      errorMessage.value = 'Todo를 복구하지 못했습니다.';
      return false;
    } finally {
      restoringTodoIds.remove(todo.id);
    }
  }

  /// 화면에 표시한 오류 메시지를 초기화합니다.
  void clearError() {
    errorMessage.value = null;
  }

  @override
  void onClose() {
    _todoSubscription?.cancel();
    _deletedTodoSubscription?.cancel();
    super.onClose();
  }
}
