import 'dart:async';

import 'package:firebase_todo_list_app/controller/todo_controller.dart';
import 'package:firebase_todo_list_app/model/todolist.dart';
import 'package:firebase_todo_list_app/repository/todo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTodoRepository implements TodoRepositoryBase {
  final StreamController<List<TodoList>> streamController =
      StreamController<List<TodoList>>();
  final StreamController<List<DeletedTodoList>> deletedStreamController =
      StreamController<List<DeletedTodoList>>();

  String? addedContent;
  TodoList? deletedTodo;
  DeletedTodoList? restoredTodo;
  Object? addError;
  Object? deleteError;
  Object? restoreError;

  @override
  Stream<List<TodoList>> watchTodos() => streamController.stream;

  @override
  Stream<List<DeletedTodoList>> watchDeletedTodos() =>
      deletedStreamController.stream;

  @override
  Future<void> addTodo(String content) async {
    if (addError case final error?) {
      throw error;
    }
    addedContent = content;
  }

  @override
  Future<void> deleteTodo(TodoList todo) async {
    if (deleteError case final error?) {
      throw error;
    }
    deletedTodo = todo;
  }

  @override
  Future<void> restoreTodo(DeletedTodoList todo) async {
    if (restoreError case final error?) {
      throw error;
    }
    restoredTodo = todo;
  }

  Future<void> close() async {
    await streamController.close();
    await deletedStreamController.close();
  }
}

void main() {
  late FakeTodoRepository repository;
  late TodoController controller;

  setUp(() {
    repository = FakeTodoRepository();
    controller = TodoController(repository: repository);
    controller.onInit();
  });

  tearDown(() async {
    controller.onClose();
    await repository.close();
  });

  test('실시간 Todo 목록을 화면 상태에 반영한다', () async {
    const todo = TodoList(id: 'todo-1', content: '회의', createdAt: null);

    repository.streamController.add([todo]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.todos, [todo]);
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, isNull);
  });

  test('빈 내용은 Repository에 전달하지 않는다', () async {
    final result = await controller.addTodo('   ');

    expect(result, isFalse);
    expect(repository.addedContent, isNull);
    expect(controller.errorMessage.value, 'Todo 내용을 입력해주세요.');
  });

  test('Todo 추가와 삭제를 Repository에 전달한다', () async {
    const todo = TodoList(id: 'todo-1', content: '회의', createdAt: null);

    final added = await controller.addTodo('회의');
    final deleted = await controller.deleteTodo(todo);

    expect(added, isTrue);
    expect(deleted, isTrue);
    expect(repository.addedContent, '회의');
    expect(repository.deletedTodo, todo);
    expect(controller.isAdding.value, isFalse);
    expect(controller.deletingTodoIds, isEmpty);
  });

  test('삭제 목록과 복구 요청을 Repository에 전달한다', () async {
    const todo = DeletedTodoList(
      id: 'todo-1',
      content: '회의',
      createdAt: null,
      deletedAt: null,
    );

    repository.deletedStreamController.add([todo]);
    await Future<void>.delayed(Duration.zero);
    final restored = await controller.restoreTodo(todo);

    expect(controller.deletedTodos, [todo]);
    expect(controller.isDeletedLoading.value, isFalse);
    expect(restored, isTrue);
    expect(repository.restoredTodo, todo);
    expect(controller.restoringTodoIds, isEmpty);
  });
}
