// lib/widgets/history/expense_card.dart
import 'package:flutter/material.dart';
import '../../models/models.dart';       // Import Expense and User models
import '../../utils/formatters.dart';  // Import formatters

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

     // Use a standard Card for consistent styling with other elements if needed,
     // or a Container if more custom styling is desired. Card is simpler here.
     return Card(
       // Use elevation from the global CardTheme defined in main.dart
       // elevation: 1,
       // Use shape from the global CardTheme
       // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       // Margin can be controlled by the ListView padding or kept standard
       margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
       child: ListTile(
          // Leading icon representing an expense/receipt
          leading: CircleAvatar( // Use CircleAvatar for better alignment and visual appeal
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.6),
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: const Icon(Icons.receipt_long_outlined, size: 20),
          ),
          // Display expense description
          title: Text(
              expense.description,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), // Adjusted style
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
             style: theme.textTheme.bodyMedium?.copyWith( // Adjusted style
                 fontWeight: FontWeight.bold,
                 color: theme.colorScheme.primary // Highlight amount
             )
          ),
          dense: true, // Make the ListTile more compact
          // Optional: Add onTap for viewing expense details later
          // onTap: () { /* Navigate to expense detail screen */ },
       ),
     );
  }
}