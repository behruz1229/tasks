import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/timer_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(Task) onToggleComplete;
  final Function(Task) onEdit;
  final Function(int) onDelete;
  final bool isCompleted;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    this.isCompleted = false,
  });

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onEdit(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎨 Анимированный чекбокс
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Checkbox(
                      key: ValueKey(task.isCompleted),
                      value: task.isCompleted,
                      onChanged: (_) async {
                        _showCompleteDialog(context, task);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? Colors.grey : null,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor().withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getPriorityName(),
                                style: TextStyle(color: _getPriorityColor(), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (task.timerDuration != null) ...[
                              Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(task.timerDuration!),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd.MM HH:mm').format(task.createdAt),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isCompleted) ...[
                const Divider(height: 20),
                Consumer<TimerProvider>(
                  builder: (context, timer, child) {
                    final isActive = timer.activeTaskId == task.id;
                    final hasTimer = task.timerDuration != null;

                    return Column(
                      children: [
                        if (isActive || hasTimer) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: isActive ? 22 : 20,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[700],
                              ),
                              child: Text(
                                isActive ? _formatDuration(timer.remainingSeconds) : _formatDuration(task.timerDuration!),
                              ),
                            ),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (isActive) ...[
                                  IconButton(
                                    icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
                                    color: Theme.of(context).colorScheme.primary,
                                    onPressed: () {
                                      timer.togglePause();

                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.stop),
                                    color: Colors.red,
                                    onPressed: () {
                                      timer.stopTimer();
                                    },
                                  ),
                                ] else if (hasTimer) ...[
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    color: Theme.of(context).colorScheme.primary,
                                    onPressed: () {
                                      timer.startTimer(task.id!, task.title, task.timerDuration!);
                                    },
                                  ),
                                ],
                              ],
                            ),
                            Row(
                              children: [
                                if (!isCompleted) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Изменить',
                                    onPressed: () {
                                      onEdit(task);
                                    },
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  tooltip: 'Удалить',
                                  onPressed: () => _showDeleteDialog(context, timer),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      tooltip: 'Удалить',
                      onPressed: () => onDelete(task.id!),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case Priority.high: return Colors.red;
      case Priority.medium: return Colors.orange;
      case Priority.low: return Colors.green;
    }
  }

  String _getPriorityName() {
    switch (task.priority) {
      case Priority.high: return 'Высокий';
      case Priority.medium: return 'Средний';
      case Priority.low: return 'Низкий';
    }
  }

  void _showCompleteDialog(BuildContext context, Task task) {
    final isDone = task.isCompleted;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDone ? 'Вернуть в активные?' : 'Завершить задачу?'),
        content: Text(isDone
            ? '"${task.title}" уже выполнена. Хотите вернуть её в список активных?'
            : '"${task.title}" будет перемещена в выполненные.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final timer = Provider.of<TimerProvider>(context, listen: false);
              if (timer.activeTaskId == task.id) {
                timer.stopTimer();
              }
              onToggleComplete(task);
            },
            child: Text(isDone ? 'Да, вернуть' : 'Да, завершить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TimerProvider? timer) {
    if (isCompleted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (timer != null && timer.activeTaskId == task.id) {
                timer.stopTimer();
              }
              onDelete(task.id!);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}