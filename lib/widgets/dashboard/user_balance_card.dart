import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/formatters.dart';

class UserBalanceCard extends StatelessWidget {
  final User user;

  const UserBalanceCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        // Leading avatar showing user initials and color
        leading: CircleAvatar(
           backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer,
           foregroundColor: theme.colorScheme.onPrimaryContainer,
           child: Text(
             user.initials,
             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
           ),
        ),
        title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.w500)
        ),
        trailing: Text(
           currencyFormatter.format(user.totalPaid),
           style: TextStyle(
               color: theme.colorScheme.primary,
               fontWeight: FontWeight.bold,
               fontSize: 15
           )
        ),
      ),
    );
  }
}