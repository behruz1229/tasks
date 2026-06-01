import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    _tasksFuture = DatabaseHelper.instance.getCompletedTasks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Нет выполненных задач', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Удалить все выполненные'),
                onPressed: _deleteAllCompleted,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _loadTasks());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskCard(
                      task: tasks[index],
                      onToggleComplete: _onRestoreTask,
                      onEdit: _onEditTask,
                      onDelete: _onDeleteTask, // 🔹 Теперь кнопка удаления работает
                      isCompleted: true,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onRestoreTask(Task task) async {
    await DatabaseHelper.instance.restoreTask(task.id!);
    setState(() => _loadTasks());
  }

  void _onEditTask(Task task) async {
    final result = await Navigator.push<Task?>(
      context,
      MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
    );

    if (result != null && mounted) {
      await DatabaseHelper.instance.updateTask(
        result.copyWith(isCompleted: false, completedAt: null),
      );
      setState(() => _loadTasks());
    }
  }

  void _onDeleteTask(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.moveToTrash(id);
      setState(() => _loadTasks());
    }
  }

  void _deleteAllCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все?'),
        content: const Text('Задачи переместятся в корзину.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final tasks = await DatabaseHelper.instance.getCompletedTasks();
      for (var t in tasks) {
        await DatabaseHelper.instance.moveToTrash(t.id!);
      }
      setState(() => _loadTasks());
    }
  }
}