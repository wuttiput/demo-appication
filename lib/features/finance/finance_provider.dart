import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import 'transaction_model.dart';

class FinanceState {
  final String selectedDate; // YYYY-MM-DD
  final List<TransactionModel> transactions;
  final bool isLoading;

  FinanceState({
    required this.selectedDate,
    this.transactions = const [],
    this.isLoading = false,
  });

  double get totalIncome => transactions
      .where((tx) => tx.type == 'income')
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => transactions
      .where((tx) => tx.type == 'expense')
      .fold(0.0, (sum, item) => sum + item.amount);

  double get netBalance => totalIncome - totalExpense;

  FinanceState copyWith({
    String? selectedDate,
    List<TransactionModel>? transactions,
    bool? isLoading,
  }) {
    return FinanceState(
      selectedDate: selectedDate ?? this.selectedDate,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier()
      : super(FinanceState(
          selectedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        )) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    final rows = await DatabaseHelper.instance.queryTransactionsByDate(state.selectedDate);
    final list = rows.map((r) => TransactionModel.fromMap(r)).toList();
    state = state.copyWith(transactions: list, isLoading: false);
  }

  Future<void> setDate(String newDate) async {
    state = state.copyWith(selectedDate: newDate);
    await loadTransactions();
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    String? description,
    required String date,
  }) async {
    final tx = TransactionModel(
      type: type,
      amount: amount,
      description: description,
      date: date,
    );
    await DatabaseHelper.instance.insertTransaction(tx.toMap());
    
    // Reload if the transaction was added to the currently selected date
    if (date == state.selectedDate) {
      await loadTransactions();
    }
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier();
});
