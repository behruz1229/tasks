import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/task.dart';
import 'active_tasks_screen.dart';
import 'completed_tasks_screen.dart';
import 'trash_screen.dart';
import 'add_edit_task_screen.dart';
import 'statistics_screen.dart';
import 'task_search_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  int _currentIndex = 0;
  Key _screenKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Список задач'),
            centerTitle: true,
            actions: _buildAppBarActions(),
          ),
          body: KeyedSubtree(
            key: _screenKey,
            child: _buildCurrentScreen(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.list), label: 'Активные'),
              NavigationDestination(icon: Icon(Icons.check_circle), label: 'Выполненные'),
              NavigationDestination(icon: Icon(Icons.delete_outline), label: 'Корзина'),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditTaskScreen(isFromAddTab: true),
                ),
              ).then((_) {
                if (_currentIndex == 0) {
                  setState(() {
                    _screenKey = UniqueKey();
                  });
                }
              });
            },
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  // 🔹 Выносим действия AppBar в отдельный метод
  List<Widget> _buildAppBarActions() {
    return [
      // Кнопка поиска
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () async {
          final result = await showSearch<Task?>(
            context: context,
            delegate: TaskSearchDelegate(),
          );
          if (result != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditTaskScreen(task: result),
              ),
            );
          }
        },
      ),
      // Меню (три точки)
      Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'statistics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                );
              } else if (value == 'filter_priority' && _currentIndex == 0) {
                _showPriorityFilterDialog(context, settings);
              }
            },
            itemBuilder: (context) {
              // 🔹 Формируем список пунктов динамически
              final items = <PopupMenuItem<String>>[
                // ✅ Статистика — есть на всех вкладках
                const PopupMenuItem(
                  value: 'statistics',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart),
                      SizedBox(width: 8),
                      Text('Статистика'),
                    ],
                  ),
                ),
              ];

              // ✅ Фильтр — ТОЛЬКО на вкладке "Активные"
              if (_currentIndex == 0) {
                items.add(const PopupMenuItem(
                  value: 'filter_priority',
                  child: Row(
                    children: [
                      Icon(Icons.filter_list),
                      SizedBox(width: 8),
                      Text('Фильтр по приоритету'),
                    ],
                  ),
                ));
              }

              return items;
            },
          );
        },
      ),
    ];
  }

  Future<void> _showPriorityFilterDialog(BuildContext context, SettingsProvider settings) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр по приоритету'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.priority_high, color: Colors.red),
              title: const Text('Высокий'),
              trailing: settings.priorityFilter == Priority.high
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                settings.setPriorityFilter(Priority.high);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove, color: Colors.orange),
              title: const Text('Средний'),
              trailing: settings.priorityFilter == Priority.medium
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                settings.setPriorityFilter(Priority.medium);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.expand_more, color: Colors.green),
              title: const Text('Низкий'),
              trailing: settings.priorityFilter == Priority.low
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                settings.setPriorityFilter(Priority.low);
                Navigator.pop(context);
              },
            ),
            if (settings.priorityFilter != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Сбросить фильтр'),
                onTap: () {
                  settings.setPriorityFilter(null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0: return const ActiveTasksScreen();
      case 1: return const CompletedTasksScreen();
      case 2: return const TrashScreen();
      default: return const ActiveTasksScreen();
    }
  }
}