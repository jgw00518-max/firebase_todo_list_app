import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_todo_list_app/model/todolist.dart';

/// Controller가 사용하는 Todo 데이터 작업의 계약을 정의합니다.
abstract interface class TodoRepositoryBase {
  Stream<List<TodoList>> watchTodos();

  Stream<List<DeletedTodoList>> watchDeletedTodos();

  Future<void> addTodo(String content);

  Future<void> deleteTodo(TodoList todo);

  Future<void> restoreTodo(DeletedTodoList todo);
}

/// Todo 문서의 조회, 추가, 삭제 이동을 Firestore와 연결합니다.
class TodoRepository implements TodoRepositoryBase {
  TodoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _todos =>
      _firestore.collection(TodoCollections.todos);

  CollectionReference<Map<String, dynamic>> get _deletedTodos =>
      _firestore.collection(TodoCollections.deletedTodos);

  /// 작성일이 최신인 Todo부터 실시간으로 전달합니다.
  @override
  Stream<List<TodoList>> watchTodos() {
    return _todos
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => TodoList.fromMap(document.id, document.data()))
              .toList(growable: false),
        );
  }

  /// 최근 삭제한 Todo부터 삭제 목록으로 전달합니다.
  @override
  Stream<List<DeletedTodoList>> watchDeletedTodos() {
    return _deletedTodos
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    DeletedTodoList.fromMap(document.id, document.data()),
              )
              .toList(growable: false),
        );
  }

  /// 입력 내용을 정리한 뒤 작성일을 서버 시간으로 저장합니다.
  @override
  Future<void> addTodo(String content) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw ArgumentError.value(content, 'content', 'Todo 내용을 입력해야 합니다.');
    }

    await _todos.add(TodoList.createData(trimmedContent));
  }

  /// 원본 문서를 삭제 컬렉션으로 옮긴 뒤 Todo 목록에서 제거합니다.
  @override
  Future<void> deleteTodo(TodoList todo) async {
    final todoReference = _todos.doc(todo.id);
    final deletedTodoReference = _deletedTodos.doc(todo.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(todoReference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw StateError('삭제할 Todo 문서를 찾을 수 없습니다: ${todo.id}');
      }

      final savedTodo = TodoList.fromMap(snapshot.id, data);
      transaction.set(
        deletedTodoReference,
        DeletedTodoList.createData(savedTodo),
      );
      transaction.delete(todoReference);
    });
  }

  /// 삭제 문서를 원래 Todo 컬렉션으로 되돌린 뒤 삭제 목록에서 제거합니다.
  @override
  Future<void> restoreTodo(DeletedTodoList todo) async {
    final todoReference = _todos.doc(todo.id);
    final deletedTodoReference = _deletedTodos.doc(todo.id);

    await _firestore.runTransaction((transaction) async {
      final deletedSnapshot = await transaction.get(deletedTodoReference);
      final deletedData = deletedSnapshot.data();
      final activeSnapshot = await transaction.get(todoReference);

      if (!deletedSnapshot.exists || deletedData == null) {
        throw StateError('복구할 Todo 문서를 찾을 수 없습니다: ${todo.id}');
      }
      if (activeSnapshot.exists) {
        throw StateError('같은 ID의 Todo 문서가 이미 존재합니다: ${todo.id}');
      }

      final savedTodo = DeletedTodoList.fromMap(
        deletedSnapshot.id,
        deletedData,
      );
      transaction.set(todoReference, TodoList.restoreData(savedTodo));
      transaction.delete(deletedTodoReference);
    });
  }
}
