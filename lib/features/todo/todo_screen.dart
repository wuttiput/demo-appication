import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'todo_provider.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _todoController = TextEditingController();

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  void _submitTodo() {
    final title = _todoController.text.trim();
    if (title.isNotEmpty) {
      ref.read(todoProvider.notifier).addTodo(title);
      _todoController.clear();
    }
  }

  Future<void> _pickDate(BuildContext context, String currentDate, TodoNotifier notifier) async {
    final parsed = DateFormat('yyyy-MM-dd').parse(currentDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.indigo600,
              onPrimary: Colors.white,
              surface: AppTheme.slate900,
              onSurface: AppTheme.slate100,
            ),
            dialogBackgroundColor: AppTheme.slate950,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      notifier.setDate(formatted);
    }
  }

  void _changeDay(String currentDate, TodoNotifier notifier, int offset) {
    final parsed = DateFormat('yyyy-MM-dd').parse(currentDate);
    final newDate = parsed.add(Duration(days: offset));
    final formatted = DateFormat('yyyy-MM-dd').format(newDate);
    notifier.setDate(formatted);
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoProvider);
    final todoNotifier = ref.read(todoProvider.notifier);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = todoState.selectedDate == todayStr;

    final activeCount = todoState.todos.where((t) => t.isDone == 0).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.indigo600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.indigo500.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.playlist_add_check, color: AppTheme.indigo500, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To-Do List',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.slate100),
                      ),
                      Text(
                        isToday ? 'วันนี้ (${todoState.selectedDate})' : todoState.selectedDate,
                        style: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Active Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeCount > 0
                          ? AppTheme.indigo600.withOpacity(0.15)
                          : AppTheme.slate900,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: activeCount > 0
                            ? AppTheme.indigo500.withOpacity(0.3)
                            : AppTheme.slate800,
                      ),
                    ),
                    child: Text(
                      activeCount > 0 ? 'เหลืออีก $activeCount งาน' : 'เสร็จสิ้นหมดแล้ว 🎉',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: activeCount > 0 ? AppTheme.indigo500 : AppTheme.emerald400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Selector Row
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'งานของวันที่:',
                      style: TextStyle(fontSize: 12, color: AppTheme.slate400, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        // Prev Day
                        IconButton(
                          onPressed: () => _changeDay(todoState.selectedDate, todoNotifier, -1),
                          icon: const Icon(Icons.chevron_left, color: AppTheme.slate400),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        
                        // Date Picker
                        InkWell(
                          onTap: () => _pickDate(context, todoState.selectedDate, todoNotifier),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.slate950.withOpacity(0.6),
                              border: Border.all(color: AppTheme.slate800),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              todoState.selectedDate,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigo500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Next Day
                        IconButton(
                          onPressed: () => _changeDay(todoState.selectedDate, todoNotifier, 1),
                          icon: const Icon(Icons.chevron_right, color: AppTheme.slate400),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        
                        if (!isToday) ...[
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => todoNotifier.setDate(todayStr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.indigo600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('วันนี้', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add Task Input Box
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      onSubmitted: (_) => _submitTodo(),
                      decoration: const InputDecoration(
                        labelText: 'เพิ่มสิ่งที่ต้องทำใหม่...',
                        hintText: 'ระบุหัวข้องาน เช่น ซื้อของเข้าบ้าน, อ่านหนังสือ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.indigo600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(14),
                      minimumSize: Size.zero,
                    ),
                    child: const Icon(Icons.add, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // To-Do List View
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: todoState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : todoState.todos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, color: AppTheme.slate700, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'ยังไม่มีรายการสิ่งที่ต้องทำในวันนี้',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.slate400),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'สนุกกับการเพิ่มงานชิ้นแรกด้านบนได้เลย!',
                                    style: TextStyle(fontSize: 11, color: AppTheme.slate700),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: todoState.todos.length,
                              itemBuilder: (context, index) {
                                final todo = todoState.todos[index];
                                final completed = todo.completed;
                                return Card(
                                  color: completed
                                      ? AppTheme.slate950.withOpacity(0.2)
                                      : AppTheme.slate900,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: Row(
                                      children: [
                                        // Checkbox with animation
                                        IconButton(
                                          onPressed: () => todoNotifier.toggleTodo(todo),
                                          icon: Icon(
                                            completed
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: completed ? AppTheme.emerald400 : AppTheme.slate400,
                                            size: 22,
                                          ),
                                        ),
                                        
                                        // Title text
                                        Expanded(
                                          child: Text(
                                            todo.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              decoration: completed
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: completed
                                                  ? AppTheme.slate700
                                                  : AppTheme.slate100,
                                              fontWeight: completed
                                                  ? FontWeight.normal
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),

                                        // Delete Button
                                        IconButton(
                                          onPressed: () {
                                            todoNotifier.deleteTodo(todo.id!);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('ลบรายการ To-Do เรียบร้อยแล้ว'),
                                                backgroundColor: AppTheme.rose400,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.rose400, size: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
