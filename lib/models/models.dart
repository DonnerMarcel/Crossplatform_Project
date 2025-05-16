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

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'] ?? '',
      profileColor: map['profileColor'] != null
          ? Color(int.parse(map['profileColor']))
          : null,
      totalPaid: (map['totalPaid'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileColor': profileColor?.value.toString(),
      'totalPaid': totalPaid,
    };
  }
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

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      description: map['description'] ?? '',
      payerId: map['payerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'payerId': payerId,
    };
  }
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

  double get totalPaid => members.fold(0.0, (sum, user) => sum + (user.totalPaid ?? 0.0));

  factory PaymentGroup.fromMap(Map<String, dynamic> map) {
    return PaymentGroup(
      id: map['id'],
      name: map['name'] ?? '',
      members: (map['members'] as List<dynamic>)
          .map((member) => User.fromMap(member))
          .toList(),
      expenses: (map['expenses'] as List<dynamic>)
          .map((expense) => Expense.fromMap(expense))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members.map((u) => u.toMap()).toList(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
    };
  }
}
