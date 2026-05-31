import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final financeNotifier = ref.read(financeProvider.notifier);

    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = financeState.selectedDate == todayStr;

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
            ],
          ),
        ),
      ),
    );
  }
}
