// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For .sorted() and firstWhereOrNull
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers.dart';
import '../utils/formatters.dart';
import '../widgets/dashboard/user_balance_card.dart';
// --- FIX: Correct the import path ---
import '../widgets/history/expense_card.dart'; // Changed from 'shared' to 'history'
import '../widgets/dashboard/spinning_wheel.dart';

// Define the typedef here
typedef AddExpenseCallback = void Function({String? preselectedPayerId});

// Change to ConsumerStatefulWidget
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

// Change to ConsumerState
class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  // Method to handle completion of the spin
  void _handleSpinComplete(User selectedUser) {
     showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spin Result'),
        content: Row(
          children: [
            CircleAvatar(
               backgroundColor: selectedUser.profileColor ?? Colors.grey[300],
               child: Text(selectedUser.initials, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  // Getter for total group expenses
  double get _totalGroupExpenses => widget.group.totalGroupExpenses;

  @override
  Widget build(BuildContext context) {
    // Ensure user totals are calculated
    widget.group.userTotals;

    final currentExpenses = widget.group.expenses;

    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Total Overview Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Group Expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(_totalGroupExpenses),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
           const SizedBox(height: 20),

          // User Balances Section
           Text(
               'User Balances (Total Paid in Group)',
               style: Theme.of(context).textTheme.titleLarge
           ),
           const SizedBox(height: 8),
           if (widget.group.members.isNotEmpty)
                ...widget.group.members.map((user) => UserBalanceCard(
                      user: user
                    )).toList()
           else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No members in this group."),
                ),

            const SizedBox(height: 24),

            // Spinning Wheel
            Center(
              child: SpinningWheel(
                users: widget.group.members,
                totalGroupExpenses: _totalGroupExpenses,
                onSpinComplete: _handleSpinComplete,
              ),
            ),

           const SizedBox(height: 24),

          // Last Expense Section
           Text(
               'Last Expense',
               style: Theme.of(context).textTheme.titleLarge
           ),
           const SizedBox(height: 8),
            if (currentExpenses.isNotEmpty)
               ExpenseCard( // This should now be recognized
                   // Use firstWhereOrNull for safety if list could become empty
                   expense: currentExpenses.sorted((a, b) => b.date.compareTo(a.date)).first,
                   payer: widget.group.getUserById(currentExpenses.sorted((a, b) => b.date.compareTo(a.date)).first.payerId),
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