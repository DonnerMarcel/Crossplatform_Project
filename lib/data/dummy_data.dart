// lib/data/dummy_data.dart
import 'package:flutter/material.dart';
import '../models/models.dart';

final User currentUser = User(
  id: 'user-001',
  name: 'Me',
  profileColor: Colors.deepPurple[300],
);


final User userMe = currentUser;

final User userMax = User(
  id: 'user-002',
  name: 'Max Power',
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

final User userSara = User(
  id: 'user-006',
  name: 'Sara Connor',
  profileColor: Colors.teal[400],
);



List<PaymentGroup> dummyGroups = [


  PaymentGroup(
    id: 'group-flat-share',
    name: 'WG Sonnenallee',
    members: [userMe, userMax, userAnna],
    expenses: [
      Expense(id: 'exp-g1-01', amount: 50.0, date: DateTime.now().subtract(const Duration(days: 25)), description: 'Rent Contribution April', payerId: userMax.id),
      Expense(id: 'exp-g1-02', amount: 30.0, date: DateTime.now().subtract(const Duration(days: 23)), description: 'Groceries Week 1', payerId: userAnna.id),
      Expense(id: 'exp-g1-03', amount: 15.0, date: DateTime.now().subtract(const Duration(days: 20)), description: 'Internet Bill', payerId: userMe.id),
      Expense(id: 'exp-g1-04', amount: 50.0, date: DateTime.now().subtract(const Duration(days: 19)), description: 'Rent Contribution May', payerId: userMax.id),
      Expense(id: 'exp-g1-05', amount: 42.50, date: DateTime.now().subtract(const Duration(days: 5)), description: 'Groceries Week 2', payerId: userAnna.id),
    ],
  ),

  PaymentGroup(
    id: 'group-lunch',
    name: 'Lunch Buddies',
    members: [userMe, userJohn, userKlaus],
    expenses: [
      Expense(id: 'exp-g2-01', amount: 62.55, date: DateTime.now().subtract(const Duration(days: 90)), description: 'Asian Restaurant', payerId: userMe.id),
      Expense(id: 'exp-g2-02', amount: 45.00, date: DateTime.now().subtract(const Duration(days: 85)), description: 'Pizza Place', payerId: userJohn.id),
      Expense(id: 'exp-g2-03', amount: 88.45, date: DateTime.now().subtract(const Duration(days: 80)), description: 'Burger Joint Visit', payerId: userMe.id),
      Expense(id: 'exp-g2-04', amount: 55.00, date: DateTime.now().subtract(const Duration(days: 10)), description: 'Team Lunch Mexican', payerId: userKlaus.id),
    ],
  ),

  PaymentGroup(
    id: 'group-holiday',
    name: 'Holiday Trip Italy',
    members: [userMe, userMax, userJohn, userAnna],
    expenses: [
        Expense(id: 'exp-g3-01', amount: 120.00, date: DateTime.now().subtract(const Duration(days: 15)), description: 'Booking Deposit - Hotel', payerId: userMax.id),
        Expense(id: 'exp-g3-02', amount: 75.50, date: DateTime.now().subtract(const Duration(days: 12)), description: 'Guide Books & Maps', payerId: userMe.id),
        Expense(id: 'exp-g3-03', amount: 30.00, date: DateTime.now().subtract(const Duration(days: 2)), description: 'Snacks for the road', payerId: userAnna.id),
    ],
  ),

  PaymentGroup(
    id: 'group-foodie',
    name: 'Foodie Group',
    members: [userMe, userKlaus, userSara],
    expenses: [
      Expense(id: 'exp-g4-01', amount: 95.80, date: DateTime.now().subtract(const Duration(days: 7)), description: 'Wine Tasting Event', payerId: userKlaus.id),
      Expense(id: 'exp-g4-02', amount: 60.00, date: DateTime.now().subtract(const Duration(days: 3)), description: 'Cheese Platter Ingredients', payerId: userSara.id),
    ],
  ),


  PaymentGroup(
    id: 'group-project-alpha',
    name: 'Project Alpha Team',
    members: [userMe, userSara],
    expenses: [
       Expense(id: 'exp-g5-01', amount: 25.00, date: DateTime.now().subtract(const Duration(days: 14)), description: 'Coffee & Donuts', payerId: userMe.id),
       Expense(id: 'exp-g5-02', amount: 30.00, date: DateTime.now().subtract(const Duration(days: 6)), description: 'Project Supplies', payerId: userSara.id),
    ],
  ),
];
