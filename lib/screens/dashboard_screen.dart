import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed pie_chart import as it's no longer used here
// import 'package:pie_chart/pie_chart.dart';

import '../models/models.dart';
import '../providers.dart';
import '../utils/formatters.dart';
// Ensure UserBalanceCard is imported correctly (simplified version)
import '../widgets/dashboard/user_balance_card.dart';
import '../widgets/history/expense_card.dart';
import '../widgets/dashboard/spinning_wheel_dialog.dart';

// Define the typedef if not already defined globally or in main_screen.dart
typedef AddExpenseCallback = void Function({String? preselectedPayerId});

class DashboardScreen extends ConsumerStatefulWidget {
  final PaymentGroup group;
  final AddExpenseCallback onAddExpenseRequested;

  const DashboardScreen({
    super.key,
    required this.group,
    required this.onAddExpenseRequested,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // --- Spin Result Dialog Logic (Unchanged) ---
  void _showResultDialog(User selectedUser) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spin Result'),
        content: Row(
          children: [
            CircleAvatar(
              backgroundColor: selectedUser.profileColor ?? Colors.grey[300],
              foregroundColor:
                  ThemeData.estimateBrightnessForColor(selectedUser.profileColor ?? Colors.grey[300]!) == Brightness.dark
                      ? Colors.white
                      : Colors.black,
              child: Text(selectedUser.initials,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 15),
            Expanded(
                child: Text('${selectedUser.name} has been selected to pay!')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('OK & Enter Details'),
          ),
        ],
      ),
    ).then((shouldNavigate) {
      if (shouldNavigate == true && mounted) {
        widget.onAddExpenseRequested(preselectedPayerId: selectedUser.id);
      }
    });
  }

  // --- Open Spinning Wheel Dialog Logic (Unchanged) ---
  void _openSpinningWheelDialog() {
    widget.group.userTotals;
    if (widget.group.members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No members in group to spin.')));
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpinningWheelDialog(
        users: widget.group.members,
        totalGroupExpenses: widget.group.totalGroupExpenses,
        onSpinComplete: _showResultDialog,
      ),
    );
  }

  // --- Getter for total group expenses (Unchanged) ---
  double get _totalGroupExpenses => widget.group.totalGroupExpenses;

  // --- REMOVED Pie Chart Helper Methods ---
  // Map<String, double> _createPieDataMap() { ... } // REMOVED
  // List<Color> _createPieColorList(ThemeData theme) { ... } // REMOVED


  @override
  Widget build(BuildContext context) {
    // Ensure latest totals are calculated
    widget.group.userTotals;

    final currentExpenses = List<Expense>.from(widget.group.expenses);
    final sortedExpenses = currentExpenses.sorted((a, b) => b.date.compareTo(a.date));
    final Expense? latestExpense = sortedExpenses.firstOrNull;
    final theme = Theme.of(context);

    // --- REMOVED Pie Chart Variable Declarations ---
    // final Map<String, double> pieDataMap = _createPieDataMap();
    // final List<Color> pieColorList = _createPieColorList(theme);
    // final bool showChart = pieDataMap.isNotEmpty && _totalGroupExpenses > 0;

    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Total Overview Card (Unchanged) ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Group Expenses', style: theme.textTheme.titleMedium?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(currencyFormatter.format(_totalGroupExpenses), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- REMOVED Payment Distribution Pie Chart Section ---
          // Text('Payment Distribution', style: theme.textTheme.titleLarge), // REMOVED
          // const SizedBox(height: 12), // REMOVED
          // Card( ... PieChart ... ), // REMOVED
          // const SizedBox(height: 20), // REMOVED


          // --- User Balances Section (Uses simplified Card) ---
          Text('User Balances (Total Paid)', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (widget.group.members.isNotEmpty)
             // Cards no longer need totalGroupExpenses passed
             ...widget.group.members.map((user) => UserBalanceCard(user: user)).toList()
          else
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 8.0),
               child: Text("No members in this group."),
             ),

          const SizedBox(height: 28),

          // --- Action Buttons Row (Unchanged from your last version) ---
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: [
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.casino_outlined),
                    label: const Text('Spin Wheel!'),
                    onPressed: _openSpinningWheelDialog,
                    style: ElevatedButton.styleFrom( /* ... style ... */
                         foregroundColor: theme.colorScheme.onPrimary,
                         backgroundColor: theme.colorScheme.primary,
                         padding: const EdgeInsets.symmetric(vertical: 12),
                         textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                     ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                   flex: 4,
                   child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Manual'),
                    onPressed: () => widget.onAddExpenseRequested(),
                    style: OutlinedButton.styleFrom( /* ... style ... */
                         foregroundColor: theme.colorScheme.primary,
                         side: BorderSide(color: theme.colorScheme.primary),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                     ),
                   ),
                 ),
             ],
          ),

          const SizedBox(height: 28),

          // --- Last Expense Section (Unchanged) ---
          Text('Last Expense', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (latestExpense != null)
             ExpenseCard(
                 expense: latestExpense,
                 payer: widget.group.getUserById(latestExpense.payerId),
             )
          else
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 8.0),
               child: Text('No expenses recorded yet for this group.'),
             ),
          const SizedBox(height: 16),
        ],
      );
  }
}