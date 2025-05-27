import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/profile_image_cache_provider.dart';
import '../widgets/history/expense_card.dart';

class HistoryScreen extends ConsumerWidget {
  final PaymentGroup group;

  const HistoryScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Expense> expenses = group.expenses;
    final imageCache = ref.watch(profileImageCacheProvider);

    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'No expenses recorded yet for this group.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
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

        final payerImageUrl = imageCache[payerUser.id];

        return ExpenseCard(
          expense: expense,
          payer: payerUser,
          payerImageUrl: payerImageUrl,
        );
      },
    );
  }
}
