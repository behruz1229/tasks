import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../widgets/task_card.dart';
import '../providers/settings_provider.dart';
import 'add_edit_task_screen.dart';

class ActiveTasksScreen extends StatefulWidget {
  const ActiveTasksScreen({super.key});

  @override
  State<ActiveTasksScreen> createState() => _ActiveTasksScreenState();
}

class _ActiveTasksScreenState extends State<ActiveTasksScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    Provider.of<SettingsProvider>(context, listen: false).addListener(_applyFilters);
  }

  @override
  void dispose() {
    Provider.of<SettingsProvider>(context, listen: false).removeListener(_applyFilters);
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper.instance.getActiveTasks();
    setState(() {
      _allTasks.clear();
      _allTasks.addAll(tasks);
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    setState(() {
      _filteredTasks = settings.filterTasks(_allTasks);
    });
  }

  // 🔹 ИСПРАВЛЕНО: правильное удаление из AnimatedList
  void _removeTask(Task task) {
    final index = _filteredTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _filteredTasks.removeAt(index);
      _allTasks.remove(task);
      _listKey.currentState?.removeItem(
        index,
            (context, animation) => _buildTaskItem(task, animation),
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Widget _buildTaskItem(Task task, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: animation,
        child: TaskCard(
          key: ValueKey(task.id),
          task: task,
          onToggleComplete: (task) async {
            // 🔹 ИСПРАВЛЕНО: сначала удаляем из UI, потом из БД
            _removeTask(task);
            await DatabaseHelper.instance.updateTask(
              task.copyWith(isCompleted: true, completedAt: DateTime.now()),
            );
            // Перезагружаем через небольшую задержку
            Future.delayed(const Duration(milliseconds: 400), _loadTasks);
          },
          onEdit: _onEditTask,
          onDelete: (id) async {
            final task = _allTasks.firstWhere((t) => t.id == id);
            _removeTask(task);
            await DatabaseHelper.instance.moveToTrash(id);
            if (mounted) {
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredTasks.isEmpty) {
      final hasFilters = settings.searchQuery.isNotEmpty || settings.priorityFilter != null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(hasFilters ? Icons.filter_alt_off : Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Ничего не найдено' : 'Нет активных задач',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Сбросить фильтры'),
                onPressed: () => settings.clearFilters(),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text('Нажми "+" чтобы добавить', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: AnimatedList(
        key: _listKey,
        padding: const EdgeInsets.all(16),
        initialItemCount: _filteredTasks.length,
        itemBuilder: (context, index, animation) {
          if (index >= _filteredTasks.length) {
            return const SizedBox.shrink(); // 🔹 Защита от выхода за границы
          }
          return _buildTaskItem(_filteredTasks[index], animation);
        },
      ),
    );
  }

  void _onEditTask(Task task) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddEditTaskScreen(task: task),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: FadeTransition(opacity: animation, child: child));
        },
      ),
    ).then((_) => _loadTasks());
  }
}