import 'package:flutter/material.dart';
import '../../models/models.dart';

class GroupListItem extends StatelessWidget {
  final PaymentGroup group;
  final User currentUser;
  final VoidCallback onTap;

  const GroupListItem({
    super.key,
    required this.group,
    required this.currentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool userIsBehind = group.isUserBehind(currentUser.id);
    final theme = Theme.of(context);

    // Define gradients based on userIsBehind status
    final Gradient cardGradient = userIsBehind
        ? LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.5),
              theme.colorScheme.primary.withOpacity(0.3)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [theme.colorScheme.surface, theme.colorScheme.surfaceVariant.withOpacity(0.3)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

    final Color avatarBackgroundColor = userIsBehind
        ? theme.colorScheme.primary.withOpacity(0.8)
        : (group.members.isNotEmpty ? group.members.first.profileColor : null) ?? theme.colorScheme.secondaryContainer;

    final Color avatarForegroundColor = userIsBehind
         ? theme.colorScheme.onPrimary
         : theme.colorScheme.onSecondaryContainer;


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: cardGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: theme.colorScheme.primary.withOpacity(0.1),
            highlightColor: theme.colorScheme.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                     backgroundColor: avatarBackgroundColor,
                     foregroundColor: avatarForegroundColor,
                     radius: 22,
                     child: Text(
                          group.members.isNotEmpty
                              ? group.members.first.initials
                              : group.name.isNotEmpty ? group.name.substring(0,1).toUpperCase() : '?',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          group.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.members.length} Member${group.members.length == 1 ? "" : "s"}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: userIsBehind ? theme.colorScheme.primary : Colors.grey.shade500,
                    size: 24,
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}