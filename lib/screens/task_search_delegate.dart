import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';

class TaskSearchDelegate extends SearchDelegate<Task?> {
  List<Task> _results = [];
  bool _isLoading = false;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _results.clear();
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildContent(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildContent(context);

  Widget _buildContent(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Введите минимум 2 символа для поиска', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final task = _results[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.description.isEmpty ? 'Без описания' : task.description),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriorityColor(task.priority).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getPriorityName(task.priority),
              style: TextStyle(color: _getPriorityColor(task.priority), fontSize: 12),
            ),
          ),
          // 🔹 Возвращаем задачу при нажатии
          onTap: () => close(context, task),
        );
      },
    );
  }

  @override
  void showResults(BuildContext context) {
    super.showResults(context);
    _search();
  }

  @override
  void showSuggestions(BuildContext context) {
    super.showSuggestions(context);
    if (query.length >= 2) {
      _search();
    }
  }

  Future<void> _search() async {
    if (query.length < 2) return;

    _isLoading = true;

    final allTasks = await DatabaseHelper.instance.getActiveTasks();

    _results = allTasks.where((task) {
      final q = query.toLowerCase();
      return task.title.toLowerCase().contains(q) ||
          task.description.toLowerCase().contains(q);
    }).toList();

    _isLoading = false;
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high: return Colors.red;
      case Priority.medium: return Colors.orange;
      case Priority.low: return Colors.green;
    }
  }

  String _getPriorityName(Priority priority) {
    switch (priority) {
      case Priority.high: return 'Высокий';
      case Priority.medium: return 'Средний';
      case Priority.low: return 'Низкий';
    }
  }
}