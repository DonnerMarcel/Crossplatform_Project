import 'package:flutter/material.dart';

// --- User Class ---
class User {
  final String id;
  String name;
  Color? profileColor;
  double totalPaid;

  User({
    required this.id,
    required this.name,
    this.profileColor,
    this.totalPaid = 0.0,
  });

  String get initials {
    if (name.isEmpty) return '?';
    List<String> parts = name.trim().split(' ');
    parts.removeWhere((part) => part.isEmpty);

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
  final String payerId;

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
  List<User> members;
  List<Expense> expenses;

  PaymentGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.expenses,
  });

  Map<String, double> get userTotals {
    Map<String, double> totals = { for (var user in members) user.id : 0.0 };

    // Sum expenses for each payer
    for (var expense in expenses) {
      if (totals.containsKey(expense.payerId)) {
        totals[expense.payerId] = totals[expense.payerId]! + expense.amount;
      }
    }

    // Update the totalPaid field on the User objects within this group instance
    for(var user in members) {
        user.totalPaid = totals[user.id] ?? 0.0;
    }
    return totals;
  }

  // Calculate the sum of all expenses in this group.
  double get totalGroupExpenses {
      return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  bool isUserBehind(String userId) {
    if (members.isEmpty) return false;

    final totalsMap = userTotals;
    final userPayment = totalsMap[userId] ?? 0.0;
    final totalPaidInGroup = totalGroupExpenses;

    if (totalPaidInGroup <= 0) return false;

    final averagePayment = totalPaidInGroup / members.length;

    return userPayment < (averagePayment - 0.01);
  }

   User? getUserById(String id) {
       try {
           return members.firstWhere((user) => user.id == id);
       } catch (e) {
           return null; // Return null if the user is not in the members list
       }
   }
}
