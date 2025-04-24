// lib/models/models.dart
import 'package:flutter/material.dart';
// The 'collection' package is used for '.average' but was actually not used
// in the isUserBehind calculation as shown. If you plan to use average or
// other collection methods later, keep this import and add the dependency:
// import 'package:collection/collection.dart'; // Run: flutter pub add collection

// --- User Class ---
class User {
  final String id;
  String name;
  Color? profileColor; // Placeholder for profile picture or colored avatar
  double totalPaid; // Total paid WITHIN A SPECIFIC GROUP context

  User({
    required this.id,
    required this.name,
    this.profileColor,
    this.totalPaid = 0.0, // Initial value when calculating for a group
  });

  // Generates initials from the name (e.g., "John Doe" -> "JD")
  String get initials {
    if (name.isEmpty) return '?';
    List<String> parts = name.trim().split(' ');
    parts.removeWhere((part) => part.isEmpty); // Remove empty parts resulting from multiple spaces

    if (parts.length > 1 && parts.last.isNotEmpty) {
      // Use first letter of the first and last part
      return parts.first.substring(0, 1).toUpperCase() +
             parts.last.substring(0, 1).toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      // Use the first letter of the only part
      return parts.first.substring(0, 1).toUpperCase();
    } else {
      return '?'; // Fallback if name is weirdly formatted
    }
  }

  // Override equality operator and hashCode to allow finding Users in lists by ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// --- Expense Class ---
class Expense {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String payerId; // Store only the User ID of the payer

  Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.payerId,
  });
}

// --- PaymentGroup Class ---
class PaymentGroup {
  final String id;
  String name;
  List<User> members; // List of Users belonging to this group
  List<Expense> expenses; // List of Expenses recorded for this group

  PaymentGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.expenses,
  });

  // Calculate the total amount paid by each user within this group.
  // Returns a Map where keys are user IDs and values are total amounts paid.
  // This method also updates the 'totalPaid' property of each User object
  // in the members list for convenience.
  Map<String, double> get userTotals {
    // Initialize totals map with 0.0 for each member
    Map<String, double> totals = { for (var user in members) user.id : 0.0 };

    // Sum expenses for each payer
    for (var expense in expenses) {
      if (totals.containsKey(expense.payerId)) {
        totals[expense.payerId] = totals[expense.payerId]! + expense.amount;
      }
      // Optional: Handle case where payerId might not be in members list?
      // else { print("Warning: Payer ID ${expense.payerId} not found in group ${this.name}"); }
    }

    // Update the totalPaid field on the User objects within this group instance
    for(var user in members) {
        user.totalPaid = totals[user.id] ?? 0.0;
    }
    return totals;
  }

  // Calculate the sum of all expenses in this group.
  double get totalGroupExpenses {
      // Use fold to sum the amounts of all expenses
      return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Simple logic to check if a specific user paid less than the average
  // share of total expenses within this group.
  // Returns true if the user paid less than their fair share.
  bool isUserBehind(String userId) {
    if (members.isEmpty) return false; // Cannot determine if there are no members

    final totalsMap = userTotals; // Calculate totals (updates user.totalPaid too)
    final userPayment = totalsMap[userId] ?? 0.0;
    final totalPaidInGroup = totalGroupExpenses; // Use the getter for total

    if (totalPaidInGroup <= 0) return false; // No expenses, no one is behind

    // Calculate the average ("fair share") per member
    final averagePayment = totalPaidInGroup / members.length;

    // Consider user behind if they paid less than the average
    // Added a small tolerance (e.g., 0.01) to handle potential floating point inaccuracies
    return userPayment < (averagePayment - 0.01);
  }

   // Helper method to find a specific User object within the group's members list by their ID.
   // Returns the User object or null if not found.
   User? getUserById(String id) {
       try {
           // Find the first member whose ID matches
           return members.firstWhere((user) => user.id == id);
       } catch (e) {
           // firstWhere throws an error if no element is found
           return null; // Return null if the user is not in the members list
       }
   }
}

// --- Helper Functions (Removed formatDate, will be in utils) ---
// The formatDate function was here previously.