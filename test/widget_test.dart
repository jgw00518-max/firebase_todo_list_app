import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_todo_list_app/controller/todo_controller.dart';
import 'package:firebase_todo_list_app/model/todolist.dart';
import 'package:firebase_todo_list_app/repository/todo_repository.dart';
import 'package:firebase_todo_list_app/view/delete.dart';
import 'package:firebase_todo_list_app/view/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class WidgetFakeTodoRepository implements TodoRepositoryBase {
  final StreamController<List<TodoList>> todosController =
      StreamController<List<TodoList>>();
  final StreamController<List<DeletedTodoList>> deletedTodosController =
      StreamController<List<DeletedTodoList>>();

  String? addedContent;
  TodoList? deletedTodo;
  DeletedTodoList? restoredTodo;

  @override
  Stream<List<TodoList>> watchTodos() => todosController.stream;

  @override
  Stream<List<DeletedTodoList>> watchDeletedTodos() =>
      deletedTodosController.stream;

  @override
  Future<void> addTodo(String content) async {
    addedContent = content;
  }

  @override
  Future<void> deleteTodo(TodoList todo) async {
    deletedTodo = todo;
  }

  @override
  Future<void> restoreTodo(DeletedTodoList todo) async {
    restoredTodo = todo;
  }

  Future<void> close() async {
    await todosController.close();
    await deletedTodosController.close();
  }
}

void main() {
  late WidgetFakeTodoRepository repository;
  late TodoController controller;

  setUp(() {
    repository = WidgetFakeTodoRepository();
    controller = TodoController(repository: repository)..onInit();
  });

  tearDown(() async {
    controller.onClose();
    await repository.close();
  });

  testWidgets('빈 목록과 AppBar 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Home(controller: controller)));
    repository.todosController.add([]);
    await tester.pump();

    expect(find.text('Todo Lists'), findsOneWidget);
    expect(find.text('등록된 Todo가 없습니다.'), findsOneWidget);
    expect(find.byKey(const Key('openDeletedButton')), findsOneWidget);
    expect(find.byKey(const Key('addTodoButton')), findsOneWidget);
  });

  testWidgets('Dialog에서 Todo를 추가한다', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Home(controller: controller)));
    repository.todosController.add([]);
    await tester.pump();

    await tester.tap(find.byKey(const Key('addTodoButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('todoInput')), '철수와 약속');
    await tester.tap(find.byKey(const Key('submitTodoButton')));
    await tester.pumpAndSettle();

    expect(repository.addedContent, '철수와 약속');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Todo 카드를 왼쪽으로 밀어 삭제한다', (tester) async {
    final todo = TodoList(
      id: 'todo-1',
      content: '미팅 잡기',
      createdAt: Timestamp.fromDate(DateTime(2025, 4, 9)),
    );
    await tester.pumpWidget(MaterialApp(home: Home(controller: controller)));
    repository.todosController.add([todo]);
    await tester.pump();

    expect(find.text('미팅 잡기  /  2025-04-09'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('todoCard-todo-1')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteTodo-todo-1')));
    await tester.pump();

    expect(repository.deletedTodo, todo);
  });

  testWidgets('삭제 화면에서 Todo를 복구한다', (tester) async {
    final todo = DeletedTodoList(
      id: 'todo-1',
      content: '볼펜 사기',
      createdAt: Timestamp.fromDate(DateTime(2025, 4, 9)),
      deletedAt: Timestamp.fromDate(DateTime(2025, 4, 10)),
    );
    await tester.pumpWidget(MaterialApp(home: Delete(controller: controller)));
    repository.deletedTodosController.add([todo]);
    await tester.pump();

    expect(find.text('Delete Lists'), findsOneWidget);
    expect(find.text('볼펜 사기  /  2025-04-09'), findsOneWidget);
    await tester.tap(find.byKey(const Key('restoreTodo-todo-1')));
    await tester.pump();

    expect(repository.restoredTodo, todo);
  });
}
