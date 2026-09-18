import 'package:cloud_firestore/cloud_firestore.dart';

/// Todo 문서가 저장되는 Firestore 컬렉션 이름을 관리합니다.
abstract final class TodoCollections {
  static const String todos = 'todos';
  static const String deletedTodos = 'deleted_todos';
}

/// `todos/{todoId}` 문서를 앱에서 사용하는 형태로 표현합니다.
class TodoList {
  const TodoList({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final Timestamp? createdAt;

  /// Firestore에서 읽은 문서 데이터를 Todo 객체로 변환합니다.
  factory TodoList.fromMap(String id, Map<String, dynamic> data) {
    return TodoList(
      id: id,
      content: data['content'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// 새 Todo를 저장할 때 서버 시간을 작성일로 사용합니다.
  static Map<String, dynamic> createData(String content) {
    return {
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// 삭제된 Todo를 복구할 때 원래 내용과 작성일을 유지합니다.
  static Map<String, dynamic> restoreData(DeletedTodoList todo) {
    return {'content': todo.content, 'createdAt': todo.createdAt};
  }
}

/// `deleted_todos/{todoId}` 문서를 앱에서 사용하는 형태로 표현합니다.
class DeletedTodoList {
  const DeletedTodoList({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.deletedAt,
  });

  final String id;
  final String content;
  final Timestamp? createdAt;
  final Timestamp? deletedAt;

  /// Firestore에서 읽은 삭제 문서 데이터를 객체로 변환합니다.
  factory DeletedTodoList.fromMap(String id, Map<String, dynamic> data) {
    return DeletedTodoList(
      id: id,
      content: data['content'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      deletedAt: data['deletedAt'] as Timestamp?,
    );
  }

  /// Todo 삭제 시 원래 작성일을 유지하고 삭제 시각은 서버 시간으로 기록합니다.
  static Map<String, dynamic> createData(TodoList todo) {
    return {
      'content': todo.content,
      'createdAt': todo.createdAt,
      'deletedAt': FieldValue.serverTimestamp(),
    };
  }
}
