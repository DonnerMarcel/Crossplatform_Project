import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'spinning_wheel.dart';

class SpinningWheelDialog extends StatelessWidget {
  final List<User> users;
  final double totalGroupExpenses;
  final SpinCompletionCallback onSpinComplete;

  const SpinningWheelDialog({
    super.key,
    required this.users,
    required this.totalGroupExpenses,
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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SpinningWheel(
            users: users,
            totalGroupExpenses: totalGroupExpenses,
            size: 280,
            autoSpin: true,
            duration: const Duration(seconds: 5),
            onSpinComplete: (selectedUser) {
              Navigator.of(context).pop();
              onSpinComplete(selectedUser);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}