import 'package:firebase_todo_list_app/controller/todo_controller.dart';
import 'package:firebase_todo_list_app/model/todolist.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 삭제된 Todo를 확인하고 원래 목록으로 복구하는 화면입니다.
class Delete extends StatelessWidget {
  const Delete({super.key, this.controller});

  final TodoController? controller;

  @override
  Widget build(BuildContext context) {
    final todoController = controller ?? Get.find<TodoController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Delete Lists'),
      ),
      body: Obx(() {
        if (todoController.isDeletedLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (todoController.deletedTodos.isEmpty) {
          return Center(
            child: Text(todoController.errorMessage.value ?? '삭제된 Todo가 없습니다.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: todoController.deletedTodos.length,
          itemBuilder: (context, index) {
            final todo = todoController.deletedTodos[index];
            return _DeletedTodoCard(todo: todo, controller: todoController);
          },
        );
      }),
    );
  }
}

/// 삭제된 Todo 정보와 복구 버튼을 카드로 표시합니다.
class _DeletedTodoCard extends StatelessWidget {
  const _DeletedTodoCard({required this.todo, required this.controller});

  final DeletedTodoList todo;
  final TodoController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('deletedTodoCard-${todo.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFFFF7FF),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        minTileHeight: 76,
        leading: const Icon(Icons.calendar_month),
        title: Text(
          '${todo.content}  /  ${_formatDate(todo.createdAt?.toDate())}',
        ),
        trailing: Obx(
          () => IconButton(
            key: Key('restoreTodo-${todo.id}'),
            tooltip: '복구',
            onPressed: controller.restoringTodoIds.contains(todo.id)
                ? null
                : () => _restore(context),
            icon: controller.restoringTodoIds.contains(todo.id)
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore),
          ),
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final restored = await controller.restoreTodo(todo);
    if (!restored && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage.value ?? '복구하지 못했습니다.')),
      );
    }
  }
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '저장 중';
  }
  final localDate = date.toLocal();
  final month = localDate.month.toString().padLeft(2, '0');
  final day = localDate.day.toString().padLeft(2, '0');
  return '${localDate.year}-$month-$day';
}
