// lib/widgets/dashboard/user_balance_card.dart
import 'package:flutter/material.dart';
import '../../models/models.dart';       // Import User model
import '../../utils/formatters.dart';  // Import formatters (to be created)

class UserBalanceCard extends StatelessWidget {
  final User user; // Receives the User object with updated totalPaid for the group context

  const UserBalanceCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data for consistent styling

    return Card(
      elevation: 1, // Subtle elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent rounding
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0), // Reduced vertical margin for list appearance
      child: ListTile(
        // Leading avatar showing user initials and color
        leading: CircleAvatar(
           backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer, // Use profile color or theme default
           foregroundColor: theme.colorScheme.onPrimaryContainer, // Text color on the avatar
           child: Text(
             user.initials, // Use initials getter from User model
             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
           ),
        ),
        // Display user name
        title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.w500) // Slightly less bold than title
        ),
        // Display total amount paid by the user, formatted as currency
        trailing: Text(
           // Use the currency formatter (requires utils/formatters.dart)
           currencyFormatter.format(user.totalPaid),
           style: TextStyle(
               color: theme.colorScheme.primary, // Highlight amount with primary color
               fontWeight: FontWeight.bold,
               fontSize: 15
           )
        ),
        // Optional: Add density for a more compact list item
        // visualDensity: VisualDensity.compact,
        // contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      ),
    );
  }
}