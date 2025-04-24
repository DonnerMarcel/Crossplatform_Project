// lib/widgets/group_list/group_list_item.dart
import 'package:flutter/material.dart';
import '../../models/models.dart'; // Import models (adjust path if needed)

class GroupListItem extends StatelessWidget {
  final PaymentGroup group;
  final User currentUser; // Needs the current user to check 'isUserBehind'
  final VoidCallback onTap; // Callback function when the item is tapped

  const GroupListItem({
    super.key,
    required this.group,
    required this.currentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the current user is behind in this specific group
    final bool userIsBehind = group.isUserBehind(currentUser.id);

    return Card(
      // Highlight card background if user is behind
      color: userIsBehind ? Colors.red[50] : null, // Use theme's card color if not behind
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent corner rounding
      elevation: 1, // Standard elevation
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0), // Standard margin from theme
      // Use InkWell for tap effect and to trigger the onTap callback
      child: InkWell(
          onTap: onTap, // Execute the callback passed from the parent screen
          borderRadius: BorderRadius.circular(12), // Match card shape for ripple effect
          child: ListTile(
              // Display initials of first member or group letter
              leading: CircleAvatar(
                 backgroundColor: userIsBehind
                     ? Colors.red[100] // Distinct background for avatar if behind
                     : Theme.of(context).colorScheme.secondaryContainer, // Use theme color otherwise
                 child: Text(
                      // Get initials from the first member, or first letter of group name, or '?'
                      group.members.isNotEmpty
                          ? group.members.first.initials
                          : group.name.isNotEmpty ? group.name.substring(0,1).toUpperCase() : '?',
                      style: TextStyle(
                          color: userIsBehind
                              ? Colors.red[800] // Darker text color on the highlighted avatar
                              : Theme.of(context).colorScheme.onSecondaryContainer, // Theme color otherwise
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                  ),
              ),
              // Display group name
              title: Text(
                  group.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              // Display member count
              subtitle: Text(
                  '${group.members.length} Member${group.members.length == 1 ? "" : "s"}' // Handle pluralization
              ),
              // Display appropriate trailing icon
              trailing: userIsBehind
                  ? const Icon(Icons.warning_amber_rounded, color: Colors.red) // Warning icon if behind
                  : const Icon(Icons.chevron_right, color: Colors.grey), // Standard navigation icon
              // Optional: Adjust content padding if needed
              // contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
      ),
    );
  }
}