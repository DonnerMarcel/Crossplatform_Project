// lib/data/dummy_data.dart
import 'package:flutter/material.dart';
import '../models/models.dart'; // Import the data models

// --- ---------------- --- //
// ---      USERS        --- //
// --- ---------------- --- //

// Define Current User (Simulates logged-in user)
// In a real app, this would come from an authentication service.
final User currentUser = User(
  id: 'user-001', // Use a more structured ID format
  name: 'Me',
  profileColor: Colors.deepPurple[300], // Use lighter shade maybe
);

// Define other distinct users for groups
// Giving them clearer, unique IDs
final User userMe = currentUser; // Alias for clarity

final User userMax = User(
  id: 'user-002',
  name: 'Max Power', // Slightly more distinct name
  profileColor: Colors.amber[600],
);

final User userKlaus = User(
  id: 'user-003',
  name: 'Klaus Huber',
  profileColor: Colors.blue[600],
);

final User userJohn = User(
  id: 'user-004',
  name: 'John Doe',
  profileColor: Colors.redAccent[400],
);

final User userAnna = User(
  id: 'user-005',
  name: 'Anna Schmidt',
  profileColor: Colors.green[600],
);

// Add one more user for variety
final User userSara = User(
  id: 'user-006',
  name: 'Sara Connor',
  profileColor: Colors.teal[400],
);


// --- ---------------- --- //
// ---      GROUPS       --- //
// --- ---------------- --- //

// List of dummy payment groups with members and expenses
// This list serves as the initial data source for GroupDataService.
List<PaymentGroup> dummyGroups = [

  // --- Group 1: Flat Share ---
  // Scenario: 'Me' has paid less than the average share.
  PaymentGroup(
    id: 'group-flat-share', // More descriptive ID
    name: 'WG Sonnenallee',
    members: [userMe, userMax, userAnna],
    expenses: [
      Expense(id: 'exp-g1-01', amount: 50.0, date: DateTime.now().subtract(const Duration(days: 25)), description: 'Rent Contribution April', payerId: userMax.id),
      Expense(id: 'exp-g1-02', amount: 30.0, date: DateTime.now().subtract(const Duration(days: 23)), description: 'Groceries Week 1', payerId: userAnna.id),
      Expense(id: 'exp-g1-03', amount: 15.0, date: DateTime.now().subtract(const Duration(days: 20)), description: 'Internet Bill', payerId: userMe.id), // Me paid little
      Expense(id: 'exp-g1-04', amount: 50.0, date: DateTime.now().subtract(const Duration(days: 19)), description: 'Rent Contribution May', payerId: userMax.id),
      Expense(id: 'exp-g1-05', amount: 42.50, date: DateTime.now().subtract(const Duration(days: 5)), description: 'Groceries Week 2', payerId: userAnna.id),
    ],
  ),

  // --- Group 2: Lunch ---
  // Scenario: 'Me' has paid more than the average share.
  PaymentGroup(
    id: 'group-lunch',
    name: 'Lunch Buddies',
    members: [userMe, userJohn, userKlaus],
    expenses: [
      Expense(id: 'exp-g2-01', amount: 62.55, date: DateTime.now().subtract(const Duration(days: 90)), description: 'Asian Restaurant', payerId: userMe.id), // Me paid
      Expense(id: 'exp-g2-02', amount: 45.00, date: DateTime.now().subtract(const Duration(days: 85)), description: 'Pizza Place', payerId: userJohn.id),
      Expense(id: 'exp-g2-03', amount: 88.45, date: DateTime.now().subtract(const Duration(days: 80)), description: 'Burger Joint Visit', payerId: userMe.id), // Me paid again
      Expense(id: 'exp-g2-04', amount: 55.00, date: DateTime.now().subtract(const Duration(days: 10)), description: 'Team Lunch Mexican', payerId: userKlaus.id), // Klaus paid
    ],
  ),

   // --- Group 3: Holiday Trip ---
   // Scenario: Some initial expenses added.
  PaymentGroup(
    id: 'group-holiday',
    name: 'Holiday Trip Italy', // More specific name
    members: [userMe, userMax, userJohn, userAnna], // 4 members
    expenses: [
        Expense(id: 'exp-g3-01', amount: 120.00, date: DateTime.now().subtract(const Duration(days: 15)), description: 'Booking Deposit - Hotel', payerId: userMax.id),
        Expense(id: 'exp-g3-02', amount: 75.50, date: DateTime.now().subtract(const Duration(days: 12)), description: 'Guide Books & Maps', payerId: userMe.id),
        Expense(id: 'exp-g3-03', amount: 30.00, date: DateTime.now().subtract(const Duration(days: 2)), description: 'Snacks for the road', payerId: userAnna.id),
    ],
  ),

   // --- Group 4: Foodies ---
   // Scenario: Different set of members, some expenses.
  PaymentGroup(
    id: 'group-foodie', // Was g4 before
    name: 'Foodie Group',
    members: [userMe, userKlaus, userSara], // Different members
    expenses: [
      Expense(id: 'exp-g4-01', amount: 95.80, date: DateTime.now().subtract(const Duration(days: 7)), description: 'Wine Tasting Event', payerId: userKlaus.id),
      Expense(id: 'exp-g4-02', amount: 60.00, date: DateTime.now().subtract(const Duration(days: 3)), description: 'Cheese Platter Ingredients', payerId: userSara.id),
    ],
  ),

  // --- Group 5: Project Team ---
  // Scenario: Small group, balanced payments.
  PaymentGroup(
    id: 'group-project-alpha',
    name: 'Project Alpha Team',
    members: [userMe, userSara], // Only 2 members
    expenses: [
       Expense(id: 'exp-g5-01', amount: 25.00, date: DateTime.now().subtract(const Duration(days: 14)), description: 'Coffee & Donuts', payerId: userMe.id),
       Expense(id: 'exp-g5-02', amount: 30.00, date: DateTime.now().subtract(const Duration(days: 6)), description: 'Project Supplies', payerId: userSara.id),
    ],
  ),
];

// --- End Dummy Data ---