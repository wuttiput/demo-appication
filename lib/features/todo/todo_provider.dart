import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import 'todo_model.dart';

class TodoState {
  final String selectedDate; // YYYY-MM-DD
  final List<TodoModel> todos;
  final bool isLoading;

  TodoState({
    required this.selectedDate,
    this.todos = const [],
    this.isLoading = false,
  });

  TodoState copyWith({
    String? selectedDate,
    List<TodoModel>? todos,
    bool? isLoading,
  }) {
    return TodoState(
      selectedDate: selectedDate ?? this.selectedDate,
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
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
    state = state.copyWith(todos: list, isLoading: false);
  }

  Future<void> setDate(String newDate) async {
    state = state.copyWith(selectedDate: newDate);
    await loadTodos();
  }

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) return;
    
    final todo = TodoModel(
      title: title.trim(),
      date: state.selectedDate,
    );
    await DatabaseHelper.instance.insertTodo(todo.toMap());
    await loadTodos();
  }

  Future<void> toggleTodo(TodoModel todo) async {
    final newIsDone = todo.isDone == 1 ? 0 : 1;
    await DatabaseHelper.instance.updateTodoStatus(todo.id!, newIsDone);
    await loadTodos();
  }

  Future<void> deleteTodo(int id) async {
    await DatabaseHelper.instance.deleteTodo(id);
    await loadTodos();
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  return TodoNotifier();
});
