// lib/widgets/dashboard/spinning_wheel_dialog.dart
import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'spinning_wheel.dart'; // Import the enhanced wheel

class SpinningWheelDialog extends StatelessWidget {
  final List<User> users;
  final double totalGroupExpenses;
  final SpinCompletionCallback onSpinComplete; // Callback to parent

  const SpinningWheelDialog({
    super.key,
    required this.users,
    required this.totalGroupExpenses,
    required this.onSpinComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Remove default padding around the content
      contentPadding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 10.0),
      // Optional: Customize shape and background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: Colors.grey[100], // Slightly off-white background
      content: Column(
        mainAxisSize: MainAxisSize.min, // Prevent dialog from taking full height
        children: [
          Text(
            "Spinning to see who pays...",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SpinningWheel(
            users: users,
            totalGroupExpenses: totalGroupExpenses,
            size: 280, // Slightly larger size for dialog
            autoSpin: true, // Start spinning immediately
            duration: const Duration(seconds: 5), // Slightly longer spin
            onSpinComplete: (selectedUser) {
              // Close the dialog *before* calling the parent's callback
              Navigator.of(context).pop();
              // Then call the original callback passed from DashboardScreen
              onSpinComplete(selectedUser);
            },
          ),
          const SizedBox(height: 10),
           // Optional: Add a cancel button to the dialog itself
           // TextButton(
           //   child: const Text("Cancel Spin"),
           //   onPressed: () => Navigator.of(context).pop(), // Just close dialog
           // )
        ],
      ),
    );
  }
}