import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/formatters.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final User? payer;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.payer
  });

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);

     return Card(
       margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
       child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.6),
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: const Icon(Icons.receipt_long_outlined, size: 20),
          ),
          title: Text(
              expense.description,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
              'Paid by ${payer?.name ?? "Unknown"} on ${formatDate(expense.date)}',
              style: theme.textTheme.bodySmall
          ),
          trailing: Text(
             currencyFormatter.format(expense.amount),
             style: theme.textTheme.bodyMedium?.copyWith(
                 fontWeight: FontWeight.bold,
                 color: theme.colorScheme.primary
             )
          ),
          dense: true,
       ),
     );
  }
}