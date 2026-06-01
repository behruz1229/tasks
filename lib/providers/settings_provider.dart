import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class SettingsProvider extends ChangeNotifier {
  bool _hapticFeedbackEnabled = true;
  String _searchQuery = '';
  Priority? _priorityFilter;
  static const String _hapticKey = 'haptic_feedback_enabled';

  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  String get searchQuery => _searchQuery;
  Priority? get priorityFilter => _priorityFilter;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticFeedbackEnabled = prefs.getBool(_hapticKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleHapticFeedback() async {
    _hapticFeedbackEnabled = !_hapticFeedbackEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticKey, _hapticFeedbackEnabled);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPriorityFilter(Priority? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _priorityFilter = null;
    notifyListeners();
  }

  // 🔹 Фильтрация задач
  List<Task> filterTasks(List<Task> tasks) {
    return tasks.where((task) {
      // Поиск по названию и описанию
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!task.title.toLowerCase().contains(query) &&
            !task.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      // Фильтр по приоритету
      if (_priorityFilter != null && task.priority != _priorityFilter) {
        return false;
      }
      return true;
    }).toList();
  }
}