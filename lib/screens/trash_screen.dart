import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../widgets/task_card_trash.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    _tasksFuture = DatabaseHelper.instance.getTrashedTasks();
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
                Icon(Icons.delete_sweep_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Корзина пуста', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Очистить корзину'),
                onPressed: _clearTrash,
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
                    return TaskCardTrash(
                      task: tasks[index],
                      onRestore: _onRestore,
                      onDelete: _onDeletePermanently,
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

  void _onRestore(Task task) async {
    // 🔹 Показываем диалог выбора
    final destination = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Куда восстановить?'),
        content: const Text('Выберите, куда переместить задачу:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'active'),
            child: const Text('В Активные'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'completed'),
            child: const Text('В Выполненные'),
          ),
        ],
      ),
    );

    if (destination != null && mounted) {
      // 🔹 Создаём новую задачу с правильными полями
      final restoredTask = task.copyWith(
        isDeleted: false,
        isCompleted: destination == 'completed',
        completedAt: destination == 'completed' ? DateTime.now() : null,
      );

      // 🔹 Обновляем в базе данных
      await DatabaseHelper.instance.updateTask(restoredTask);
      setState(() => _loadTasks());
    }
  }

  void _onDeletePermanently(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
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
      await DatabaseHelper.instance.deletePermanently(id);
      setState(() => _loadTasks());
    }
  }

  void _clearTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить корзину?'),
        content: const Text('Все задачи будут удалены навсегда.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.clearTrash();
      setState(() => _loadTasks());
    }
  }
}