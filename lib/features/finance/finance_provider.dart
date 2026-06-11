import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import 'transaction_model.dart';

class FinanceState {
  final String selectedDate; // YYYY-MM-DD
  final String selectedYearMonth; // YYYY-MM
  final List<TransactionModel> transactions;
  final List<TransactionModel> monthlyTransactions;
  final bool isLoading;
  final bool isMonthlyLoading;

  FinanceState({
    required this.selectedDate,
    required this.selectedYearMonth,
    this.transactions = const [],
    this.monthlyTransactions = const [],
    this.isLoading = false,
    this.isMonthlyLoading = false,
  });

  double get totalIncome => transactions
      .where((tx) => tx.type == 'income')
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => transactions
      .where((tx) => tx.type == 'expense')
      .fold(0.0, (sum, item) => sum + item.amount);

  double get netBalance => totalIncome - totalExpense;

  double get monthlyTotalIncome => monthlyTransactions
      .where((tx) => tx.type == 'income')
      .fold(0.0, (sum, item) => sum + item.amount);

  double get monthlyTotalExpense => monthlyTransactions
      .where((tx) => tx.type == 'expense')
      .fold(0.0, (sum, item) => sum + item.amount);

  double get monthlyNetBalance => monthlyTotalIncome - monthlyTotalExpense;

  FinanceState copyWith({
    String? selectedDate,
    String? selectedYearMonth,
    List<TransactionModel>? transactions,
    List<TransactionModel>? monthlyTransactions,
    bool? isLoading,
    bool? isMonthlyLoading,
  }) {
    return FinanceState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedYearMonth: selectedYearMonth ?? this.selectedYearMonth,
      transactions: transactions ?? this.transactions,
      monthlyTransactions: monthlyTransactions ?? this.monthlyTransactions,
      isLoading: isLoading ?? this.isLoading,
      isMonthlyLoading: isMonthlyLoading ?? this.isMonthlyLoading,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier()
      : super(FinanceState(
          selectedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          selectedYearMonth: DateFormat('yyyy-MM').format(DateTime.now()),
        )) {
    loadTransactions();
    loadMonthlyTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    final rows = await DatabaseHelper.instance.queryTransactionsByDate(state.selectedDate);
    final list = rows.map((r) => TransactionModel.fromMap(r)).toList();
    state = state.copyWith(transactions: list, isLoading: false);
  }

  Future<void> loadMonthlyTransactions() async {
    state = state.copyWith(isMonthlyLoading: true);
    final rows = await DatabaseHelper.instance.queryTransactionsByMonth(state.selectedYearMonth);
    final list = rows.map((r) => TransactionModel.fromMap(r)).toList();
    state = state.copyWith(monthlyTransactions: list, isMonthlyLoading: false);
  }

  Future<void> setDate(String newDate) async {
    state = state.copyWith(selectedDate: newDate);
    await loadTransactions();
  }

  Future<void> setYearMonth(String newYearMonth) async {
    state = state.copyWith(selectedYearMonth: newYearMonth);
    await loadMonthlyTransactions();
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
    
    if (date == state.selectedDate) {
      await loadTransactions();
    }
    if (date.startsWith(state.selectedYearMonth)) {
      await loadMonthlyTransactions();
    }
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
    await loadMonthlyTransactions();
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier();
});
