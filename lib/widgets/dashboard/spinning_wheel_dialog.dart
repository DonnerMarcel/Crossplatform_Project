import 'package:flutter/material.dart';
import '../../models/models.dart'; // Assuming User model is here
import 'spinning_wheel.dart'; // Your updated SpinningWheel widget

class SpinningWheelDialog extends StatelessWidget {
  final List<User> users;
  // final double totalGroupExpenses; // REMOVED
  final double averageExpenseAmount; // NEW
  final SpinCompletionCallback onSpinComplete;

  const SpinningWheelDialog({
    super.key,
    required this.users,
    // required this.totalGroupExpenses, // REMOVED
    required this.averageExpenseAmount, // NEW
    required this.onSpinComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: Colors.grey[100],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Spinning to see who pays...",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SpinningWheel(
            users: users,
            // totalGroupExpenses: totalGroupExpenses, // REMOVED
            averageExpenseAmount: averageExpenseAmount, // NEW - pass the average expense amount
            size: 280, // Consider making this adaptive or a parameter
            autoSpin: true,
            duration: const Duration(seconds: 5), // You can adjust spin duration
            onSpinComplete: (selectedUser) {
              // It's generally better to pop the dialog *after* the callback,
              // or let the calling widget handle popping if more complex logic is needed.
              // For simplicity here, popping before calling back.
              if (Navigator.canPop(context)) {
                 Navigator.of(context).pop();
              }
              onSpinComplete(selectedUser);
            },
            onSpinStart: () {
              print("SpinningWheelDialog: Spin started!");
            },
          ),
          const SizedBox(height: 10),
          // Optionally, add a cancel button if the spin is not auto-started
          // or if users should be able to close it before completion.
          // TextButton(
          //   child: const Text("Cancel"),
          //   onPressed: () {
          //     if (Navigator.canPop(context)) {
          //       Navigator.of(context).pop();
          //     }
          //   },
          // )
        ],
      ),
    );
  }
}
