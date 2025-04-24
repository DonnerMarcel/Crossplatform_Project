// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../models/models.dart';             // Import data models
import '../widgets/history/expense_card.dart';      // Import the widget to display each expense (to be created)

class HistoryScreen extends StatelessWidget {
  final PaymentGroup group; // Receives the entire group object

  const HistoryScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    // Get the expenses directly from the group object
    // The list is already sorted by date (newest first) in MainScreen after adding
    final List<Expense> expenses = group.expenses;

    // No Scaffold/AppBar here, as it's provided by MainScreen

    // Check if there are any expenses to display
    return expenses.isEmpty
        ? const Center( // Show a message if the list is empty
            child: Text(
              'No expenses recorded yet for this group.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            )
          )
        : ListView.builder( // Display expenses in a scrollable list
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0), // Add some padding
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              // Find the User object corresponding to the payerId for this expense
              final payerUser = group.getUserById(expense.payerId);

              // Use the ExpenseCard widget to display the expense details
              // (ExpenseCard needs to be created in lib/widgets/expense_card.dart)
              return ExpenseCard(expense: expense, payer: payerUser);
            },
          );
  }
}