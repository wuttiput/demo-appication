import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import 'finance_provider.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'income'; // 'income' or 'expense'
  final _formKey = GlobalKey<FormState>();
  bool _isMonthlyView = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm(String selectedDate) async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final desc = _descriptionController.text.trim();
      
      await ref.read(financeProvider.notifier).addTransaction(
        type: _selectedType,
        amount: amount,
        description: desc.isNotEmpty ? desc : null,
        date: selectedDate,
      );

      _amountController.clear();
      _descriptionController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกรายการเรียบร้อยแล้ว'),
            backgroundColor: AppTheme.emerald400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickDate(BuildContext context, String currentDate, FinanceNotifier notifier) async {
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

  void _changeDay(String currentDate, FinanceNotifier notifier, int offset) {
    final parsed = DateFormat('yyyy-MM-dd').parse(currentDate);
    final newDate = parsed.add(Duration(days: offset));
    final formatted = DateFormat('yyyy-MM-dd').format(newDate);
    notifier.setDate(formatted);
  }

  Future<void> _pickMonth(BuildContext context, String currentYearMonth, FinanceNotifier notifier) async {
    final parsed = DateFormat('yyyy-MM').parse(currentYearMonth);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(parsed.year, parsed.month, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
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
      final formatted = DateFormat('yyyy-MM').format(picked);
      notifier.setYearMonth(formatted);
    }
  }

  void _changeMonth(String currentYearMonth, FinanceNotifier notifier, int offset) {
    final parsed = DateFormat('yyyy-MM').parse(currentYearMonth);
    final newDate = DateTime(parsed.year, parsed.month + offset);
    final formatted = DateFormat('yyyy-MM').format(newDate);
    notifier.setYearMonth(formatted);
  }

  String _formatThaiMonth(String yearMonth) {
    try {
      final parsed = DateFormat('yyyy-MM').parse(yearMonth);
      final months = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      final monthName = months[parsed.month - 1];
      final yearInBuddhistEra = parsed.year + 543;
      return '$monthName $yearInBuddhistEra';
    } catch (_) {
      return yearMonth;
    }
  }

  String _formatThaiShortDate(String dateStr) {
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(dateStr);
      final months = [
        'ม.ค.', 'ก.พ.', 'มี.ย.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      final monthName = months[parsed.month - 1];
      final shortYear = (parsed.year + 543) % 100;
      return '${parsed.day} $monthName $shortYear';
    } catch (_) {
      return dateStr;
    }
  }

  double _calculateMaxY(Map<int, double> income, Map<int, double> expense) {
    double maxVal = 100.0;
    for (final v in income.values) {
      if (v > maxVal) maxVal = v;
    }
    for (final v in expense.values) {
      if (v > maxVal) maxVal = v;
    }
    return maxVal * 1.15;
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final financeNotifier = ref.read(financeProvider.notifier);

    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = financeState.selectedDate == todayStr;

    final netVal = financeState.netBalance;
    final hasTransactions = financeState.transactions.isNotEmpty;
    
    final Color cardBg;
    final Color cardBorder;
    final Color accentColor;
    final IconData statusIcon;
    final String statusText;
    final String moneyText;

    if (!hasTransactions || financeState.isLoading) {
      cardBg = AppTheme.slate900.withOpacity(0.45);
      cardBorder = AppTheme.slate800.withOpacity(0.4);
      accentColor = AppTheme.slate400;
      statusIcon = Icons.remove_circle_outline_rounded;
      statusText = 'ไม่มีประวัติการบันทึกรายการในวันนี้';
      moneyText = currencyFormat.format(0.0);
    } else if (netVal >= 0) {
      cardBg = AppTheme.emerald950;
      cardBorder = AppTheme.emeraldBorder.withOpacity(0.4);
      accentColor = AppTheme.emerald400;
      statusIcon = Icons.trending_up_rounded;
      statusText = 'ยอดเงินคงเหลือเป็นบวก';
      moneyText = currencyFormat.format(netVal);
    } else {
      cardBg = AppTheme.rose950;
      cardBorder = AppTheme.roseBorder.withOpacity(0.4);
      accentColor = AppTheme.rose400;
      statusIcon = Icons.trending_down_rounded;
      statusText = 'ยอดรายจ่ายเกินรายรับ';
      moneyText = currencyFormat.format(netVal);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                      color: AppTheme.emerald400.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.emeraldBorder.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: AppTheme.emerald400, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รายรับ-รายจ่าย',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.slate100),
                      ),
                      Text(
                        isToday ? 'วันนี้ (${financeState.selectedDate})' : financeState.selectedDate,
                        style: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Switcher (Daily vs Monthly)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.slate900.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.slate800),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isMonthlyView = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isMonthlyView ? AppTheme.indigo600 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.today_rounded,
                                  size: 16,
                                  color: !_isMonthlyView ? Colors.white : AppTheme.slate400,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'บันทึกรายวัน',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: !_isMonthlyView ? Colors.white : AppTheme.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isMonthlyView = true;
                          });
                          ref.read(financeProvider.notifier).loadMonthlyTransactions();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isMonthlyView ? AppTheme.indigo600 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: _isMonthlyView ? Colors.white : AppTheme.slate400,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'สถิติรายเดือน',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _isMonthlyView ? Colors.white : AppTheme.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_isMonthlyView) ...[
                // Date Selector Row
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ข้อมูลของวันที่:',
                        style: TextStyle(fontSize: 12, color: AppTheme.slate400, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          // Prev Day Button
                          IconButton(
                            onPressed: () => _changeDay(financeState.selectedDate, financeNotifier, -1),
                            icon: const Icon(Icons.chevron_left, color: AppTheme.slate400),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          
                          // Date Picker trigger
                          InkWell(
                            onTap: () => _pickDate(context, financeState.selectedDate, financeNotifier),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.slate950.withOpacity(0.6),
                                border: Border.all(color: AppTheme.slate800),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                financeState.selectedDate,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigo500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Next Day Button
                          IconButton(
                            onPressed: () => _changeDay(financeState.selectedDate, financeNotifier, 1),
                            icon: const Icon(Icons.chevron_right, color: AppTheme.slate400),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          
                          if (!isToday) ...[
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => financeNotifier.setDate(todayStr),
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
                const SizedBox(height: 16),

                // Summary Cards
                Row(
                  children: [
                    // Income Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald950,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.emeraldBorder.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('รายรับรวม', style: TextStyle(fontSize: 11, color: AppTheme.emerald400)),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(financeState.totalIncome),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.emerald400),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expense Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.rose950,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.roseBorder.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('รายจ่ายรวม', style: TextStyle(fontSize: 11, color: AppTheme.rose400)),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(financeState.totalExpense),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.rose400),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ยอดรวมสุทธิ Card (Net Balance)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statusIcon,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ยอดรวมสุทธิ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.slate100,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                color: accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        moneyText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Input Form Card & History List
                Column(
                  children: [
                    // Form Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'บันทึกรายการเงินใหม่',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),

                              // Type Selection
                              Row(
                                children: [
                                  // Income Selection Toggle
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedType = 'income'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _selectedType == 'income'
                                              ? AppTheme.emerald950
                                              : AppTheme.slate950.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _selectedType == 'income'
                                                ? AppTheme.emerald400.withOpacity(0.5)
                                                : AppTheme.slate800,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                  color: AppTheme.emerald400, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'รายรับ (Income)',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.slate100),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Expense Selection Toggle
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedType = 'expense'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _selectedType == 'expense'
                                              ? AppTheme.rose950
                                              : AppTheme.slate950.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _selectedType == 'expense'
                                                ? AppTheme.rose400.withOpacity(0.5)
                                                : AppTheme.slate800,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                  color: AppTheme.rose400, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'รายจ่าย (Expense)',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.slate100),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Amount Input
                              TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'กรุณากรอกจำนวนเงิน';
                                  if (double.tryParse(val) == null) return 'กรุณากรอกเฉพาะตัวเลข';
                                  if (double.parse(val) <= 0) return 'จำนวนเงินต้องมากกว่า 0';
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'จำนวนเงิน (บาท)',
                                  hintText: '0.00',
                                  prefixText: '฿ ',
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Description Input
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'รายละเอียด / หมายเหตุ',
                                  hintText: 'ระบุข้อความ เช่น ซื้อข้าว, เงินเดือน',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Submit Button
                              ElevatedButton(
                                onPressed: () => _submitForm(financeState.selectedDate),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.indigo600,
                                  foregroundColor: Colors.white,
                                  shadowColor: AppTheme.indigo600.withOpacity(0.3),
                                  elevation: 4,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'บันทึกรายการ',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // History Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ประวัติรายการบันทึก',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.slate950.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.slate800),
                                  ),
                                  child: Text(
                                    'ทั้งหมด ${financeState.transactions.length} รายการ',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Transactions Table
                            if (financeState.isLoading)
                              const Center(child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: CircularProgressIndicator(),
                              ))
                            else if (financeState.transactions.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 36.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.history_toggle_off, color: AppTheme.slate700, size: 40),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'ยังไม่มีประวัติการบันทึกสำหรับวันนี้',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate400),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'กรอกแบบฟอร์มด้านบนเพื่อบันทึกรายการใหม่',
                                        style: TextStyle(fontSize: 10, color: AppTheme.slate700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: financeState.transactions.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final tx = financeState.transactions[index];
                                  final isIncome = tx.type == 'income';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Item Desc & Date
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.description ?? (isIncome ? 'รายรับ' : 'รายจ่าย'),
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.slate100),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                tx.date,
                                                style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Type Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isIncome ? AppTheme.emerald950 : AppTheme.rose950,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isIncome
                                                  ? AppTheme.emeraldBorder.withOpacity(0.3)
                                                  : AppTheme.roseBorder.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            isIncome ? 'รายรับ' : 'รายจ่าย',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isIncome ? AppTheme.emerald400 : AppTheme.rose400,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Amount
                                        Text(
                                          '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isIncome ? AppTheme.emerald400 : AppTheme.rose400,
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Delete Button
                                        IconButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('ลบรายการนี้?'),
                                                content: const Text('คุณแน่ใจว่าต้องการลบรายการนี้ใช่หรือไม่?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('ยกเลิก', style: TextStyle(color: AppTheme.slate400)),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      ref.read(financeProvider.notifier).deleteTransaction(tx.id!);
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('ลบรายการเรียบร้อยแล้ว'),
                                                          backgroundColor: AppTheme.rose400,
                                                        ),
                                                      );
                                                    },
                                                    child: const Text('ยืนยันลบ', style: TextStyle(color: AppTheme.rose400)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.rose400, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // 1. Monthly Selector Row
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ข้อมูลของเดือน:',
                        style: TextStyle(fontSize: 12, color: AppTheme.slate400, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          // Prev Month Button
                          IconButton(
                            onPressed: () => _changeMonth(financeState.selectedYearMonth, financeNotifier, -1),
                            icon: const Icon(Icons.chevron_left, color: AppTheme.slate400),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          
                          // Month Picker trigger
                          InkWell(
                            onTap: () => _pickMonth(context, financeState.selectedYearMonth, financeNotifier),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.slate950.withOpacity(0.6),
                                border: Border.all(color: AppTheme.slate800),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _formatThaiMonth(financeState.selectedYearMonth),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigo500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Next Month Button
                          IconButton(
                            onPressed: () => _changeMonth(financeState.selectedYearMonth, financeNotifier, 1),
                            icon: const Icon(Icons.chevron_right, color: AppTheme.slate400),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          
                          if (financeState.selectedYearMonth != DateFormat('yyyy-MM').format(DateTime.now())) ...[
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => financeNotifier.setYearMonth(DateFormat('yyyy-MM').format(DateTime.now())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.indigo600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('เดือนนี้', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Summary Cards
                Row(
                  children: [
                    // Monthly Income Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: !financeState.monthlyTransactions.isNotEmpty || financeState.isMonthlyLoading
                              ? AppTheme.slate900.withOpacity(0.45)
                              : AppTheme.emerald950,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !financeState.monthlyTransactions.isNotEmpty || financeState.isMonthlyLoading
                                ? AppTheme.slate800.withOpacity(0.4)
                                : AppTheme.emeraldBorder.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รายรับรายเดือน',
                              style: TextStyle(
                                fontSize: 11,
                                color: !financeState.monthlyTransactions.isNotEmpty || financeState.isMonthlyLoading
                                    ? AppTheme.slate400
                                    : AppTheme.emerald400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(financeState.monthlyTotalIncome),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: !financeState.monthlyTransactions.isNotEmpty || financeState.isMonthlyLoading
                                    ? AppTheme.slate300
                                    : AppTheme.emerald400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Monthly Expense Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: !financeState.monthlyTransactions.isNotEmpty || financeState.isMonthlyLoading
                              ? AppTheme.slate900.withOpacity(0.45)
                              : AppTheme.rose950,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !financeState.monthlyTransactions.isNotEmpty || financeState.isMonthlyLoading
                                ? AppTheme.slate800.withOpacity(0.4)
                                : AppTheme.roseBorder.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รายจ่ายรายเดือน',
                              style: TextStyle(
                                fontSize: 11,
                                color: !financeState.monthlyTransactions.isNotEmpty || financeState.isMonthlyLoading
                                    ? AppTheme.slate400
                                    : AppTheme.rose400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(financeState.monthlyTotalExpense),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: !financeState.monthlyTransactions.isNotEmpty || financeState.isMonthlyLoading
                                    ? AppTheme.slate300
                                    : AppTheme.rose400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Monthly Net Balance Card
                Builder(
                  builder: (context) {
                    final hasMonthlyTransactions = financeState.monthlyTransactions.isNotEmpty;
                    final monthlyNet = financeState.monthlyNetBalance;

                    final Color monthlyNetBg;
                    final Color monthlyNetBorder;
                    final Color monthlyNetAccent;
                    final IconData monthlyNetIcon;
                    final String monthlyNetStatusText;

                    if (financeState.isMonthlyLoading) {
                      monthlyNetBg = AppTheme.slate900.withOpacity(0.45);
                      monthlyNetBorder = AppTheme.slate800.withOpacity(0.4);
                      monthlyNetAccent = AppTheme.slate400;
                      monthlyNetIcon = Icons.hourglass_empty;
                      monthlyNetStatusText = 'กำลังโหลดข้อมูล...';
                    } else if (!hasMonthlyTransactions) {
                      monthlyNetBg = AppTheme.slate900.withOpacity(0.45);
                      monthlyNetBorder = AppTheme.slate800.withOpacity(0.4);
                      monthlyNetAccent = AppTheme.slate400;
                      monthlyNetIcon = Icons.remove_circle_outline_rounded;
                      monthlyNetStatusText = 'ยังไม่มีรายการ กรุณาเพิ่มรายรับ/รายจ่าย';
                    } else if (monthlyNet >= 0) {
                      monthlyNetBg = AppTheme.emerald950;
                      monthlyNetBorder = AppTheme.emeraldBorder.withOpacity(0.4);
                      monthlyNetAccent = AppTheme.emerald400;
                      monthlyNetIcon = Icons.trending_up_rounded;
                      monthlyNetStatusText = 'รายรับรวมมากกว่ารายจ่าย';
                    } else {
                      monthlyNetBg = AppTheme.rose950;
                      monthlyNetBorder = AppTheme.roseBorder.withOpacity(0.4);
                      monthlyNetAccent = AppTheme.rose400;
                      monthlyNetIcon = Icons.trending_down_rounded;
                      monthlyNetStatusText = 'รายจ่ายรวมมากกว่ารายรับ';
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: monthlyNetBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: monthlyNetBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: monthlyNetAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              monthlyNetIcon,
                              color: monthlyNetAccent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ยอดสุทธิรายเดือน',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.slate100,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  monthlyNetStatusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: monthlyNetAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormat.format(monthlyNet),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: monthlyNetAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 4. Daily Comparison Chart Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'กราฟเปรียบเทียบรายรับ-รายจ่ายรายวัน',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (financeState.isMonthlyLoading)
                          const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (financeState.monthlyTransactions.isEmpty)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.slate950.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.slate800),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bar_chart_rounded, color: AppTheme.slate700, size: 48),
                                  SizedBox(height: 8),
                                  Text(
                                    'ไม่มีข้อมูลการเงินในเดือนนี้',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Builder(
                            builder: (context) {
                              final parsedMonth = DateFormat('yyyy-MM').parse(financeState.selectedYearMonth);
                              final lastDay = DateTime(parsedMonth.year, parsedMonth.month + 1, 0).day;
                              
                              final Map<int, double> dailyIncomeMap = {};
                              final Map<int, double> dailyExpenseMap = {};
                              
                              for (int i = 1; i <= lastDay; i++) {
                                dailyIncomeMap[i] = 0.0;
                                dailyExpenseMap[i] = 0.0;
                              }
                              
                              for (final tx in financeState.monthlyTransactions) {
                                try {
                                  final txDate = DateFormat('yyyy-MM-dd').parse(tx.date);
                                  if (txDate.year == parsedMonth.year && txDate.month == parsedMonth.month) {
                                    final day = txDate.day;
                                    if (tx.type == 'income') {
                                      dailyIncomeMap[day] = (dailyIncomeMap[day] ?? 0.0) + tx.amount;
                                    } else {
                                      dailyExpenseMap[day] = (dailyExpenseMap[day] ?? 0.0) + tx.amount;
                                    }
                                  }
                                } catch (_) {}
                              }

                              final maxVal = _calculateMaxY(dailyIncomeMap, dailyExpenseMap);
                              final List<BarChartGroupData> barGroups = [];
                              
                              for (int day = 1; day <= lastDay; day++) {
                                final inc = dailyIncomeMap[day] ?? 0.0;
                                final exp = dailyExpenseMap[day] ?? 0.0;
                                
                                barGroups.add(
                                  BarChartGroupData(
                                    x: day,
                                    barRods: [
                                      BarChartRodData(
                                        toY: inc,
                                        color: AppTheme.emerald400,
                                        width: 6,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                      BarChartRodData(
                                        toY: exp,
                                        color: AppTheme.rose400,
                                        width: 6,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: lastDay * 36.0 + 40.0,
                                  height: 200,
                                  child: BarChart(
                                    BarChartData(
                                      maxY: maxVal,
                                      barGroups: barGroups,
                                      gridData: const FlGridData(show: false),
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (double value, TitleMeta meta) {
                                              final dayNum = value.toInt();
                                              if (dayNum >= 1 && dayNum <= lastDay) {
                                                final hasData = (dailyIncomeMap[dayNum] ?? 0) > 0 || (dailyExpenseMap[dayNum] ?? 0) > 0;
                                                if (dayNum == 1 || dayNum == lastDay || dayNum % 5 == 0 || hasData) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 6.0),
                                                    child: Text(
                                                      '$dayNum',
                                                      style: const TextStyle(
                                                        color: AppTheme.slate400,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 9,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                              return const SizedBox.shrink();
                                            },
                                            reservedSize: 22,
                                          ),
                                        ),
                                      ),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor: (group) => AppTheme.slate900,
                                          tooltipBorder: const BorderSide(color: AppTheme.slate800),
                                          tooltipBorderRadius: BorderRadius.circular(8),
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            final isIncome = rodIndex == 0;
                                            final typeStr = isIncome ? 'รายรับ' : 'รายจ่าย';
                                            final color = isIncome ? AppTheme.emerald400 : AppTheme.rose400;
                                            return BarTooltipItem(
                                              'วันที่ ${group.x}\n$typeStr: ${currencyFormat.format(rod.toY)}',
                                              TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Monthly Transactions Table
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'รายการบันทึกประจำเดือน',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.slate950.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.slate800),
                              ),
                              child: Text(
                                'ทั้งหมด ${financeState.monthlyTransactions.length} รายการ',
                                style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (financeState.isMonthlyLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (financeState.monthlyTransactions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36.0),
                              child: Column(
                                children: [
                                  Icon(Icons.history_toggle_off, color: AppTheme.slate700, size: 40),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'ยังไม่มีประวัติการบันทึกสำหรับเดือนนี้',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate400),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'สลับไปแท็บบันทึกรายวันเพื่อเพิ่มรายการใหม่',
                                    style: TextStyle(fontSize: 10, color: AppTheme.slate700),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: financeState.monthlyTransactions.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final tx = financeState.monthlyTransactions[index];
                              final isIncome = tx.type == 'income';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Short Date Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      width: 72,
                                      decoration: BoxDecoration(
                                        color: AppTheme.slate950.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.slate800),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _formatThaiShortDate(tx.date),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.slate300,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Item Desc
                                    Expanded(
                                      child: Text(
                                        tx.description ?? (isIncome ? 'รายรับ' : 'รายจ่าย'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.slate100,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Type Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isIncome ? AppTheme.emerald950 : AppTheme.rose950,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isIncome
                                              ? AppTheme.emeraldBorder.withOpacity(0.3)
                                              : AppTheme.roseBorder.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        isIncome ? 'รายรับ' : 'รายจ่าย',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isIncome ? AppTheme.emerald400 : AppTheme.rose400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Amount
                                    Text(
                                      '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isIncome ? AppTheme.emerald400 : AppTheme.rose400,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Delete Button
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('ลบรายการนี้?'),
                                            content: const Text('คุณแน่ใจว่าต้องการลบรายการนี้ใช่หรือไม่?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('ยกเลิก', style: TextStyle(color: AppTheme.slate400)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  ref.read(financeProvider.notifier).deleteTransaction(tx.id!);
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('ลบรายการเรียบร้อยแล้ว'),
                                                      backgroundColor: AppTheme.rose400,
                                                    ),
                                                  );
                                                },
                                                child: const Text('ยืนยันลบ', style: TextStyle(color: AppTheme.rose400)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.rose400, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
