import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import 'todo_model.dart';

class TodoState {
  final String selectedDate; // YYYY-MM-DD
  final List<TodoModel> todos;
  final bool isLoading;
  final int flameScore;

  TodoState({
    required this.selectedDate,
    this.todos = const [],
    this.isLoading = false,
    this.flameScore = 0,
  });

  TodoState copyWith({
    String? selectedDate,
    List<TodoModel>? todos,
    bool? isLoading,
    int? flameScore,
  }) {
    return TodoState(
      selectedDate: selectedDate ?? this.selectedDate,
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      flameScore: flameScore ?? this.flameScore,
    );
  }
}

class TodoNotifier extends StateNotifier<TodoState> {
  TodoNotifier()
      : super(TodoState(
          selectedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        )) {
    loadTodos();
  }

  Future<void> loadTodos() async {
    state = state.copyWith(isLoading: true);
    final rows = await DatabaseHelper.instance.queryTodosByDate(state.selectedDate);
    final list = rows.map((r) => TodoModel.fromMap(r)).toList();
    final flame = await DatabaseHelper.instance.getFlameScore();
    state = state.copyWith(todos: list, flameScore: flame, isLoading: false);
  }

  Future<void> setDate(String newDate) async {
    state = state.copyWith(selectedDate: newDate);
    await loadTodos();
  }

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) return;
    
    int maxOrder = 0;
    if (state.todos.isNotEmpty) {
      maxOrder = state.todos.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b);
    }
    
    final todo = TodoModel(
      title: title.trim(),
      date: state.selectedDate,
      orderIndex: maxOrder + 1,
    );
    await DatabaseHelper.instance.insertTodo(todo.toMap());
    await loadTodos();
  }

  Future<bool> toggleTodo(TodoModel todo) async {
    final newIsDone = todo.isDone == 1 ? 0 : 1;
    await DatabaseHelper.instance.updateTodoStatus(todo.id!, newIsDone);
    
    int newFlameScore = state.flameScore;
    if (newIsDone == 1) {
      newFlameScore += 1;
    } else {
      newFlameScore = (newFlameScore - 1).clamp(0, 999999);
    }
    await DatabaseHelper.instance.updateFlameScore(newFlameScore);
    
    await loadTodos();
    return newIsDone == 1;
  }

  Future<void> reorderTodos(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final List<TodoModel> items = List.from(state.todos);
    final TodoModel item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    
    state = state.copyWith(todos: items);
    
    for (int i = 0; i < items.length; i++) {
      final updatedItem = items[i].copyWith(orderIndex: i);
      items[i] = updatedItem;
      await DatabaseHelper.instance.updateTodoOrder(updatedItem.id!, i);
    }
    
    state = state.copyWith(todos: items);
  }

  Future<void> deleteTodo(int id) async {
    await DatabaseHelper.instance.deleteTodo(id);
    await loadTodos();
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  return TodoNotifier();
});
