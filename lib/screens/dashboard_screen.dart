import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_chart/pie_chart.dart';

import '../models/models.dart';
import '../providers.dart';
import '../utils/formatters.dart';
import '../widgets/dashboard/user_balance_card.dart';
import '../widgets/history/expense_card.dart';
import '../widgets/dashboard/spinning_wheel_dialog.dart';

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
              child: Text(selectedUser.name.substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text('${selectedUser.name} has been selected to pay!')),
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

  void _openSpinningWheelDialog() {
    if (widget.group.members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members in group to spin.')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpinningWheelDialog(
        users: widget.group.members,
        totalGroupExpenses: widget.group.totalPaid,
        onSpinComplete: _showResultDialog,
      ),
    );
  }

  double get _totalGroupExpenses => widget.group.totalPaid;

  Map<String, double> _createPieDataMap() {
    final double total = widget.group.totalPaid;
    Map<String, double> dataMap = {};
    if (total <= 0) {
      for (var user in widget.group.members) {
        dataMap[user.name] = 0.01;
      }
      return dataMap;
    }
    for (var user in widget.group.members) {
      final paid = user.totalPaid ?? 0;
      if (paid > 0) {
        dataMap[user.name] = paid;
      }
    }
    if (dataMap.isEmpty && widget.group.members.isNotEmpty) {
      for (var user in widget.group.members) {
        dataMap[user.name] = 0.01;
      }
    }
    return dataMap;
  }

  List<Color> _createPieColorList(ThemeData theme) {
    List<Color> colorList = [];
    int colorIndex = 0;
    final fallbackColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.orangeAccent,
      Colors.lightGreen,
      Colors.blueAccent,
      Colors.purple,
    ];
    for (var user in widget.group.members) {
      colorList.add(user.profileColor ?? fallbackColors[colorIndex % fallbackColors.length]);
      colorIndex++;
    }
    return colorList;
  }

  @override
  Widget build(BuildContext context) {
    final currentExpenses = List<Expense>.from(widget.group.expenses);
    final sortedExpenses = currentExpenses.sorted((a, b) => b.date.compareTo(a.date));
    final Expense? latestExpense = sortedExpenses.firstOrNull;
    final theme = Theme.of(context);

    final pieDataMap = _createPieDataMap();
    final pieColorList = _createPieColorList(theme);
    final bool showChart = pieDataMap.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Group total
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Group Expenses', style: theme.textTheme.titleMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(currencyFormatter.format(_totalGroupExpenses),
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // User totals
        Text('User Balances (Total Paid)', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        if (widget.group.members.isNotEmpty)
          ...widget.group.members.map((user) => UserBalanceCard(user: user)).toList()
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("No members in this group."),
          ),

        const SizedBox(height: 28),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Spin Wheel!'),
                onPressed: _openSpinningWheelDialog,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Last Expense
        Text('Last Expense', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        if (latestExpense != null)
          ExpenseCard(
            expense: latestExpense,
            payer: widget.group.members.firstWhere(
                  (user) => user.id == latestExpense.payerId,
              orElse: () => User(
                id: 'unknown',
                name: 'Unknown',
                profileColor: Colors.grey,
              ),
            ),
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
