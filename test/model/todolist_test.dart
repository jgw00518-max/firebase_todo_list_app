import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_todo_list_app/model/todolist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoList', () {
    test('Firestore 문서를 Todo 객체로 변환한다', () {
      final createdAt = Timestamp.fromDate(DateTime(2025, 4, 9));

      final todo = TodoList.fromMap('todo-1', {
        'content': '철수와 약속',
        'createdAt': createdAt,
      });

      expect(todo.id, 'todo-1');
      expect(todo.content, '철수와 약속');
      expect(todo.createdAt, createdAt);
    });

    test('새 Todo 데이터는 공백을 제거하고 서버 시간을 사용한다', () {
      final data = TodoList.createData('  철수와 약속  ');

      expect(data['content'], '철수와 약속');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });

  group('DeletedTodoList', () {
    test('삭제 데이터는 작성일을 유지하고 삭제 시각에 서버 시간을 사용한다', () {
      final createdAt = Timestamp.fromDate(DateTime(2025, 4, 9));
      final todo = TodoList(
        id: 'todo-1',
        content: '철수와 약속',
        createdAt: createdAt,
      );

      final data = DeletedTodoList.createData(todo);

      expect(data['content'], '철수와 약속');
      expect(data['createdAt'], createdAt);
      expect(data['deletedAt'], isA<FieldValue>());
    });
  });
}
