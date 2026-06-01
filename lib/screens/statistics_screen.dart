import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/task.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _activeTasks = 0;
  int _highPriority = 0;
  int _mediumPriority = 0;
  int _lowPriority = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final allTasks = await DatabaseHelper.instance.getAllTasks();
    final completed = await DatabaseHelper.instance.getCompletedTasks();
    final active = await DatabaseHelper.instance.getActiveTasks();

    setState(() {
      _totalTasks = allTasks.length;
      _completedTasks = completed.length;
      _activeTasks = active.length;

      _highPriority = allTasks.where((t) => t.priority == Priority.high).length;
      _mediumPriority = allTasks.where((t) => t.priority == Priority.medium).length;
      _lowPriority = allTasks.where((t) => t.priority == Priority.low).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            'Всего задач',
            _totalTasks.toString(),
            Icons.task,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Активные',
            _activeTasks.toString(),
            Icons.list,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Выполненные',
            _completedTasks.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 32),
          const Text(
            'По приоритету',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPriorityBar('Высокий', _highPriority, Colors.red),
          const SizedBox(height: 8),
          _buildPriorityBar('Средний', _mediumPriority, Colors.orange),
          const SizedBox(height: 8),
          _buildPriorityBar('Низкий', _lowPriority, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBar(String label, int count, Color color) {
    final percentage = _totalTasks > 0 ? (count / _totalTasks * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text('$count ($percentage%)', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}