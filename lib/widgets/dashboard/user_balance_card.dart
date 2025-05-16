import 'package:flutter/material.dart';
// Make sure these imports point to the correct location in your project
import '../../models/models.dart';
import '../../utils/formatters.dart'; // Contains currencyFormatter

class UserBalanceCard extends StatelessWidget {
  final User user;

  const UserBalanceCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // This card simply displays the user's info and their total paid amount for the group.
    // The percentage visualization is now handled by the central PieChart.
    return Card(
      elevation: 1, // Subtle elevation
      // Using the CardTheme shape provided in main.dart, or override here:
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0), // Vertical spacing between cards
      child: ListTile(
         // Consistent padding within the ListTile
         contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        // Leading avatar showing user initials and color
        leading: CircleAvatar(
            backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer, // Auto text color based on background
            child: Text(
              user.name.substring(0,1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14) // Consistent font size for initials
            ),
        ),
        // User's name
        title: Text(
            user.name,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500) // Use theme for consistency
        ),
        // Trailing text showing the total amount paid by this user
        trailing: Text(
            currencyFormatter.format(user.totalPaid),
            style: theme.textTheme.titleMedium?.copyWith( // Use theme text style
              color: theme.colorScheme.primary, // Highlight amount with primary color
              fontWeight: FontWeight.bold,
              // fontSize: 15 // Font size from theme is usually better
            )
        ),
      ),
    );
  }
}