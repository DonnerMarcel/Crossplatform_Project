// lib/data/dummy_data.dart
import 'package:flutter/material.dart';
import '../models/models.dart'; // Import the models

// --- Define Current User (Example) ---
// In a real app, this would come from login/auth state
final User currentUser = User(id: '1', name: 'Me', profileColor: Colors.deepPurple);

// --- Dummy Data for Groups ---
// Create some distinct users first
final userMe = currentUser;
final userMax = User(id: '2', name: 'Max', profileColor: Colors.amber);
final userKlaus = User(id: '3', name: 'Klaus Huber', profileColor: Colors.blue);
final userJohn = User(id: '4', name: 'John', profileColor: Colors.redAccent);
final userAnna = User(id: '5', name: 'Anna', profileColor: Colors.green);

// Create dummy groups with members and expenses
List<PaymentGroup> dummyGroups = [
  // Group 1: "WG Sonnenallee" - Me is potentially behind
  PaymentGroup(
    id: 'g1',
    name: 'WG Sonnenallee', // Flat Share Sonnenallee
    members: [userMe, userMax, userAnna],
    expenses: [
      Expense(id: 'e101', amount: 50.0, date: DateTime(2025, 4, 1), description: 'Rent Contribution', payerId: userMax.id),
      Expense(id: 'e102', amount: 30.0, date: DateTime(2025, 4, 3), description: 'Groceries', payerId: userAnna.id),
      Expense(id: 'e103', amount: 15.0, date: DateTime(2025, 4, 5), description: 'Internet', payerId: userMe.id), // Me paid little
      Expense(id: 'e104', amount: 50.0, date: DateTime(2025, 4, 6), description: 'Rent Contribution', payerId: userMax.id),
    ],
  ),
  // Group 2: "Lunch Buddies" - Me seems okay/ahead
  PaymentGroup(
    id: 'g2',
    name: 'Lunch Buddies',
    members: [userMe, userJohn, userKlaus],
    expenses: [
      Expense(id: 'e201', amount: 62.55, date: DateTime(2025, 1, 23), description: 'Asian Restaurant', payerId: userMe.id), // Me paid
      Expense(id: 'e202', amount: 45.00, date: DateTime(2025, 1, 20), description: 'Pizza', payerId: userJohn.id),
      Expense(id: 'e203', amount: 88.45, date: DateTime(2025, 1, 15), description: 'Burger Joint', payerId: userMe.id), // Me paid again
    ],
  ),
   // Group 3: "Holiday Trip" - Empty expenses
  PaymentGroup(
    id: 'g3',
    name: 'Holiday Trip',
    members: [userMe, userMax, userJohn, userAnna],
    expenses: [], // No expenses yet
  ),
   // Group 4: "Holiday Trip" - Empty expenses
  PaymentGroup(
    id: 'g4',
    name: 'Foodie Group',
    members: [userMe, userMax, userAnna],
    expenses: [], // No expenses yet
  ),
];

