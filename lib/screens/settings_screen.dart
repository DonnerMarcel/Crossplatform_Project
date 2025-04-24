// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../models/models.dart';          // Import models for PaymentGroup
import '../utils/constants.dart';      // Import constants (to be created)
import '../utils/formatters.dart';     // Import formatters (to be created)

class SettingsScreen extends StatelessWidget {
  final PaymentGroup group; // Receives the group object

  const SettingsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    // No Scaffold/AppBar here, it's provided by MainScreen

    return ListView( // Use ListView for potentially scrollable settings
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Group Name Setting (Placeholder) ---
        ListTile(
          leading: const Icon(Icons.edit_note),
          title: const Text('Group Name'),
          subtitle: Text(group.name), // Display current group name
          onTap: () { // Placeholder action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Placeholder: Edit group name action'))
            );
          },
        ),
        const Divider(), // Visual separator

        // --- Portion Cost Setting (Placeholder - Using global constant) ---
        ListTile(
          leading: const Icon(Icons.attach_money),
          title: const Text('Cost per Portion/Meal (Global)'),
          // Display the global constant formatted as currency
          // Requires 'currencyFormatter' from utils/formatters.dart and 'portionCostPerUser' from utils/constants.dart
          subtitle: Text(currencyFormatter.format(portionCostPerUser)),
          onTap: () { // Placeholder action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Placeholder: Change global portion cost action'))
            );
          },
        ),
        const Divider(),

        // --- Manage Members Setting (Placeholder) ---
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: Text('Manage Members (${group.members.length})'), // Show current member count
          subtitle: const Text('Add/remove members for this group'), // Description
          onTap: () { // Placeholder action
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Placeholder: Manage members for ${group.name}'))
            );
          },
        ),
        const Divider(),

        // --- Delete Group Setting (Placeholder) ---
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red), // Red icon
          title: const Text('Delete Group'),
          textColor: Colors.red, // Red text color
          onTap: () { // Placeholder action
            // TODO: Implement confirmation dialog before actual deletion
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Placeholder: Delete group ${group.name} action'))
            );
          },
        ),
        const Divider(),

        // Add more group-specific or general app settings here later...
        // Example:
        // ListTile(
        //   leading: const Icon(Icons.color_lens_outlined),
        //   title: const Text('Group Theme/Color'),
        //   onTap: () {},
        // ),
        // const Divider(),
      ],
    );
  }
}