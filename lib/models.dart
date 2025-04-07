// models.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Import for average calculation (flutter pub add collection)

// --- User Class (Unchanged) ---
class User {
  final String id;
  String name;
  Color? profileColor; // Placeholder for profile picture
  double totalPaid; // Total paid WITHIN A SPECIFIC GROUP

  User({
    required this.id,
    required this.name,
    this.profileColor,
    this.totalPaid = 0.0, // Initial value for a group context
  });

  String get initials {
    if (name.isEmpty) return '?';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1 && parts.last.isNotEmpty) {
      return parts.first.substring(0, 1).toUpperCase() + parts.last.substring(0, 1).toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first.substring(0, 1).toUpperCase();
    } else {
      return '?';
    }
  }

  // Add equality check for finding users in lists
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// --- Expense Class (Small change: payer is just User ID) ---
class Expense {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String payerId; // Store User ID instead of the full User object

  Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.payerId,
  });
}

// --- NEW: PaymentGroup Class ---
class PaymentGroup {
  final String id;
  String name;
  List<User> members; // Users in this group
  List<Expense> expenses; // Expenses for this group

  PaymentGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.expenses,
  });

  // Calculate total paid per user within this group
  Map<String, double> get userTotals {
    Map<String, double> totals = { for (var user in members) user.id : 0.0 };
    for (var expense in expenses) {
      if (totals.containsKey(expense.payerId)) {
        totals[expense.payerId] = totals[expense.payerId]! + expense.amount;
      }
    }
    // Update user objects (optional, could be done elsewhere)
    for(var user in members) {
        user.totalPaid = totals[user.id] ?? 0.0;
    }
    return totals;
  }

  // Get total expenses for this group
  double get totalGroupExpenses {
      return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Simple logic to check if a specific user is "behind"
  // Returns true if the user paid less than the average per member
  bool isUserBehind(String userId) {
    if (members.isEmpty) return false;
    final totals = userTotals; // Calculate totals first
    final userPayment = totals[userId] ?? 0.0;
    final totalPaid = totals.values.fold(0.0, (sum, item) => sum + item);
    final averagePayment = members.isNotEmpty ? totalPaid / members.length : 0.0;

    // Consider user behind if they paid significantly less than average (e.g. < average and not 0 average)
    // You could refine this logic (e.g., using hysteresis)
    return averagePayment > 0 && userPayment < averagePayment;
  }

   // Helper to get a specific user from the members list by ID
   User? getUserById(String id) {
       try {
           return members.firstWhere((user) => user.id == id);
       } catch (e) {
           return null; // Not found
       }
   }
}


// --- Helper Functions (Unchanged) ---
String formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
}