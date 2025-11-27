import 'package:flutter/material.dart';
import 'models.dart';
import 'data/db_helper.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await DBHelper.fetchTasks();
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Не удалось загрузить задачи';
        _loading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final result = await Navigator.pushNamed(context, '/add');
    if (result is! String) return;
    final text = result.trim();
    if (text.isEmpty) return;

    try {
      final saved = await DBHelper.insertTask(Task(title: text));
      setState(() => _tasks.insert(0, saved));
    } catch (_) {
      _showError('Не удалось сохранить задачу');
    }
  }

  Future<void> _toggle(Task t, bool v) async {
    final updated = t.copyWith(done: v);
    setState(() {
      final idx = _tasks.indexWhere((x) => x.id == t.id);
      if (idx != -1) _tasks[idx] = updated;
    });
    try {
      await DBHelper.updateTask(updated);
    } catch (_) {
      _showError('Не удалось обновить задачу');
      _load();
    }
  }

  Future<void> _delete(Task t) async {
    final id = t.id;
    if (id == null) return;
    setState(() => _tasks.removeWhere((x) => x.id == id));
    try {
      await DBHelper.deleteTask(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задача удалена')),
      );
    } catch (_) {
      _showError('Не удалось удалить задачу');
      _load();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Задачи')), // без const у AppBar
      body: _buildBody(),
      // квадратный FAB
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Material(
            color: AppColors.pinkLight.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _addTask,
              child: const Center(child: Icon(Icons.add, size: 34, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_tasks.isEmpty) {
      return const Center(child: Text('Пока нет задач. Нажмите +'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 22),
      itemBuilder: (context, i) {
        final t = _tasks[i];
        return Dismissible(
          key: ValueKey(t.id ?? t.title),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red.withOpacity(0.3),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _delete(t),
          child: Row(
            children: [
              CircleCheckbox(value: t.done, onChanged: (v) => _toggle(t, v)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 18,
                    decoration: t.done ? TextDecoration.lineThrough : null,
                    color: t.done ? Colors.white70 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
