import 'package:firebase_todo_list_app/controller/todo_controller.dart';
import 'package:firebase_todo_list_app/model/todolist.dart';
import 'package:firebase_todo_list_app/view/delete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

/// Todo 목록과 추가 및 삭제 진입 기능을 제공하는 메인 화면입니다.
class Home extends StatelessWidget {
  const Home({super.key, this.controller});

  final TodoController? controller;

  @override
  Widget build(BuildContext context) {
    final todoController = controller ?? Get.find<TodoController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Todo Lists'),
        actions: [
          IconButton(
            key: const Key('openDeletedButton'),
            tooltip: '삭제 목록',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Delete(controller: todoController),
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            key: const Key('addTodoButton'),
            tooltip: 'Todo 추가',
            onPressed: () => _showAddDialog(context, todoController),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Obx(() => _buildBody(context, todoController)),
    );
  }

  /// 로딩, 오류, 빈 목록과 Todo 목록 상태를 구분해 표시합니다.
  Widget _buildBody(BuildContext context, TodoController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = controller.errorMessage.value;
    if (controller.todos.isEmpty) {
      return Center(
        child: Text(
          error ?? '등록된 Todo가 없습니다.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Column(
      children: [
        if (error != null)
          _ErrorBanner(message: error, onClose: controller.clearError),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: controller.todos.length,
            itemBuilder: (context, index) {
              final todo = controller.todos[index];
              return _TodoCard(todo: todo, controller: controller);
            },
          ),
        ),
      ],
    );
  }

  /// 입력 Dialog에서 검증과 저장 상태를 함께 보여줍니다.
  Future<void> _showAddDialog(
    BuildContext context,
    TodoController controller,
  ) async {
    controller.clearError();
    await showDialog<void>(
      context: context,
      builder: (_) => _AddTodoDialog(controller: controller),
    );
  }
}

/// Dialog가 사라질 때 입력 컨트롤러도 함께 안전하게 정리합니다.
class _AddTodoDialog extends StatefulWidget {
  const _AddTodoDialog({required this.controller});

  final TodoController controller;

  @override
  State<_AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<_AddTodoDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Todo List'),
      content: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('todoInput'),
              controller: _textController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '추가할 내용'),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.controller.errorMessage.value case final message?) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Obx(
          () => TextButton(
            key: const Key('submitTodoButton'),
            onPressed: widget.controller.isAdding.value ? null : _submit,
            child: widget.controller.isAdding.value
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('추가하기'),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final saved = await widget.controller.addTodo(_textController.text);
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Todo 한 건을 카드로 표시하고 왼쪽 Swipe 삭제를 제공합니다.
class _TodoCard extends StatelessWidget {
  const _TodoCard({required this.todo, required this.controller});

  final TodoList todo;
  final TodoController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: Key('todoCard-${todo.id}'),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              key: Key('deleteTodo-${todo.id}'),
              onPressed: (_) => _delete(context),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '삭제',
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          color: const Color(0xFFFFF7FF),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            minTileHeight: 76,
            leading: const Icon(Icons.calendar_month),
            title: Text(
              '${todo.content}  /  ${_formatDate(todo.createdAt?.toDate())}',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final deleted = await controller.deleteTodo(todo);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage.value ?? '삭제하지 못했습니다.')),
      );
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      actions: [TextButton(onPressed: onClose, child: const Text('닫기'))],
    );
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
