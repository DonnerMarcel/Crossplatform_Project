import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/formatters.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final User? payer;
  final String? payerImageUrl; // New parameter for cached image URL

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.payer,
    this.payerImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: payerImageUrl == null
              ? (payer?.profileColor ?? theme.colorScheme.primaryContainer)
              : null,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          backgroundImage: payerImageUrl != null ? NetworkImage(payerImageUrl!) : null,
          child: payerImageUrl == null
              ? Text(
            payer?.name.isNotEmpty == true
                ? payer!.name[0].toUpperCase()
                : '?',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          )
              : null,
        ),
        title: Text(
          expense.description,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Paid by ${payer?.name ?? "Unknown"} on ${formatDate(expense.date)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          currencyFormatter.format(expense.amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        dense: true,
      ),
    );
  }
}
