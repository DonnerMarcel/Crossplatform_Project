import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/history/expense_card.dart';

class HistoryScreen extends StatelessWidget {
  final PaymentGroup group;

  const HistoryScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final List<Expense> expenses = group.expenses;

    return expenses.isEmpty
        ? const Center(
            child: Text(
              'No expenses recorded yet for this group.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            )
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final payerUser = group.members.firstWhere(
                    (user) => user.id == expense.payerId,
                orElse: () => User(
                  id: 'unknown',
                  name: 'Unknown',
                  profileColor: Colors.grey,
                ),
              );

              return ExpenseCard(expense: expense, payer: payerUser);
            },
          );
  }
}