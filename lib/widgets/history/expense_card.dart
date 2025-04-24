// lib/widgets/shared/expense_card.dart
import 'package:flutter/material.dart';
import '../../models/models.dart';       // Import Expense and User models
import '../../utils/formatters.dart';  // Import formatters (to be created)

class ExpenseCard extends StatelessWidget {
  final Expense expense; // The expense data to display
  final User? payer;     // The User object who paid (nullable in case not found)

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.payer // Payer is required, but can be null if ID didn't match
  });

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context); // Get theme data

     return Card(
       elevation: 1, // Subtle elevation
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent rounding
       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0), // Consistent margin
       child: ListTile(
          // Leading icon representing an expense/receipt
          leading: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.secondary), // Use theme color
          // Display expense description
          title: Text(
              expense.description,
              style: const TextStyle(fontWeight: FontWeight.w500), // Medium weight title
              maxLines: 1, // Prevent long descriptions from wrapping excessively
              overflow: TextOverflow.ellipsis, // Use ellipsis if too long
          ),
          // Display who paid and when
          subtitle: Text(
              // Safely display payer name or 'Unknown' if null
              'Paid by ${payer?.name ?? "Unknown"} on ${formatDate(expense.date)}',
              // Requires formatDate function from utils/formatters.dart
              style: theme.textTheme.bodySmall // Use smaller text style for subtitle
          ),
          // Display the expense amount, formatted as currency
          trailing: Text(
             // Requires currencyFormatter from utils/formatters.dart
             currencyFormatter.format(expense.amount),
             style: TextStyle(
                 fontWeight: FontWeight.bold,
                 fontSize: 15,
                 color: theme.colorScheme.onSurface // Standard text color for amount
             )
          ),
          // Optional: Add density for a more compact list item
          // visualDensity: VisualDensity.compact,
          // contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
       ),
     );
  }
}