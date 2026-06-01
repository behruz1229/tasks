import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../providers/timer_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  final bool isFromAddTab;

  const AddEditTaskScreen({super.key, this.task, this.isFromAddTab = false});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  late TextEditingController _hoursCtrl;
  late TextEditingController _minutesCtrl;
  late TextEditingController _secondsCtrl;
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late Priority _priority;
  int? _timerDuration;

  late String _originalTitle;
  late String _originalDescription;
  late Priority _originalPriority;
  late int? _originalTimerDuration;

  @override
  void initState() {
    super.initState();
    _initForm();
    _saveOriginalValues();
  }

  void _initForm() {
    _title = widget.task?.title ?? '';
    _description = widget.task?.description ?? '';
    _priority = widget.task?.priority ?? Priority.medium;
    _timerDuration = widget.task?.timerDuration;
  }

  void _saveOriginalValues() {
    _originalTitle = _title;
    _originalDescription = _description;
    _originalPriority = _priority;
    _originalTimerDuration = _timerDuration;
  }

  bool get _hasChanges {
    return _title != _originalTitle ||
        _description != _originalDescription ||
        _priority != _originalPriority ||
        _timerDuration != _originalTimerDuration;
  }

  void _resetForm() {
    setState(() {
      _title = '';
      _description = '';
      _priority = Priority.medium;
      _timerDuration = null;
      _formKey.currentState?.reset();
    });
  }

  bool get isEditing => widget.task != null;

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showTimerPicker() {
    // 🔹 Инициализируем значения из текущего таймера
    int hours = _timerDuration != null ? _timerDuration! ~/ 3600 : 0;
    int minutes = _timerDuration != null ? (_timerDuration! % 3600) ~/ 60 : 0;
    int seconds = _timerDuration != null ? _timerDuration! % 60 : 0;
    _hoursCtrl = TextEditingController(text: hours.toString());
    _minutesCtrl = TextEditingController(text: minutes.toString());
    _secondsCtrl = TextEditingController(text: seconds.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите длительность', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 🔹 Три поля: Часы / Минуты / Секунды с русскими подписями
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Часы
                Column(
                  children: [
                    const Text('Часы', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        controller: TextEditingController(text: hours.toString()),
                        onChanged: (value) {
                          hours = int.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
                // Минуты
                Column(
                  children: [
                    const Text('Мин', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        controller: TextEditingController(text: minutes.toString()),
                        onChanged: (value) {
                          minutes = int.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
                // Секунды
                Column(
                  children: [
                    const Text('Сек', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        controller: TextEditingController(text: seconds.toString()),
                        onChanged: (value) {
                          seconds = int.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🔹 Кнопка "Готово"
            FilledButton(
              onPressed: () {
                // 🔹 Сохраняем выбранное время в секундах
                setState(() {
                  _timerDuration = hours * 3600 + minutes * 60 + seconds;
                });
                Navigator.pop(context);
                _hoursCtrl.dispose();
                _minutesCtrl.dispose();
                _secondsCtrl.dispose();
              },
              child: const Text('Готово'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Редактировать' : 'Новая задача')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(labelText: 'Название *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
              validator: (value) => value == null || value.trim().isEmpty ? 'Введите название' : null,
              onSaved: (value) => _title = value!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
              maxLines: 3,
              onSaved: (value) => _description = value?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            const Text('Приоритет:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<Priority>(
              segments: const [
                ButtonSegment(value: Priority.high, label: Text('Высокий'), icon: Icon(Icons.priority_high, color: Colors.red)),
                ButtonSegment(value: Priority.medium, label: Text('Средний'), icon: Icon(Icons.remove, color: Colors.orange)),
                ButtonSegment(value: Priority.low, label: Text('Низкий'), icon: Icon(Icons.expand_more, color: Colors.green)),
              ],
              selected: {_priority},
              onSelectionChanged: (Set<Priority> selected) => setState(() => _priority = selected.first),
            ),
            const SizedBox(height: 16),
            const Text('Таймер:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Установить длительность'),
              subtitle: Text(_timerDuration != null ? _formatDuration(_timerDuration!) : 'Не установлен'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showTimerPicker,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveTask,
        icon: Icon(isEditing ? Icons.save : Icons.add),
        label: Text(isEditing ? 'Сохранить' : 'Создать'),
      ),
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedTask = Task(
        id: widget.task?.id,
        title: _title,
        description: _description,
        priority: _priority,
        isCompleted: widget.task?.isCompleted ?? false,
        timerDuration: _timerDuration,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        completedAt: widget.task?.completedAt,
      );

      // 🔹 Логика таймера при редактировании
      if (isEditing) {
        DatabaseHelper.instance.updateTask(updatedTask);

        // Если время изменилось и таймер для этой задачи запущен - перезапускаем
        final timer = Provider.of<TimerProvider>(context, listen: false);
        if (_timerDuration != _originalTimerDuration && timer.activeTaskId == widget.task?.id) {
          timer.restartTimer(widget.task!.id!, _timerDuration ?? 0);
        }
      } else {
        DatabaseHelper.instance.createTask(updatedTask);
      }

      if (widget.isFromAddTab) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Задача создана!'), duration: Duration(seconds: 2)),
        );
      } else {
        Navigator.pop(context, updatedTask);
      }
    }
  }
}