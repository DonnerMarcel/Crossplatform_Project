// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For .sorted() and firstWhereOrNull
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers.dart';
import '../utils/formatters.dart';
import '../widgets/dashboard/user_balance_card.dart';
import '../widgets/history/expense_card.dart'; // Correct import path
import '../widgets/dashboard/spinning_wheel_dialog.dart';
import 'add_expense_screen.dart';

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

  // Method to show the result dialog after the spin
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
               child: Text(selectedUser.initials, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text('${selectedUser.name} has been selected to pay!')),
          ],
        ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(dialogContext, false),
             child: const Text('Abbruch', style: TextStyle(color: Colors.grey)),
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

  // Method to open the spinning wheel dialog
  void _openSpinningWheelDialog() {
     widget.group.userTotals; // Ensure totals are calculated

     if (widget.group.members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No members in group to spin.'))
        );
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

  void _navigateToAddExpense({String? preselectedPayerId}) async {
    // Use ref.read to safely get the current state within this async method
    // --- FIX: Use firstWhereOrNull for safer nullable lookup ---
    final PaymentGroup? group = ref.read(groupServiceProvider.select(
      // Use firstWhereOrNull from package:collection
            (groups) => groups.firstWhereOrNull((g) => g.id == widget.group.id)
    ));

    // Check if group data is available
    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Group data not available.'))
      );
      return;
    }
    // Check if there are members to pay
    if (group.members.isEmpty && preselectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot add expense: No members in the group.'))
      );
      return;
    }

    // Navigate to AddExpenseScreen
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupMembers: group.members, // Use members from fetched group
          preselectedPayerId: preselectedPayerId,
          currencySymbol: currencyFormatter.currencySymbol,
        ),
      ),
    );

    // If an expense was successfully created and returned
    if (result != null && mounted) {
      // Call the provider's method to add the expense to the central state
      ref.read(groupServiceProvider.notifier).addExpenseToGroup(widget.group.id, result);

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense "${result.description}" saved.'),
            duration: const Duration(seconds: 2),
          )
      );
    }
  }

  // Getter for total group expenses
  double get _totalGroupExpenses => widget.group.totalGroupExpenses;

  @override
  Widget build(BuildContext context) {
    // Ensure user totals are calculated before building UI elements that depend on them
    widget.group.userTotals;

    // Get the current expenses list safely
    final currentExpenses = List<Expense>.from(widget.group.expenses);
    // Sort expenses to find the latest one
    final sortedExpenses = currentExpenses.sorted((a, b) => b.date.compareTo(a.date));
    // Get the latest expense only if the list is not empty
    final Expense? latestExpense = sortedExpenses.firstOrNull;

    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Total Overview Card ---
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

          // --- User Balances Section ---
           Text(
               'User Balances (Total Paid in Group)',
               style: Theme.of(context).textTheme.titleLarge
           ),
           const SizedBox(height: 8),
           if (widget.group.members.isNotEmpty)
                ...widget.group.members.map((user) => UserBalanceCard(
                      user: user // Pass user object with updated totalPaid
                    )).toList()
           else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No members in this group."),
                ),

            const SizedBox(height: 24),

            // --- Button to open the Spin Dialog ---
            Center(
              child:
                Row(
                  children: [
                    Expanded(
                        child:
                        ElevatedButton.icon(
                          label: const Text('Spin Wheel!'),
                          onPressed: _openSpinningWheelDialog,
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                    ),

                    SizedBox(width: 8),

                    Expanded(
                      child:
                      ElevatedButton.icon(
                          label: const Text('Add Expense'),
                          // Call _navigateToAddExpense without preselected payer for FAB
                          onPressed: _navigateToAddExpense,
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          )
                      )
                    ),
                  ]
                )
            ),

           const SizedBox(height: 24),

          // --- Last Expense Section ---
           Text(
               'Last Expense',
               style: Theme.of(context).textTheme.titleLarge
           ),
           const SizedBox(height: 8),
            // --- FIX: Provide arguments to ExpenseCard ---
            if (latestExpense != null) // Check if latestExpense exists
               ExpenseCard(
                   expense: latestExpense, // Pass the latest expense
                   // Find the payer User object using the helper method
                   payer: widget.group.getUserById(latestExpense.payerId),
               )
             else // Show message if no expenses are recorded yet
               const Padding(
                 padding: EdgeInsets.symmetric(vertical: 8.0),
                 child: Text('No expenses recorded yet for this group.'),
               ),
           const SizedBox(height: 16),
        ],
      );
  }
}
