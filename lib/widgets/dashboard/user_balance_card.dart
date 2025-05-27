import 'package:flutter/material.dart';
// Make sure these imports point to the correct location in your project
import '../../models/models.dart';
import '../../utils/formatters.dart'; // Contains currencyFormatter

class UserBalanceCard extends StatelessWidget {
  final User user;
  final String? userImageUrl; // New: cached user image URL, nullable

  const UserBalanceCard({
    super.key,
    required this.user,
    this.userImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar;

    if (userImageUrl != null && userImageUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        backgroundImage: NetworkImage(userImageUrl!),
        backgroundColor: Colors.transparent,
      );
    } else {
      avatar = CircleAvatar(
        backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Text(
          user.name.substring(0, 1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: avatar,
        title: Text(
          user.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          currencyFormatter.format(user.totalPaid),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
